#!/usr/bin/python

import glob
import os
import sys

# I hate doing this... but we've got to make this work on Github Actions...

if os.path.exists('/opt/hostedtoolcache/Python'):
    version_info = sys.version_info
    location = '/opt/hostedtoolcache/Python/{}.{}.*/*/lib/python*/site-packages'.format(
        version_info.major, version_info.minor)
    local_py_paths = glob.glob(location)
    if local_py_paths and local_py_paths[0] not in sys.path:
        sys.path.append(local_py_paths[0])

from github import (Github, GithubException)

main_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

def github_login():
    token = os.getenv('GITHUB_TOKEN')
    if not token:
        token_file = os.path.join(main_path, '.gh-token')
        if not os.path.exists(token_file):
            print('''GITHUB_TOKEN not set, and {} not found.

You either need to
- set the GITHUB_TOKEN environment variable, or
- specify it in {}

Please see https://github.com/settings/tokens for how to obtain token.'''.format(
    token_file, token_file))
            sys.exit(1)
        token = open(token_file).read().strip()
    return Github(token)

def get_contributions_from_gh():
    repos = [
        '.github',
        'community',
        'flux2',
        'flux2-kustomize-helm-example',
        'flux2-multi-tenancy',
        'go-git-providers',
        'helm-controller',
        'image-automation-controller',
        'image-reflector-controller',
        'kustomize-controller',
        'notification-controller',
        'pkg',
        'source-controller',
        'source-watcher',
        'terraform-provider-flux',
        'website',
        'webui'
    ]
    bots = [
        'fluxcdbot',
        'dependabot[bot]'
    ]
    contributors = {}

    gh = github_login()
    flux = gh.get_user('fluxcd')
    for repo in repos:
        try:
            contribs = flux.get_repo(repo).get_contributors()
        except GithubException:
            print("Couldn't get contributors for {}.".format(repo))
            continue
        for contributor in contribs:
            name = contributor.login
            if name in bots:
                continue
            if name not in contributors:
                contributors[name] = {'contributions': 0}
            contributors[name]['contributions'] += contributor.contributions
            contributors[name]['avatar_url'] = contributor.avatar_url
    return contributors

def sort_contributions(contributors):
    contribs = []
    for c in contributors:
        contribs += [
            (c, contributors[c]['contributions'], contributors[c]['avatar_url'])
        ]
    return sorted(contribs, key=lambda a: a[1], reverse=True)

def write_html(contributors):
    html = ""
    for contrib in contributors:
        html += \
            """<a href="https://github.com/{}"><img src="{}" title="{}" width="80" height="80"></a>
""".format(contrib[0], contrib[2], contrib[0])

    out_file = os.path.join(main_path, 'content/en/contributors_include.html')
    if os.path.exists(out_file):
        os.remove(out_file)
    f = open(out_file, 'w')
    f.write(html)
    f.close()

def main():
    contributors = get_contributions_from_gh()
    write_html(sort_contributions(contributors))

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("Aborted.", sys.stderr)
        sys.exit(1)
