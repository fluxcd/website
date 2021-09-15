---
title: "Bootstrap Flux without a Git Repository"
description: Bootstrap Flux without a Git Repository for testing and development purposes.
linkTitle: Without Git
---

{{% warning %}}

Bootstrapping using this method is only for testing and development purposes. By using this method no state is stored in Git.

{{% /warning %}}

## Before you begin

To follow this guide you will need the following:

- The Flux CLI. [Install the Flux CLI](../installation.md#install-the-flux-cli)
- A Kubernetes Cluster.

## Install Flux

For testing purposes you can install Flux without storing its manifests in a Git repository:

```bash
flux install

```

Or using kubectl:

```bash
kubectl apply -f <https://github.com/fluxcd/flux2/releases/latest/download/install.yaml>
```
