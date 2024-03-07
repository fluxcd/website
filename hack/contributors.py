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
import yaml

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
        'cues',
        'flagger',
        'flux-benchmark',
        'flux2',
        'flux2-kustomize-helm-example',
        'flux2-monitoring-example',
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
        'test-infra',
        'website'
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

# If you are trying to make this list have a stable sort order, you haven't understood.
# This function is intended to return the contributors in order of the most contributions.
# People move up and down the list because they are making contributions and going up and
# down in the rankings. Do not attempt to make this return stable sorted results. It's OK
# for this leaderboard to change every week.
def sort_contributions(contributors):
    contribs = [{'name': x,
                 'contributions': contributors[x]['contributions'],
                 'avatar_url': contributors[x]['avatar_url']} for x in contributors.keys()]
    contribs = sorted(contribs, key=lambda a: a['name'], reverse=False)
    contribs = sorted(contribs, key=lambda a: a['contributions'], reverse=True)
    for x in contribs:
        x.pop('contributions')
    return contribs


def write_yaml(contributors):
    out_file = os.path.join(MAIN_PATH, 'data/contributors.yaml')
    if os.path.exists(out_file):
        os.remove(out_file)
    with open(out_file, 'w') as stream:
        yaml.dump(contributors, stream)
        stream.close()

def main():
    contributors = get_contributions_from_gh()
    write_yaml(sort_contributions(contributors))

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("Aborted.", sys.stderr)
        sys.exit(1)
