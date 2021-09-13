---
title: "Bootstrap Flux on GitHub"
description: Bootstrap Flux for a GitHub account or GitHub Organization
---

## Before you begin

To follow the guide, you need the following:

- **A Kubernetes cluster**
- **The Flux CLI**
- **A GitHub personal access token with repo permissions**. See the GitHub documentation on [creating a personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line).

## Export your GitHub personal access token

Export your GitHub personal access token and username:

```bash
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=<your-username>
```

## Run bootstrap for a personal GitHub Repository

Run bootstrap for a repository on your personal GitHub account:

```bash
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=<insert-repo-name> \
  --personal
```

## Run bootstrap for a repository owned by a GitHub organization:

```bash
flux bootstrap github \
  --owner=my-github-organization \
  --repository=my-repository \
  --team=team1-slug \
  --team=team2-slug
```
