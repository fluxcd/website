---
title: Promote Flux Helm Releases with GitHub Actions
linkTitle: Promote Helm Releases with GitHub Actions
description: "How to configure a promotion workflow for Flux HelmReleases with GitHub Actions."
weight: 31
---

This guide shows how to configure Flux and GitHub Actions to promote
Helm Releases across environments when a new Helm chart version is available.

![Flux Helm promotion GitHub workflow](/img/flux-helm-github-promotion.png)

For this guide we assume a scenario with two clusters: staging and production;
with the following promotion pipeline:

- On the staging cluster, Flux will monitor the Helm repository for new chart versions,
  and it will automatically upgrade and test the Helm release.
- After the Helm release is successfully upgraded,
  Flux will send an event to GitHub that will trigger a GitHub Actions workflow.
- The GitHub workflow receives the new chart version, updates the Flux `HelmRelease`
  manifest YAML for the production cluster and opens a Pull Request.
- When the Pull Request is merged, Flux upgrades the Helm release on the production
  cluster to the chart version that was tested in staging.

## Prerequisites

For this guide we assume you have two clusters bootstrapped with Flux and a good understanding
of how Flux manages Helm releases. Please see the
[helm example repository](https://github.com/fluxcd/flux2-kustomize-helm-example)
to familiarise yourself with Flux and Helm.

## Define staging and production releases

For the staging cluster, we'll define a `HelmRelease` for which Flux will monitor the Helm repository,
and it will automatically upgrade the Helm release to the latest chart version based on a semver range.

Example of `clusters/staging/apps/demo.yaml`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta2
kind: HelmRelease
metadata:
  name: demo
  namespace: apps
spec:
  interval: 60m
  chart:
    spec:
      chart: demo
      version: "1.x" # automatically upgrade to the latest version
      interval: 5m # scan the Helm repository every five minutes
      sourceRef:
        kind: HelmRepository
        name: demo-charts
  test:
    enable: true # run tests on upgrades
  valuesFrom:
    - kind: Secret
      name: demo-staging-values
```

For the production cluster, we'll define a `HelmRelease` with a fixed version, the chart version will be
update in Git by GitHub Actions based on the Flux events.

Example of `clusters/production/apps/demo.yaml`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta2
kind: HelmRelease
metadata:
  name: demo
  namespace: apps
spec:
  interval: 60m
  chart:
    spec:
      chart: demo
      # This field will be updated by GitHub Actions.
      version: "1.0.0"
      sourceRef:
        kind: HelmRepository
        name: demo-charts
  valuesFrom:
    - kind: Secret
      name: demo-production-values
```

## Define the promotion GitHub workflow

To promote a chart version that was successfully deployed and tested on staging, we'll create a
GitHub workflow that reacts to Flux repository dispatch events.

Example of `.github/workflows/demo-promotion.yaml`:

```yaml
name: demo-promotion
on:
  repository_dispatch:
    types:
      - HelmRelease/demo.apps

permissions:
  contents: write
  pull-requests: write

jobs:
  promote:
    runs-on: ubuntu-latest
    # Start promotion when the staging cluster has successfully
    # upgraded the Helm release to a new chart version.
    if: |
      github.event.client_payload.metadata.env == 'staging' &&
      github.event.client_payload.severity == 'info'
    steps:
      # Checkout main branch.
      - uses: actions/checkout@v3
        with:
          ref: main
      # Parse the event metadata to determine the chart version deployed on staging.
      - name: Get chart version from staging
        id: staging
        run: |
          VERSION=$(echo ${{ github.event.client_payload.metadata.revision }} | cut -d '@' -f1)
          echo VERSION=${VERSION} >> $GITHUB_OUTPUT
      # Patch the chart version in the production Helm release manifest.
      - name: Set chart version in production
        id: production
        env:
          CHART_VERSION: ${{ steps.staging.outputs.version }}
        run: |
          echo "set chart version to ${CHART_VERSION}"
          yq eval '.spec.chart.spec.version=env(CHART_VERSION)' -i ./clusters/production/apps/demo.yaml
      # Open a Pull Request if an upgraded is needed in production.
      - name: Open promotion PR
        uses: peter-evans/create-pull-request@v4
        with:
          branch: demo-promotion
          delete-branch: true
          token: ${{ secrets.GITHUB_TOKEN }}
          commit-message: Update demo to v${{ steps.staging.outputs.version }}
          title: Promote demo release to v${{ steps.staging.outputs.version }}
          body: |
            Promote demo release on production to v${{ steps.staging.outputs.version }}
            
```

The above workflow does the following:

- Runs on repository dispatch events issued by Flux with the `HelmRelease/demo.apps` type.
- Filters the events to take into consideration only success Helm release upgrades.
- Clones the `main` branch where the Flux `HelmRelease` YAML manifests are defined.
- Parses the event metadata to determine the chart version deployed on staging.
- Patches the chart version in the `HelmRelease` manifest at `clusters/production/apps/demo.yaml`.
- Creates a new branch called `demo-promotion`, commits the version change and opens a Pull Request against `main`.

**Note** that you should adapt the workflow to match your release name, namespace and YAML path.

## Configure Flux for repository dispatching

On the staging cluster, we'll configure Flux to send events to GitHub every time
it performs a Helm release upgrade.

Example of `clusters/staging/apps/demo-github.yaml`:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Provider
metadata:
  name: github
  namespace: apps
spec:
  type: githubdispatch
  address: https://github.com/org/repo
  secretRef:
    name: github-token
---
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Alert
metadata:
  name: demo-dispatch
  namespace: apps
spec:
  providerRef:
    name: github
  summary: "Trigger promotion"
  eventMetadata:
    env: staging
    cluster: staging-1
    region: eu-central-1
  eventSeverity: info
  eventSources:
    - kind: HelmRelease
      name: demo
  inclusionList:
    - ".*.upgrade.*succeeded.*"
```

**Note** that you should adapt the above definitions to match your GitHub repository address.
If [testing is enabled](https://fluxcd.io/flux/components/helm/helmreleases/#configuring-helm-test-actions)
in your HelmRelease, you can use the `".*.test.*succeeded.*"`
expression in the inclusion list instead of `".*.upgrade.*succeeded.*"`.
This will ensure the promotion happens only after tests have been successfully run.

You also need to create a Kubernetes secret with a GitHub Personal Access Token
that has access to the repository:

```shell
kubectl -n apps create secret generic github-token \
--from-literal=token=${GITHUB_TOKEN}
```

{{% alert color="warning" title="GitHub PAT" %}}
Note that it is advised to create a dedicated user for Flux under your GitHub organisation.
Make the Flux user part of a GitHub team, so that you can give Flux access only
to the repositories used with `flux bootstrap github`.
{{% /alert %}}

## Relevant documentation

- [Guides > Manage Helm Releases](/flux/guides/helmreleases.md)
- [Toolkit Components > Helm Repository API](/flux/components/source/helmrepositories.md)
- [Toolkit Components > Helm Release API](/flux/components/helm/helmreleases.md)
- [Toolkit Components > Notification API > GitHub Dispatch](/flux/components/notification/providers/#github-dispatch)
