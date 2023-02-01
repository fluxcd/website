#!/usr/bin/env python3
#
# Generate a blog post draft from template.
#

from datetime import date
import os
import shutil
import sys

TOP_LEVEL_DIR = os.path.realpath(
    os.path.join(os.path.dirname(__file__), '..'))
BLOG_DIR = os.path.join(TOP_LEVEL_DIR, 'content/en/blog')
TEMPLATE_FN = os.path.join(TOP_LEVEL_DIR, 'templates/monthly-update.md')

def generate_blog_post_draft():
    today = date.today()
    month_name = today.strftime('%B')
    year = today.year
    if today.month == 12:
        year += 1
        next_month = '01'
    else:
        next_month = date(year, today.month+1, 1).strftime('%m')
    directory = os.path.join(
        BLOG_DIR, '{}-{}-{}-{}-update'.format(
            year, next_month, '01', month_name.lower()))
    if not os.path.exists(directory):
        os.makedirs(directory)
    file_name = os.path.join(directory, 'index.md')
    shutil.copyfile(TEMPLATE_FN, file_name)
    print('Created a blog post draft for {} {} in {}.'.format(
        month_name, year, file_name
    ))
    return file_name

def main():
    if os.getcwd() != TOP_LEVEL_DIR:
        print('Please run this script from top-level of the repository.')
        sys.exit(1)

    generate_blog_post_draft()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("Aborted.", sys.stderr)
        sys.exit(1)
