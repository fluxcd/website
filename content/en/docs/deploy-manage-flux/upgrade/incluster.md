---
title: "Upgrade Flux In Cluster"
linkTitle: "In Cluster"
description: Upgrade Flux directly with the CLI and kubectl
weight: 524
---

## Before you begin

You will need the following:

- Upgraded the Flux CLI to the latest version

## Upgrade Flux

Use the upgrade method that is similar to how you bootstrapped Flux.

{{% tabs %}}
{{% tab flux install %}}
Apply the new Flux manifests by running ``flux install``:

```
flux install

```
{{% /tab %}}
{{% tab kubectl %}}
If you've installed Flux directly on the cluster with kubectl,
then rerun the command using the latest manifests from the `main` branch:

```bash
kustomize build <https://github.com/fluxcd/flux2/manifests/install?ref=main> | kubectl apply -f-
```
{{% /tab %}}
{{% /tabs %}}

## Check the upgrade

Use ``flux check``:

```bash
flux check
```
