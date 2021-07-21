#!/usr/bin/python3

import glob
import os
import random
import shutil
import sys

# Workaround to make this work in Netlify...
local_py_path = '/opt/buildhome/python3.7/lib/python3.7/site-packages/'
if local_py_path not in sys.path:
    sys.path.append(local_py_path)

import yaml

DEFAULT_LOGO = 'logos/logo-generic.png'
top_level_dir = os.path.realpath(
    os.path.join(os.path.dirname(__file__), '..'))
content_dir = os.path.join(top_level_dir, 'content/en')
adopters_dir = os.path.join(top_level_dir, 'adopters')

def write_page_header(f):
    f.write('''---
title: Flux Adopters
type: page
description: >
  The Flux community is immensely proud to have grown a lot over all the years. On this page you can see a selection of organisations who self-identified as using any of the Flux projects in production.

  Thanks a lot for your trust, support and being part of our community!
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

def fix_up_logo(logo_entry):
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

def write_adopter_logos_for_landing_page(data):
    html = ""
    random.shuffle(data)

    data = [entry for entry in data
            if not entry['logo'].endswith(DEFAULT_LOGO)]
    for entry in data:
        if entry['logo'] not in html:
            html += """
        <img src="{logo}" alt="{caption}">""".format(
            logo=entry['logo'],
            caption=entry['name'] if 'needs-name' in entry and \
                entry['needs-name'] else '')

    out_file = os.path.join(content_dir, 'adopters_bg_include.html')
    if os.path.exists(out_file):
        os.remove(out_file)
    f = open(out_file, 'w')
    f.write(html)
    f.close()

def read_endorsements():
    endorsements_fn = os.path.join(content_dir, 'endorsements.yaml')
    with open(endorsements_fn, 'r') as File:
        data = yaml.safe_load(File)
    return data

def write_endorsements(data):
    html = ""
    for entry in data['endorsements']:
        html += """
    <div class="carousel-item {active}">
          <div class="foreground-item">
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

    endorsements_html_fn = os.path.join(content_dir, 'adopters_carousel_include.html')
    if os.path.exists(endorsements_html_fn):
        os.remove(endorsements_html_fn)
    f = open(endorsements_html_fn, 'w')
    f.write(html)
    f.close()


def write_adopters_page():
    adopters_page_fn = os.path.join(content_dir, 'adopters.md')

    f = open(adopters_page_fn, 'w')
    write_page_header(f)

    adopters_files = sorted(glob.glob(adopters_dir+'/*.yaml'))
    all_companies = []
    for yaml_fn in adopters_files:
        with open(yaml_fn, 'r') as File:
            data = yaml.safe_load(File)
        write_section_header(yaml_fn, data, f)

        companies = data['adopters']['companies']
        companies = sorted(companies, key=lambda x: x['name'].lower())

        f.write('''<div class="adopters">
{{< cardpane >}}
''')
        for company in companies:
            if 'logo' not in company:
                company['logo'] = DEFAULT_LOGO
            company['logo'] = fix_up_logo(company['logo'])
            if company not in all_companies:
                all_companies += [company]
            write_card_text(f, company['name'], company['url'], company['logo'])

        f.write('''{{< /cardpane >}}
</div>
''')
    f.close()
    return all_companies

def main():
    if os.getcwd() != top_level_dir:
        print('Please run this script from top-level of the repository.')
        sys.exit(1)

    endorsements = read_endorsements()
    write_endorsements(endorsements)

    all_companies = write_adopters_page()

    new_logos_dir = os.path.join(top_level_dir, 'static/img/logos')
    if not os.path.exists(new_logos_dir):
        os.makedirs(new_logos_dir)

    for img in glob.glob(
            os.path.join(adopters_dir, 'logos')+'/*'):
        shutil.copyfile(
            img,
            os.path.join(new_logos_dir,
                         os.path.basename(img)))

    write_adopter_logos_for_landing_page(all_companies)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("Aborted.", sys.stderr)
        sys.exit(1)
