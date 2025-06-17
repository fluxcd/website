---
author: Matheus Pimenta & Stefan Prodan
date: 2025-07-07 12:00:00+00:00
title: Time-based deployments with Flux Operator
description: "Update your Kubernetes workloads based on schedules with Flux Operator"
url: /blog/2025/07/time-based-deployments/
tags: [ecosystem]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

We are thrilled to announce time-based deployments, a feature long-awaited by Flux users, in
[Flux Operator v0.23.0](https://github.com/controlplaneio-fluxcd/flux-operator/releases/tag/v0.23.0)!

![](featured-image.png)

Organizations using Flux for GitOps deployments frequently require sophisticated control over when
changes are applied to production systems, particularly in regulated industries or critical business
environments. Key requirements include adhering to Change Advisory Board (CAB) approval windows,
enforcing "No Deploy Fridays" policies, and restricting deployments during peak business hours to
ensure service stability.

Maintenance windows become critical when managing helm upgrades, where teams need to skip reconciliation
unless the current time falls within a specified interval. In regulated environments like medical device
companies, automated deployments must be controlled to prevent unexpected disruptions during critical
operational periods. Large telecommunications providers and ISVs managing multiple client clusters need
gating mechanisms to control application rollouts, allowing tenants to consume platform updates when ready.

In this post, we show how to use time-based deployment with Flux Operator
[`ResourceSets`](https://fluxcd.control-plane.io/operator/resourcesets/introduction/).

## How it works

The Flux Operator ResourceSet API allows defining bundles of Flux objects by
templating a set of resources with inputs provided by the ResourceSetInputProvider API.

The ResourceSetInputProvider API allows pulling inputs from external sources, such as
GitHub pull requests, branches and tags. For example, on the reconciliation of a
ResourceSetInputProvider of type `GitHubTag`, the operator will list the tags of
a GitHub repository, filter them according to a semver range, and export a set of
inputs for each matching tag in the ResourceSetInputProvider `.status.exportedInputs`
field. For example:

```yaml
status:
  exportedInputs:
  - id: "48955639"
    tag: "6.0.4"
    sha: 11cf36d83818e64aaa60d523ab6438258ebb6009
```

Starting with Flux Operator v0.23.0, the ResourceSetInputProvider API now has the field
[`.spec.schedule`](https://fluxcd.control-plane.io/operator/resourcesetinputprovider/#schedule),
which allows defining a cron-based schedule for the reconciliation of the ResourceSetInputProvider.
For example:

```yaml
spec:
  schedule:
    # Every day-of-week from Monday through Thursday
    # between 10:00 to 16:00
    - cron: "0 10 * * 1-4"
      timeZone: "Europe/London"
      window: "6h"
    # Every Friday from 10:00 to 13:00
    - cron: "0 10 * * 5"
      timeZone: "Europe/London"
      window: "3h"
```

With this configuration, reconciliations of the ResourceSetInputProvider object
would only be allowed to run within the specified time windows. When the window
is active, the reconciliation happens normally, according to the interval defined
in the `fluxcd.controlplane.io/reconcileEvery` annotation.

## A complete example

- **Define a ResourceSetInputProvider**: This provider will scan a Git branch or tag
   for changes and export the commit SHA as an input.
- **Configure schedule**: The provider will have a reconciliation schedule
   that defines when it should check for changes in the Git repository.
- **Define a ResourceSet**: The ResourceSet will use the inputs from the provider
   to create a `GitRepository` and `Kustomization` that deploys the application
   at the specified commit SHA.

### ResourceSetInputProvider Definition

Assuming the Kubernetes deployment manifests for an application are stored in a Git repository,
you can define a input provider that scans a branch for changes
and exports the commit SHA:

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: ResourceSetInputProvider
metadata:
  name: my-app-main
  namespace: apps
  labels:
    app.kubernetes.io/name: my-app
  annotations:
    fluxcd.controlplane.io/reconcileEvery: "10m"
    fluxcd.controlplane.io/reconcileTimeout: "1m"
spec:
  schedule:
    - cron: "0 8 * * 1-5"
      timeZone: "Europe/London"
      window: 8h
  type: GitHubBranch # or GitLabBranch
  url: https://github.com/my-org/my-app
  secretRef:
    name: gh-app-auth
  filter:
    includeBranch: "^main$"
  defaultValues:
    env: "production"
```

For when Git tags are used to version the application, you can define an input provider
that scans the Git tags and exports the latest tag according to a semantic versioning:

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: ResourceSetInputProvider
metadata:
  name: my-app-release
  namespace: apps
  labels:
    app.kubernetes.io/name: my-app
  annotations:
    fluxcd.controlplane.io/reconcileEvery: "10m"
    fluxcd.controlplane.io/reconcileTimeout: "1m"
spec:
  schedule:
    - cron: "0 8 * * 1-5"
      timeZone: "Europe/London"
      window: 8h
  type: GitHubTag # or GitLabTag
  url: https://github.com/my-org/my-app
  secretRef:
    name: gh-auth
  filter:
    semver: ">=1.0.0"
    limit: 1
```

### ResourceSet Definition

The exported inputs can then be used in a `ResourceSet` to deploy the application
using the commit SHA from the input provider:

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: ResourceSet
metadata:
  name: my-app
  namespace: apps
spec:
  inputsFrom:
    - kind: ResourceSetInputProvider
      selector:
        matchLabels:
          app.kubernetes.io/name: my-app
  resources:
    - apiVersion: source.toolkit.fluxcd.io/v1
      kind: GitRepository
      metadata:
        name: my-app
        namespace: << inputs.provider.namespace >>
      spec:
        interval: 12h
        url: https://github.com/my-org/my-app
        ref:
          commit: << inputs.sha >>
        secretRef:
          name: gh-auth
        sparseCheckout:
          - deploy
    - apiVersion: kustomize.toolkit.fluxcd.io/v1
      kind: Kustomization
      metadata:
        name: my-app
        namespace: << inputs.provider.namespace >>
      spec:
        interval: 30m
        retryInterval: 5m
        prune: true
        wait: true
        timeout: 5m
        sourceRef:
          kind: GitRepository
          name: my-app
        path: deploy/<< inputs.env >>
```

When the `ResourceSetInputProvider` runs according to its schedule, if it finds a new commit,
the `ResourceSet` will be automatically updated with the new commit SHA which will trigger
an application deployment for the new version.

## Further reading

- [Complete Guide](https://fluxcd.control-plane.io/operator/resourcesets/time-based-delivery/)
- [ResourceSets Introduction](https://fluxcd.control-plane.io/operator/resourcesets/introduction/)
- [ResourceSets Documentation](https://fluxcd.control-plane.io/operator/resourceset/)
- [Schedule Documentation](https://fluxcd.control-plane.io/operator/resourcesetinputprovider/#schedule)
- [Schedule Status Documentation](https://fluxcd.control-plane.io/operator/resourcesetinputprovider/#schedule-status)
