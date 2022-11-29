#!/usr/bin/env python3

from datetime import (date, datetime, timedelta)
import glob
import os
import sys
import re

# Workaround to make this work in Netlify...
LOCAL_PY_PATH = '/opt/buildhome/python3.11/lib/python3.11/site-packages/'
if LOCAL_PY_PATH not in sys.path:
    sys.path.append(LOCAL_PY_PATH)

# I hate doing this... but we've got to make this work on Github Actions...
if os.path.exists('/opt/hostedtoolcache/Python'):
    VERSION_INFO = sys.version_info
    LOCATION = '/opt/hostedtoolcache/Python/{}.{}.*/*/lib/python*/site-packages'.format(
        VERSION_INFO.major, VERSION_INFO.minor)
    LOCAL_PY_PATHS = glob.glob(LOCATION)
    if LOCAL_PY_PATHS and LOCAL_PY_PATHS[0] not in sys.path:
        sys.path.append(LOCAL_PY_PATHS[0])


from icalendar import Calendar
import pytz
import recurring_ical_events
import urllib3

CAL_URL = 'https://lists.cncf.io/g/cncf-flux-dev/ics/4130481/1290943905/feed.ics'

TOP_LEVEL_DIR = os.path.realpath(
    os.path.join(os.path.dirname(__file__), '..'))
CONTENT_DIR = os.path.join(TOP_LEVEL_DIR, 'content/en')
CALENDAR_INCLUDE_HTML = os.path.join(CONTENT_DIR, 'calendar_include.html')
NEXT_EVENT_INCLUDE_HTML = os.path.join(CONTENT_DIR, 'next_event_include.html')

URL_RE = re.compile(r"((https?):((//)|(\\\\))+[\w\d:#@%/;$()~_?\+-=\\\.&]*)", re.MULTILINE|re.UNICODE)

# Ex: https://docs.google.com/document/d/1l_M0om0qUEN_NNiGgpqJ2tvsF2iioHkaARDeh6b70B0/edit# ( https://docs.google.com/document/d/1l_M0om0qUEN_NNiGgpqJ2tvsF2iioHkaARDeh6b70B0/edit )
DOUBLE_URL_RE = re.compile(r"((https?):((//)|(\\\\))+[\w\d:#@%/;$()~_?\+-=\\\.&]*)(\s\(\s((https?):((//)|(\\\\))+[\w\d:#@%/;$()~_?\+-=\\\.&]*)\s\))", re.MULTILINE|re.UNICODE)


def replace_url_to_link(value):
    return URL_RE.sub(r'<a href="\1" target="_blank">here</a><br/>', value)

def fix_double_url(text):
    # icalendar description inserts some noisy url data
    # like this:
    # Meeting agenda, minutes and videos: https://docs.google.com/document/d/1l_M0om0qUEN_NNiGgpqJ2tvsF2iioHkaARDeh6b70B0/edit# ( https://docs.google.com/document/d/1l_M0om0qUEN_NNiGgpqJ2tvsF2iioHkaARDeh6b70B0/edit )
    # or this:
    # Find your local number: https://zoom.us/u/adZJ8PKSIP ( https://www.google.com/url?q=https://zoom.us/u/adZJ8PKSIP&sa=D&source=calendar&ust=1604867561566000&usg=AOvVaw2W04x-xaitfml1SAw4m10z )

    # Until the source data is fixed, the this will find every "URL1 ( URL2 )" and replace it with "URL1"
    return DOUBLE_URL_RE.sub(r"\1", text)



def download_calendar():
    http = urllib3.PoolManager()
    r = http.request('GET', CAL_URL)
    if r.status != 200:
        print('Error retrieving calendar.', sys.stderr)
        return None
    return r.data


def read_organizer(event):
    organizer = event['organizer']
    email = organizer.title().split(':')[1].lower()
    name = email
    if 'cn' in organizer.params:
        name = organizer.params['cn']

    return {"name": name, "email": email}

def read_calendar(cal):
    events = []
    gcal = Calendar.from_ical(cal)
    today = date.today()
    next_month = today+timedelta(days=30)
    for event in recurring_ical_events.of(gcal).between(today, next_month):
        description = replace_url_to_link(fix_double_url(event['description']))
        if type(event['dtstart'].dt) == date:
            event_time = datetime.combine(
                event['dtstart'].dt, datetime.min.time()).astimezone(pytz.utc)
        else:
            event_time = event['dtstart'].dt.astimezone(pytz.utc)
        if 'location' not in event:
            event_location = ''
        else:
            event_location = event['location'].title().lower()
        events += [
            {
                "time": event_time,
                "title": event['summary'],
                "location": event_location,
                "organizer": read_organizer(event),
                "description": description
            }
        ]
    events.sort(key=lambda e: e['time'])
    return events

def format_location_html(event):
    lc = event['location'].lower()
    location = event['location']
    html = event['location']
    if lc.startswith("http://") or lc.startswith("https://"):
        html = f"""<a href="{lc}">{location}</a>"""
    elif lc.find("slack") or lc.find('#flux'):
        html = f"""<a href="https://cloud-native.slack.com/messages/flux">{location}</a>"""
    return html


def write_events_html(events):
    if os.path.exists(CALENDAR_INCLUDE_HTML):
        os.remove(CALENDAR_INCLUDE_HTML)

    if not events:
        return

    html = """
    <ul class="calendar-list">"""

    for event in events:
        html += f"""
        <li>
            <div class="calendar-row">
                <div class="date">{event['time'].strftime('%F')}</div>
                <div class="time">{event['time'].strftime('%H:%M')}</div>
                <div class="label">{event['title']}</div>
            </div>
            <div class="calendar-card">
                <ul class="details-list">
                    <li>
                        <dt>Where</dt>
                        <dd>{format_location_html(event)}</dd>
                    </li>
                    
                    <li>
                        <dt>Organizer</dt>
                        <dd><a href="mailto:{event['organizer']['email']}">{event['organizer']['name']}</a></dd>
                    </li>
                </ul>

                <span class="description">{event['description']}</span>
            </div>
        </li>

"""
    html += """
    </ul>"""

    f = open(CALENDAR_INCLUDE_HTML, 'w')
    f.write(html)
    f.close()

    with open(NEXT_EVENT_INCLUDE_HTML, 'w') as f:
        event = events[0]
        if not event['location'].startswith('http'):
            event['location'] = '/#calendar'
        f.write('📆 Next event: <a href="{where}">{date} {time} UTC: {title}</a>'.format(
            where=event['location'],
            date=event['time'].strftime('%F'),
            time=event['time'].strftime('%H:%M'),
            title=event['title']))
        f.close()

def main():
    cal = download_calendar()
    if not cal:
        sys.exit(1)
    events = read_calendar(cal)
    write_events_html(events)

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('Aborted.', sys.stderr)
        sys.exit(1)
