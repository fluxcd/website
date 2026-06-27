---
title: "CRD resource categories"
linkTitle: "CRD Resource Categories"
description: "How to list and discover Flux resources using kubectl CRD categories."
weight: 35
---

Starting with Flux 2.9, all Flux Custom Resource Definitions (CRDs)
include [Kubernetes resource categories](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#categories)
that allow you to use `kubectl get` with category selectors to list Flux resources
across multiple CRD types in a single command.

## Categories

Every Flux CRD is assigned exactly three categories:

| Category | Scope | Description |
|---|---|---|
| `all` | Cluster-wide | Includes Flux resources in `kubectl get all` output |
| `fluxcd` | All Flux CRDs | Lists every Flux custom resource |
| Resource-specific | Per resource | Lists resources matching a specific Flux CRD category |

The resource-specific categories are:

| Category | Controllers | CRDs |
|---|---|---|
| `fluxcd-sources` | source-controller, source-watcher, flux-operator | `GitRepository`, `OCIRepository`, `HelmRepository`, `HelmChart`, `Bucket`, `ExternalArtifact`, `ArtifactGenerator`, `ResourceSetInputProvider` |
| `fluxcd-appliers` | kustomize-controller, helm-controller, flux-operator | `Kustomization`, `HelmRelease`, `ResourceSet`, `FluxInstance` |
| `fluxcd-notifications` | notification-controller | `Alert`, `Provider`, `Receiver` |
| `fluxcd-images` | image-reflector-controller, image-automation-controller | `ImageRepository`, `ImagePolicy`, `ImageUpdateAutomation` |
