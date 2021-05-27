#!/usr/bin/python3

import glob
import os
import shutil
import sys

# Workaround to make this work in Netlify...
local_py_path = '/opt/buildhome/python3.7/lib/python3.7/site-packages/'
if local_py_path not in sys.path:
    sys.path.append(local_py_path)

import yaml

def write_page_header(f):
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

def write_section_header(yaml_fn, data, f):
    section_id = os.path.basename(yaml_fn).split('.yaml')[0][2:]
    section_title = data['adopters']['project']
    page_description = data['adopters']['description']
    f.write('''
<h2 id="{}">{} Adopters</h2>

{}

'''.format(section_id, section_title, page_description))

def fix_up_logo(adopters_dir, logo_entry):
    if not logo_entry.startswith('https:'):
        logo_fn = os.path.join(adopters_dir, logo_entry)
        if not os.path.exists(logo_fn):
            print('"{}" not found.'.format(logo_fn))
            sys.exit(1)
        logo_entry = '/img/' + logo_entry
    return logo_entry

def write_card_text(f, company_name, company_url, company_logo):
    card_text = '{{% card header="[' + \
        company_name + '](' + \
        company_url + ')" %}}\n'
    card_text += '![' + company_name + '](' + \
        company_logo + ')\n'
    card_text += '{{% /card %}}\n'
    f.write(card_text)


def main():
    top_level_dir = os.path.realpath(
        os.path.join(os.path.dirname(__file__), '..'))

    if os.getcwd() != top_level_dir:
        print('Please run this script from top-level of the repository.')
        sys.exit(1)

    adopters_dir = os.path.join(top_level_dir, 'adopters')
    content_dir = os.path.join(top_level_dir, 'content/en')
    adopters_page_fn = os.path.join(content_dir, 'adopters.md')

    f = open(adopters_page_fn, 'w')

    write_page_header(f)

    adopters_files = sorted(glob.glob(adopters_dir+'/*.yaml'))
    for yaml_fn in adopters_files:
        with open(yaml_fn, 'r') as File:
            data = yaml.safe_load(File)
        write_section_header(yaml_fn, data, f)

        companies = data['adopters']['companies']
        companies = sorted(companies, key=lambda x: x['name'].lower())

        f.write('''{{< cardpane >}}
''')
        for company in companies:
            i = companies.index(company)
            if 'logo' not in company:
                company['logo'] = 'logos/logo-generic.png'
            company['logo'] = fix_up_logo(adopters_dir, company['logo'])
            write_card_text(f, company['name'], company['url'], company['logo'])

        f.write('''{{< /cardpane >}}
''')

    new_logos_dir = os.path.join(top_level_dir, 'static/img/logos')
    if not os.path.exists(new_logos_dir):
        os.makedirs(new_logos_dir)

    for img in glob.glob(
            os.path.join(adopters_dir, 'logos')+'/*'):
        shutil.copyfile(
            img,
            os.path.join(new_logos_dir,
                         os.path.basename(img)))

    f.close()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("Aborted.", sys.stderr)
        sys.exit(1)
