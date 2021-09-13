---
title: "Bootstrap Flux with a privately hosted GitLab instance"
description: Bootstrap Flux with a privately hosted GitLab instance
---

## Before you begin

To follow this guide you will need the following:

- The Flux CLI. [Install the Flux CLI](../installation.md#install-the-flux-cli)
- A Kubernetes Cluster.

## Run bootstrap for a repository on a privately hosted GitLab instance

```bash
flux bootstrap gitlab \
  --hostname=my-gitlab.com \
  --token-auth \
  --owner=my-gitlab-group \
  --repository=my-repository \
  --branch=master
```
