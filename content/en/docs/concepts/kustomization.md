---
title: Kustomizations
Description: Kustomizations specify how objects get applied to your cluster 
weight: 4
---

Kustomizations

A Kustomization represents a set of Kubernetes resources that Flux reconciles within the cluster. 

## What is a Kustomization?

A kustomization is a YAML manifest that specifies
- a source for an application manifest
- what manifests are to be applied to the cluster
- how often they are reconciled

## Working with Kustomizations

Kustomization objects can be either generated on the command line, using the Flux CLI tool, or written by hand.

```bash
$ flux example command
```
```yaml

```

## Kustomizations in action
The reconciliation runs every one minute by default but this can be specified in the kustomization. If you make any changes to the cluster using `kubectl edit` or `kubectl patch`, it will be promptly reverted. You either suspend the reconciliation or push your changes to a Git repository.

For more information, take a look at [this documentation](../components/kustomize/kustomization.md).
