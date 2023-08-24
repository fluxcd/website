---
title: "GitOps Toolkit components"
linkTitle: "Toolkit Components"
description: "Documentation of the individual GitOps Toolkit components and their APIs."
weight: 60
---

Flux is constructed with the GitOps Toolkit components, which is a set of

- specialized tools and Flux Controllers
- composable APIs
- reusable Go packages for GitOps under the [fluxcd GitHub organisation](https://github.com/fluxcd)

for building Continuous Delivery on top of Kubernetes.

![GitOps Toolkit overview](/img/diagrams/gitops-toolkit.png)

The APIs comprise Kubernetes custom resources,
which can be created and updated by a cluster user, or by other
automation tooling.

You can use the toolkit to extend Flux, and to build your own systems
for continuous delivery. The [source-watcher
guide](../gitops-toolkit/source-watcher/) is a good place to start.

A reference for each component and API type is linked below.

- [Source Controller](source/_index.md)
    - [GitRepository CRD](source/gitrepositories.md)
    - [OCIRepository CRD](source/ocirepositories.md)
    - [HelmRepository CRD](source/helmrepositories.md)
    - [HelmChart CRD](source/helmcharts.md)
    - [Bucket CRD](source/buckets.md)
- [Kustomize Controller](kustomize/_index.md)
    - [Kustomization CRD](kustomize/kustomizations.md)
- [Helm Controller](helm/_index.md)
    - [HelmRelease CRD](helm/helmreleases.md)
- [Notification Controller](notification/_index.md)
    - [Provider CRD](notification/providers.md)
    - [Alert CRD](notification/alerts.md)
    - [Receiver CRD](notification/receivers.md)
- [Image automation controllers](image/_index.md)
    - [ImageRepository CRD](image/imagerepositories.md)
    - [ImagePolicy CRD](image/imagepolicies.md)
    - [ImageUpdateAutomation CRD](image/imageupdateautomations.md)
