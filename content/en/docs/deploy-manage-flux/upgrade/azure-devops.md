---
title: "Upgrade an Azure DevOps deployment of Flux"
linkTitle: "With Azure DevOps"
weight: 522
---

## Before you begin

You will need the following:

- Upgraded the Flux CLI to the latest version

## Generate updated Flux component manifests

Generate manifests for Flux with ``flux install``:

```bash
flux install \
  --export > ./flux-system/gotk-components.yaml
```

## Commit and push the updated component manifests

1. Add the manifest
  ```bash
  git add flux-system/gotk-components.yaml
  ```

2. Commit the changes
  ```bash
  git commit -m "Upgrade to $(flux -v)"
  ```

3. Push the changes
  ```bash
  git push
  ```
