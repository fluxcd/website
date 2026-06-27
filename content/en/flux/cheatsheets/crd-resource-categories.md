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

## Usage examples

### List all Flux resources

To list all Flux custom resources across all namespaces:

```cli
kubectl get fluxcd -A
```

### List Flux resources in the default `kubectl get all` output

Flux resources now appear alongside built-in Kubernetes resources when running:

```cli
kubectl get all -n flux-system
```

### List resources by category

List all source resources:

```cli
kubectl get fluxcd-sources -A
```

List all applier resources (Kustomizations and HelmReleases):

```cli
kubectl get fluxcd-appliers -A
```

List all notification resources:

```cli
kubectl get fluxcd-notifications -A
```

List all image automation resources:

```cli
kubectl get fluxcd-images -A
```

### Filter by namespace

List all Flux resources in a specific namespace:

```cli
kubectl get fluxcd -n flux-system
```

### Combine with other kubectl options

You can combine category selectors with any `kubectl get` option.
For example, to get YAML output for all Flux sources:

```cli
kubectl get fluxcd-sources -A -o yaml
```

Or to watch for changes to all Flux resources:

```cli
kubectl get fluxcd -A --watch
```

{{% alert color="info" title="Tip" %}}
Using `kubectl get fluxcd` is the quickest way to get an overview of all Flux resources
in your cluster. It replaces the need to query each CRD type individually
(e.g. `kubectl get gitrepositories`, `kubectl get kustomizations`, etc.).
{{% /alert %}}
