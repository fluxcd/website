---
title: "Bootstrap Flux on GitHub Enterprise"
description: Bootstrap Flux using a GitHub enterprise
linkTitle: GitHub Enterprise
---

##  Before you begin

To follow this guide you will need the following:

- The Flux CLI. [Install the Flux CLI](../installation.md#install-the-flux-cli#install-the-flux-cli)
- A Kubernetes Cluster.

# Run bootstrap

You can use either SSH or HTTPS authentication for connecting to Git.

{{% tabs %}}
{{% tab SSH %}}
```bash
flux bootstrap github \
  --hostname=my-github-enterprise.com \
  --ssh-hostname=my-github-enterprise.com \
  --owner=my-github-organization \
  --repository=my-repository \
  --branch=main \
```
{{% /tab %}}
{{% tab HTTPS %}}
```bash
flux bootstrap github \
  --token-auth \
  --hostname=my-github-enterprise.com \
  --owner=my-github-organization \
  --repository=my-repository \
  --branch=main \
```
{{% /tab %}}
{{% tabs %}}
