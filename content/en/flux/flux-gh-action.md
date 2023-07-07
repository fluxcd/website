---
title: "Flux GitHub Action"
linkTitle: "Flux GitHub Action"
description: "How to use the Flux CLI in GitHub Actions workflows."
weight: 145
---

The Flux GitHub Action can be used to automate various tasks in CI such as:

- [Automate Flux upgrades on clusters via Pull Requests](#automate-flux-updates)
- [Push Kubernetes manifests to container registries](#push-kubernetes-manifests-to-container-registries)
- [Run end-to-end testing with Flux and Kubernetes Kind](#end-to-end-testing)

## Usage

```yaml
- name: Setup Flux CLI
  uses: fluxcd/flux2/action@main
  with:
    # Flux CLI version e.g. 2.0.0.
    # Defaults to latest stable release.
    version: 'latest'

    # Alternative download location for the Flux CLI binary.
    # Defaults to path relative to $RUNNER_TOOL_CACHE.
    bindir: ''
```

## Compatibility

The Flux GitHub Action is compatible with the Linux, macOS and Windows
[GitHub-hosted Runners](https://docs.github.com/en/actions/using-github-hosted-runners).

The Flux GitHub Action is compatible with
[self-hosted GitHub Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
for the following architectures:

- `amd64` (Linux, macOS, Windows)
- `arm64` (Linux, macOS)
- `arm/v7` (Linux)

## Examples

### Automate Flux updates

Example workflow for updating Flux's components generated with `flux bootstrap --path=clusters/production`:

```yaml
name: update-flux

on:
  workflow_dispatch:
  schedule:
    - cron: "0 * * * *"

permissions:
  contents: write
  pull-requests: write

jobs:
  components:
    runs-on: ubuntu-latest
    steps:
      - name: Check out code
        uses: actions/checkout@v3
      - name: Setup Flux CLI
        uses: fluxcd/flux2/action@main
      - name: Check for updates
        id: update
        run: |
          flux install \
            --export > ./clusters/production/flux-system/gotk-components.yaml

          VERSION="$(flux -v)"
          echo "flux_version=$VERSION" >> $GITHUB_OUTPUT
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v4
        with:
            token: ${{ secrets.GITHUB_TOKEN }}
            branch: update-flux
            commit-message: Update to ${{ steps.update.outputs.flux_version }}
            title: Update to ${{ steps.update.outputs.flux_version }}
            body: |
              ${{ steps.update.outputs.flux_version }}
```

### Push Kubernetes manifests to container registries

Example workflow for publishing Kubernetes manifests bundled as OCI artifacts to GitHub Container Registry:

```yaml
name: push-artifact-staging

on:
  push:
    branches:
      - 'main'

permissions:
  packages: write # needed for ghcr.io access

env:
  OCI_REPO: "oci://ghcr.io/my-org/manifests/${{ github.event.repository.name }}"

jobs:
  kubernetes:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Setup Flux CLI
        uses: fluxcd/flux2/action@main
      - name: Login to GHCR
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Generate manifests
        run: |
          kustomize build ./manifests/staging > ./deploy/app.yaml
      - name: Push manifests
        run: |
          flux push artifact $OCI_REPO:$(git rev-parse --short HEAD) \
            --path="./deploy" \
            --source="$(git config --get remote.origin.url)" \
            --revision="$(git branch --show-current)@sha1:$(git rev-parse HEAD)"
      - name: Deploy manifests to staging
        run: |
          flux tag artifact $OCI_REPO:$(git rev-parse --short HEAD) --tag staging
```

### Push and sign Kubernetes manifests to container registries

Example workflow for publishing Kubernetes manifests bundled as OCI artifacts
which are signed with Cosign and GitHub OIDC:

```yaml
name: push-sign-artifact

on:
  push:
    branches:
      - 'main'

permissions:
  packages: write # needed for ghcr.io access
  id-token: write # needed for keyless signing

env:
  OCI_REPO: "oci://ghcr.io/my-org/manifests/${{ github.event.repository.name }}"

jobs:
  kubernetes:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Setup Flux CLI
        uses: fluxcd/flux2/action@main
      - name: Setup Cosign
        uses: sigstore/cosign-installer@main
      - name: Login to GHCR
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Push and sign manifests
        run: |
          digest_url=$(flux push artifact \
          $OCI_REPO:$(git rev-parse --short HEAD) \
          --path="./manifests" \
          --source="$(git config --get remote.origin.url)" \
          --revision="$(git branch --show-current)@sha1:$(git rev-parse HEAD)" |\
          jq -r '. | .repository + "@" + .digest')

          cosign sign --yes $digest_url
```

### End-to-end testing

Example workflow for running Flux in Kubernetes Kind:

```yaml
name: e2e

on:
  push:
    branches:
      - '*'

jobs:
  kubernetes:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Setup Flux CLI
        uses: fluxcd/flux2/action@main
      - name: Setup Kubernetes Kind
        uses: helm/kind-action@main
      - name: Install Flux in Kubernetes Kind
        run: flux install
```

A complete e2e testing workflow is available here
[flux2-kustomize-helm-example](https://github.com/fluxcd/flux2-kustomize-helm-example/blob/main/.github/workflows/e2e.yaml)
