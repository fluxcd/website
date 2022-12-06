#!/usr/bin/env python3
#
# Generate adopters content for landing page and /adopters
#

import os
import sys

# Workaround to make this work in Netlify...
LOCAL_PY_PATH = '/opt/buildhome/python3.8/lib/python3.8/site-packages/'
if LOCAL_PY_PATH not in sys.path:
    sys.path.append(LOCAL_PY_PATH)

import yaml

TOP_LEVEL_DIR = os.path.realpath(
    os.path.join(os.path.dirname(__file__), '..'))
CONTENT_DIR = os.path.join(TOP_LEVEL_DIR, 'content/en')
def read_endorsements():
    endorsements_fn = os.path.join(CONTENT_DIR, 'endorsements.yaml')
    with open(endorsements_fn, 'r') as endorsements_fd:
        data = yaml.safe_load(endorsements_fd)
    return data

def write_endorsements(data):
    html = ""
    for entry in data['endorsements']:
        html += """
    <div class="carousel-item {active}">
          <div class="item">
            <div class="logo">
                <img src="{image}" alt="">
            </div>
            <div class="case-study">
                {text}
                <div class="description">
                    {subtitle}
                </div>
            </div>
        </div>
    </div>""".format(
        active='active' if data['endorsements'].index(entry) == 0 else '',
        image=entry['image'], text=entry['text'], subtitle=entry['subtitle']
    )

    endorsements_html_fn = os.path.join(CONTENT_DIR, 'endorsements_carousel_include.html')
    if os.path.exists(endorsements_html_fn):
        os.remove(endorsements_html_fn)
    file_descriptor = open(endorsements_html_fn, 'w')
    file_descriptor.write(html)
    file_descriptor.close()


def main():
    if os.getcwd() != TOP_LEVEL_DIR:
        print('Please run this script from top-level of the repository.')
        sys.exit(1)

    endorsements = read_endorsements()
    write_endorsements(endorsements)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("Aborted.", sys.stderr)
        sys.exit(1)
