---
title: "Ways of structuring your repositories"
linkTitle: "Ways of structuring your repositories"
description: "How to structure your Git repositories for a smooth GitOps experience with Flux."
weight: 10
---

This guide walks you through several approaches of organizing repositories
for a smooth GitOps experience with Flux.

## Monorepo

In a monorepo approach you would store all your Kubernetes manifests in a single Git repository.
The various environments specific configs are all stored in the same branch (e.g. `main`).

### Repository structure

Example structure (kustomize overlays):

```console
├── apps
│   ├── base
│   ├── production 
│   └── staging
├── infrastructure
│   ├── base
│   ├── production 
│   └── staging
└── clusters
    ├── production
    └── staging
```

Each cluster state is defined in a dedicated dir e.g. `clusters/production`
where the specific apps and infrastructure overlays are referenced.

The separation between apps and infrastructure makes it possible to
define the order in which a cluster is reconciled, e.g.
first the cluster addons and other Kubernetes controllers,
then the applications.

A complete example of this approach can be found at
[flux2-kustomize-helm-example](https://github.com/fluxcd/flux2-kustomize-helm-example).

### Delivery management

In trunk-based development, the changes are made in small batches and
are merged into the `main` branch often. Besides `main`, branches are short-lived,
once a pull request is merged, the branch gets deleted.

New app release can be automatically delivered to staging using Flux's [image updates to Git](image-update.md).
For production, you may choose to manually approve app version bumps by configuring Flux
to push the changes to a new branch from which you can create a pull request.
You can limit the impact of an issue that escaped staging testing by using Flagger's 
[canary releases](/flagger/).

Changes to infrastructure can be disruptive and could cause cluster-wide outages.
These config changes can be made in steps, first you merge a change to staging,
when the cluster is successfully reconciled, and the new cluster state passes conformance tests,
you then promote the change to production. The promotion process is gated by PR reviews
and end-to-end testing.

## Repo per environment

This approach is similar to the [monorepo](#monorepo), with some notable differences:

* In the monorepo approach, all team members can read the production config since Git is not designed to restrict access to certain files in a repository. Access control can be provided by tools like GitHub or GitLab, as they provide additional layers of security and permission management on top of Git. Having a separate repository for production means that you can grant access to a subset of team members while allowing everyone to clone staging and open pull requests.
* Promoting changes from one environment to another can be more time-consuming especially for infrastructure changes 
  that can't be automated with Flux image updates.
* When using the same repository for all environments, unintentional changes to production are harder to spot,
  especially for large pull requests. Having a dedicated production repository, limits the scope of changes
  and makes the review process less error prone.

## Repo per team

Assuming your organization has a dedicated platform admin team that provides Kubernetes as-a-service for other teams.

The platform admin team is responsible for:

* Setting up the staging and production environments.
* Maintains the cluster addon-ons and other cluster-wide resources (CRDs, controllers, admission webhooks, etc).
* Onboards the dev teams repositories using Flux's `GitRepository` custom resources.
* Configures how the dev teams repositories are reconciled on each cluster using Flux's `Kustomization` custom resources.

The dev teams are responsible for:

* Setting up the apps definitions (Kubernetes deployments, Helm releases).
* Configures how the apps are reconciled on each environment (Kustomize overlays, Helm values).
* Manages the apps promotion between environments using Flux's automated image updates to Git.

### Repository structure

Platform admin repository example (kustomize overlays):

```console
├── teams
│   ├── team1
│   ├── team2
├── infrastructure
│   ├── base
│   ├── production 
│   └── staging
└── clusters
    ├── production
    └── staging
```

Dev team repository example (kustomize overlays):

```console
└── apps
    ├── base
    ├── production 
    └── staging
```

A complete example of this approach can be found at
[flux2-multi-tenancy](https://github.com/fluxcd/flux2-multi-tenancy).

### Delivery

The delivery process is similar to the [monorepo](#delivery-management) one. The main difference is the
separation of concerns, the platform admin team handles the change management of the infrastructure,
but delegates the apps delivery to the dev teams.

## Repo per app

It is common to use the same repository to store both the application source code and its deployment manifests.
The deployment manifests from an app repo can serve as the base config for both the
[monorepo](#monorepo) and the [repo-per-team](#repo-per-team) approaches.

Instead of duplicating the deployment manifests between the app repo and the cluster(s) config repo,
the config repo can hold a _pointer_ to the app manifests.

Inside the config repo you can define a `GitRepository` that tells Flux to clone the app repo inside the cluster,
then with a `Kustomization`, you can tell Flux which directory holds the app manifests and how to patch
them based on the target environment.

Another option is to bundle the app manifests into a Helm chart and publish it to a Helm repository.
In the config repo you can define the `HelmRepository` and create an app `HelmRelease` for each
target environment.

### Repository structure

App repository plain Kubernetes manifests example:

```console
├── src
└── deploy
    └── manifests
```

Delivery example (stored in config repo):

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: app
spec:
  url: https://<host>/<org>/app
  ref:
    semver: "1.x"
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: app
spec:
  sourceRef:
    kind: GitRepository
    name: app
  path: ./deploy/manifests
  patches:
    - patch: |
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: app
        spec:
          replicas: 2
      target:
        kind: Deployment
        name: app
```

App repository Kustomize overlays example:

```console
├── src
└── deploy
    ├── base
    ├── production 
    └── staging
```

Delivery example (stored in config repo):

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: app
spec:
  url: https://<host>/<org>/app
  ref:
    branch: main
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: app
spec:
  sourceRef:
    kind: GitRepository
    name: app
  path: ./deploy/production
```

App repository Helm chart example:

```console
├── src
└── chart
    ├── templates
    ├── values.yaml 
    └── values-prod.yaml
```

Delivery example (stored in config repo):

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: apps
spec:
  url: https://<host>/<org>/charts
---
apiVersion: helm.toolkit.fluxcd.io/v2beta2
kind: HelmRelease
metadata:
  name: app
spec:
  chart:
    spec:
      chart: app
      version: "1.x"
      sourceRef:
        kind: HelmRepository
        name: apps
  values:
    replicas: 2
```
