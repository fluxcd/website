---
title: Reconciliation
description: In Flux, Reconciliation refers to ensuring that a given state (e.g application running in the cluster, infrastructure) matches a desired state declaratively defined somewhere (e.g a git repository).
weight: 5
---

## Reconciliation Overview

-- talk about how the controllers reconcile in flux

- HelmRelease reconciliation: ensures the state of the Helm release matches what is defined in the resource, performs a release if this is not the case (including revision changes of a HelmChart resource).
- Bucket reconciliation: downloads and archives the contents of the declared bucket on a given interval and stores this as an artifact, records the observed revision of the artifact and the artifact itself in the status of resource.
- [Kustomization](#kustomization) reconciliation: ensures the state of the application deployed on a cluster matches resources contained in a git repository.