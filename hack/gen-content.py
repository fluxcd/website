#!/usr/bin/env python3

# This was inspired by
# http://sigs.k8s.io/contributor-site/hack/gen-content.sh

# Check out
# external-sources/README.md for some instructions on how
# the file format works.

import csv
import os
import re
import shutil
import sys
import subprocess
import tempfile

# Workaround to make this work in Netlify...
LOCAL_PY_PATH = '/opt/buildhome/python3.8/lib/python3.8/site-packages/'
if LOCAL_PY_PATH not in sys.path:
    sys.path.append(LOCAL_PY_PATH)

import pathlib

global link_mapping
link_mapping = []

'''
We are adding basic Front-Matter here.

`docs` files can't have front-matter and # (h1)
'''
def rewrite_header(out_file, title=None, docs=False, weight=None):
    lines = open(out_file, 'r').readlines()

    if not title or title == '-':
        title = os.path.basename(out_file).split('.md')[0].title()
    header_lines = [
        '---\n',
        'title: {}\n'.format(title),
        'importedDoc: true\n'
    ]
    if weight:
        header_lines += ['weight: {}\n'.format(weight)]
    header_lines += [
        '---\n',
        '\n'
    ]

    file_desc = open(out_file, 'w')
    file_desc.writelines(header_lines)

    for line in lines:
        if not docs or not line.startswith('# ') or lines.index(line) >= 4:
            if not line.startswith('<!-- '): #FML!
                file_desc.write(line)
    file_desc.close()

class Repo():
    def __init__(self, external_sources_dir, repo_fn):
        self.temp_dir = tempfile.mkdtemp()
        self.repo_id = repo_fn.split(external_sources_dir)[1][1:]
        self.gh_source = 'https://github.com/{}/'.format(self.repo_id).strip('/')
        self.repo_fn = repo_fn
        self.dest = os.path.join(self.temp_dir, self.repo_id)
        self.file_list = []

        global link_mapping
        with open(self.repo_fn, 'r') as file_desc:
            csv_reader = csv.reader(file_desc)
            for line in csv_reader:
                self.file_list += [[entry.strip('/') for entry in line]]
                link_mapping += [[self.gh_source]+[entry.strip('/') for entry in line]]

    def __del__(self):
        shutil.rmtree(self.temp_dir)

    def clone_repo(self):
        subprocess.call([
            'git', 'clone', '--depth=1', '-q',
            self.gh_source, self.dest])

    def rewrite_links(self, out_file):
        '''
        Types of links in Markdown

        1: <url>                # hard to find - we have markdown that's mixed with html
        2: [label](url)
        3: [url]
        4: [label]: url     together with   [label]
        '''
        with open(out_file, 'r') as file_desc:
            content = file_desc.read()

        # links_1 = re.findall(r'\<.+?\>', content, re.MULTILINE)
        links_2 = re.findall(r'\[.+?\]\((.+?)\)', content, re.MULTILINE)
        links_3 = re.findall(r'\[(.+?)]\s+', content, re.MULTILINE)
        links_4 = re.findall(r'\[(.+?)\]\:\s+.+?', content, re.MULTILINE)

        # set()                 because we only want to review every link just once
        # str.split('#')[0]     because we ignore anchors
        links = set([a.split('#')[0]
                     for a in links_2+links_3+links_4
                     if not a.startswith('#')])

        link_rewrites = {}
        for link in links:
            if not link:
                continue
            global link_mapping

            for entry in link_mapping:
                if link == entry[1]:
                    link_rewrites[link] = '/{}'.format(entry[2].lower().split('.md')[0])
                elif link.startswith(self.gh_source) and link.endswith(entry[1]) and \
                     self.gh_source == entry[0]:
                    link_rewrites[link] = '/{}'.format(entry[2].lower().split('.md')[0])
            if link not in link_rewrites and os.path.exists(os.path.join(self.dest, link)) and \
               not link.startswith('https://') and not link.startswith('http://'):
                link_rewrites[link] = os.path.join(self.gh_source, 'blob/main', link)

        for key in link_rewrites:
            content = content.replace(key, link_rewrites[key])

        with open(out_file, 'w') as file_desc:
            file_desc.write(content)

    def copy_files(self, content_dir):
        for entry in self.file_list:
            out_file = os.path.join(content_dir, entry[1])
            shutil.copyfile(
                os.path.join(self.dest, entry[0]),
                out_file)
            docs = entry[1].startswith('flux/') or \
                   entry[1].startswith('flagger/')
            title = None
            weight = None
            if len(entry) == 4:
                weight = entry[3]
            if len(entry) >= 3:
                title = entry[2]
            rewrite_header(out_file, title=title, docs=docs, weight=weight)
            self.rewrite_links(out_file)


def get_repo_list(external_sources_dir):
    repos = []
    file_refs = pathlib.Path(external_sources_dir).glob('*/*')
    for file in file_refs:
        repo_fn = str(file)
        if os.path.isfile(repo_fn):
            repos += [Repo(external_sources_dir, repo_fn)]
    return repos


def main():
    repo_root = os.path.realpath(
        os.path.join(os.path.dirname(__file__), '..'))

    if os.getcwd() != repo_root:
        print('Please run this script from top-level of the repository.')
        sys.exit(1)

    content_dir = os.path.join(repo_root, 'content/en')
    external_sources_dir = os.path.join(repo_root, 'external-sources')

    repos = get_repo_list(external_sources_dir)
    for repo in repos:
        repo.clone_repo()
    for repo in repos:
        repo.copy_files(content_dir)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("Aborted.", sys.stderr)
        sys.exit(1)
