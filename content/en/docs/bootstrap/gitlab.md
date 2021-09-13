---
title: "Gitlab"
description: Bootstrap flux with GitLab
---

## Before you begin

To follow this guide you will need the following:

- The Flux CLI. [Install the Flux CLI](../installation.md#install-the-flux-cli)
- A Kubernetes Cluster.

## Export your personal access token

Export your GitLab personal access token as an environment variable:

```bash
export GITLAB_TOKEN=<your-token>
```

## Bootstrap a personal repo

Run bootstrap for a repository on your personal GitLab account:

```bash
flux bootstrap gitlab \
  --owner=my-gitlab-username \
  --repository=my-repository \
  --branch=master \
  --token-auth \
  --personal
```

To run bootstrap for a repository using deploy keys for authentication, you have to specify the SSH hostname:

```
flux bootstrap gitlab \
  --ssh-hostname=gitlab.com \
  --owner=my-gitlab-username \
  --repository=my-repository \
  --branch=master
```

## Bootstrap a group or subgroup repo

Run bootstrap for a repository owned by a GitLab (sub)group:

```
flux bootstrap gitlab \
  --owner=my-gitlab-group/my-gitlab-subgroup \
  --repository=my-repository \
  --branch=master
```
