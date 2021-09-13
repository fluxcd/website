---
title: "Upgrade Flux with the bootstrap command"
linkTitle: "With the bootstrap command"
---

## Before you begin

You will need the following:

- Upgraded the Flux CLI to the latest version

## Run the bootstrap command

Update the component manifests with ``flux bootstrap``:

```bash
flux bootstrap github \
  --owner=my-github-username \
  --repository=my-repository \
  --branch=main \
  --personal
```

## Reconcile the changes

Reconcile manifests from Git and upgrade using ``flux reconcile``:

```bash
flux reconcile source git flux-system
```

## Verify the upgrade

Verify that the controllers have been upgraded with:

```bash
flux check
```

## Next Steps

- Learn how to [Setup a GitHub action that opens a PR to update Flux](https://github.com/fluxcd/flux2/tree/main/action).
