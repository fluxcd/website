#!/usr/bin/python3

from datetime import (date, timedelta)
import glob
import os
import sys

# Workaround to make this work in Netlify...
LOCAL_PY_PATH = '/opt/buildhome/python3.8/lib/python3.8/site-packages/'
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

def download_calendar():
    http = urllib3.PoolManager()
    r = http.request('GET', CAL_URL)
    if r.status != 200:
        print('Error retrieving calendar.', sys.stderr)
        return None
    return r.data

def read_calendar(cal):
    events = []
    gcal = Calendar.from_ical(cal)
    today = date.today()
    next_month = today+timedelta(days=30)
    for event in recurring_ical_events.of(gcal).between(today, next_month):
        events += [
            (event['dtstart'].dt.astimezone(pytz.utc),
             event['summary'],
             event['description'])
        ]
    events.sort()
    return events

def write_events_html(events):
    if os.path.exists(CALENDAR_INCLUDE_HTML):
        os.remove(CALENDAR_INCLUDE_HTML)

    if not events:
        return

    html = """
    <table>"""

    for event in events:
        html += """
        <tr>
            <td class="date">{}</td>
            <td class="time">{}</td>
            <td class="label">{}</td>
        </tr>
""".format(
    event[0].strftime('%F'),
    event[0].strftime('%H:%M'),
    event[1])

    html += """
    </table>"""

    f = open(CALENDAR_INCLUDE_HTML, 'w')
    f.write(html)
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
