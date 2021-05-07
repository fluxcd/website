#!/usr/bin/python3

import glob
import os
import shutil
import sys

# Workaround to make this work in Netlify...
local_py_path = '/opt/buildhome/python3.7/lib/python3.7/site-packages/'
if not local_py_path in sys.path:
    sys.path.append(local_py_path)

import yaml

top_level_dir = os.path.realpath(
    os.path.join(os.path.dirname(__file__), '..'))

if os.getcwd() != top_level_dir:
    print('Please run this script from top-level of the repository.')
    sys.exit(1)

adopters_dir = os.path.join(top_level_dir, 'adopters')
content_dir = os.path.join(top_level_dir, 'content/en')
adopters_page_fn = os.path.join(content_dir, 'adopters.md')

f = open(adopters_page_fn, 'w')
f.write('''
---
title: Flux Adopters
type: page
---

# Flux Adopters
Organisations below all are using the [Flux family of projects](https://fluxcd.io) in production.

We are happy and proud to have you all as part of our community! :sparkling_heart:

To join this list, please follow [these instructions](https://github.com/fluxcd/website/blob/main/adopters#readme).

''')

company_files = sorted(glob.glob(adopters_dir+'/*.yaml'))
for yaml_fn in company_files:
    section_id = os.path.basename(yaml_fn).split('.yaml')[0][2:]
    with open(yaml_fn, 'r') as File:
        data = yaml.safe_load(File)
    section_title = data['adopters']['project']
    page_description = data['adopters']['description']
    f.write('''
<h2 id="{}">{} Adopters</h2>

{}

'''.format(section_id, section_title, page_description))

    companies = data['adopters']['companies']
    how_many = len(companies)
    companies = sorted(companies, key=lambda x: x['name'].lower())

    i = 0
    for company in companies:
        if i % 5 == 0:
            f.write('''
{{< cardpane >}}
''')
        if 'logo' not in company:
            company['logo'] = 'logos/logo-generic.png'
        if not company['logo'].startswith('https:'):
            logo_fn = os.path.join(adopters_dir, company['logo'])
            if not os.path.exists(logo_fn):
                print('"{}" not found.'.format(logo_fn))
                sys.exit(1)
            company['logo'] = '/img/' + company['logo']
        card_text = '{{% card header="[' + \
            company['name'] + '](' + \
            company['url'] + ')" %}}\n'
        card_text += '![' + company['name'] + '](' + \
            company['logo'] + ')\n'
        card_text += '{{% /card %}}\n'
        f.write(card_text)

        if i % 5 == 4:
            f.write('''
{{< /cardpane >}}''')
        i += 1

    if i % 5 != 4:
        f.write('''
{{< /cardpane >}}''')

new_logos_dir = os.path.join(top_level_dir, 'static/img/logos')
if not os.path.exists(new_logos_dir):
    os.makedirs(new_logos_dir)

for img in glob.glob(
        os.path.join(adopters_dir, 'logos')+'/*'):
    shutil.copyfile(
        img,
        os.path.join(new_logos_dir,
                     os.path.basename(img)))
