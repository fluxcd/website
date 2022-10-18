#!/usr/bin/env python3
#
# Generate adopters content for landing page and /adopters
#

import os
import random
import sys

# Workaround to make this work in Netlify...
LOCAL_PY_PATH = '/opt/buildhome/python3.8/lib/python3.8/site-packages/'
if LOCAL_PY_PATH not in sys.path:
    sys.path.append(LOCAL_PY_PATH)

import yaml

TOP_LEVEL_DIR = os.path.realpath(
    os.path.join(os.path.dirname(__file__), '..'))
CONTENT_DIR = os.path.join(TOP_LEVEL_DIR, 'content/en')
RESOURCES_YAML_FN = os.path.join(CONTENT_DIR, 'resources.yaml')

def write_page_header(resource_page_fd):
    resource_page_fd.write('''---
title: Resources
type: page
---

# Resources

We are very happy that our community has actively put resources together which you can learn from. Enjoy and please give feedback!

These resources are sorted by date - new entries are added to the top.
''')

def write_year_header(year, resource_page_fd):
    resource_page_fd.write('''
## {}

{{{{% blocks/section color="white" %}}}}

'''.format(year))

def write_resource_text(resource_page_fd, resource):
# {{% blocks/resource
# youtube="PFLimPh5-wo"
# title="The FASTEST way to deploy apps to Kubernetes" %}}
# {{% /blocks/resource %}}
# [//]: # (Date of video: 13-May-2022)

    card_text = '''{{% blocks/resource'''
    if 'youtube' in resource:
        card_text += '''
youtube="{}"'''.format(resource['youtube'])
    elif 'url' in resource:
        card_text += '''
url="{}"'''.format(resource['url'])
        if 'thumbnail' in resource:
            card_text += '''
thumbnail="{}"'''.format(resource['thumbnail'])
    card_text += '''
title="{}" %}}}}'''.format(resource['title'])
    card_text += '''
{{{{% /blocks/resource %}}}}
[//]: # (Date of video: {})

'''.format(resource['date'].strftime('%Y-%m-%d'))
    resource_page_fd.write(card_text)

def write_resources_page():
    resources_page_fn = os.path.join(CONTENT_DIR, 'resources.md')
    resource_page_fd = open(resources_page_fn, 'w')
    write_page_header(resource_page_fd)

    all_entries = []
    with open(RESOURCES_YAML_FN, 'r') as resources_fd:
        data = yaml.safe_load(resources_fd)
    resources = sorted(data['resources'], key=lambda x: x['date'], reverse=True)
    for year in sorted(set([x['date'].year for x in resources]), reverse=True):
        write_year_header(year, resource_page_fd)
        for resource in [x for x in resources if x['date'].year == year]:
            write_resource_text(resource_page_fd, resource)
        resource_page_fd.write('''{{% /blocks/section %}}
''')
    resource_page_fd.close()

def main():
    if os.getcwd() != TOP_LEVEL_DIR:
        print('Please run this script from top-level of the repository.')
        sys.exit(1)

    write_resources_page()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("Aborted.", sys.stderr)
        sys.exit(1)
