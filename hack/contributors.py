#!/usr/bin/env python3

import glob
import os
import sys

# I hate doing this... but we've got to make this work on Github Actions...

if os.path.exists('/opt/hostedtoolcache/Python'):
    VERSION_INFO = sys.version_info
    LOCATION = '/opt/hostedtoolcache/Python/{}.{}.*/*/lib/python*/site-packages'.format(
        VERSION_INFO.major, VERSION_INFO.minor)
    LOCAL_PY_PATHS = glob.glob(LOCATION)
    if LOCAL_PY_PATHS and LOCAL_PY_PATHS[0] not in sys.path:
        sys.path.append(LOCAL_PY_PATHS[0])

from github import (Github, GithubException)

MAIN_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

def github_login():
    token = os.getenv('GITHUB_TOKEN')
    if not token:
        token_file = os.path.join(MAIN_PATH, '.gh-token')
        if not os.path.exists(token_file):
            print('''GITHUB_TOKEN not set, and {tf} not found.

You either need to
- set the GITHUB_TOKEN environment variable, or
- specify it in {tf}

Please see https://github.com/settings/tokens for how to obtain token.'''.format(
    tf=token_file))
            sys.exit(1)
        token = open(token_file).read().strip()
    return Github(token)

def get_contributions_from_gh():
    repos = [
        '.github',
        'community',
        'flagger',
        'flux2',
        'flux2-kustomize-helm-example',
        'flux2-multi-tenancy',
        'go-git-providers',
        'golang-with-libgit2',
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

    gh_obj = github_login()
    flux = gh_obj.get_user('fluxcd')
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
    for who in contributors:
        contribs += [
            (who,
             contributors[who]['contributions'],
             contributors[who]['avatar_url'])
        ]
    return sorted(contribs, key=lambda a: a[1], reverse=True)

def write_html(contributors):
    html = ""
    for contrib in contributors:
        html += \
            """<a href="https://github.com/{}"><img src="{}" title="{}" width="80" height="80"></a>
""".format(contrib[0], contrib[2], contrib[0])

    out_file = os.path.join(MAIN_PATH, 'content/en/contributors_include.html')
    if os.path.exists(out_file):
        os.remove(out_file)
    file_desc = open(out_file, 'w')
    file_desc.write(html)
    file_desc.close()

def main():
    contributors = get_contributions_from_gh()
    write_html(sort_contributions(contributors))

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("Aborted.", sys.stderr)
        sys.exit(1)
