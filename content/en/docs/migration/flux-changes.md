---
title: "Changes Between V1 and V2"
linkTitle: "Changes"
description: "Brief overview of changes between Flux V1 and V2"
weight: 60
---

## Reconciliation

Flux v1                                                                      | Flux v2
-----------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------
Limited to a single Git repository                                           | Multiple Git repositories
Declarative config via arguments in the Flux deployment                      | `GitRepository` custom resource, which produces an artifact which can be reconciled by other controllers
Follow `HEAD` of Git branches                                                | Supports Git branches, pinning on commits and tags, follow SemVer tag ranges
Suspending of reconciliation by downscaling Flux deployment                  | Reconciliation can be paused per resource by suspending the `GitRepository`
Credentials config via Arguments and/or Secret volume mounts in the Flux pod | Credentials config per `GitRepository` resource: SSH private key, HTTP/S username/password/token, OpenPGP public keys

## `kustomize` support

Flux v1                                                                                      | Flux v2
---------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------
Declarative config through `.flux.yaml` files in the Git repository                          | Declarative config through a `Kustomization` custom resource, consuming the artifact from the GitRepository
Manifests are generated via shell exec and then reconciled by `fluxd`                        | Generation, server-side validation, and reconciliation is handled by a specialized `kustomize-controller`
Reconciliation using the service account of the Flux deployment                              | Support for service account impersonation
Garbage collection needs cluster role binding for Flux to query the Kubernetes discovery API | Garbage collection needs no cluster role binding or access to Kubernetes discovery API
Support for custom commands and generators executed by fluxd in a POSIX shell                | No support for custom commands

## Helm integration

Flux v1                                                                 | Flux v2
------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------
Declarative config in a single Helm custom resource                     | Declarative config through `HelmRepository`, `GitRepository`, `Bucket`, `HelmChart` and `HelmRelease` custom resources
Chart synchronization embedded in the operator                          | Extensive release configuration options, and a reconciliation interval per source
Support for fixed SemVer versions from Helm repositories                | Support for SemVer ranges for `HelmChart` resources
Git repository synchronization on a global interval                     | Planned support for charts from GitRepository sources
Limited observability via the status object of the HelmRelease resource | Better observability via the HelmRelease status object, Kubernetes events, and notifications
Resource heavy, relatively slow                                         | Better performance
Chart changes from Git sources are determined from Git metadata         | Chart changes must be accompanied by a version bump in `Chart.yaml` to produce a new artifact

## Notifications, webhooks, observability

Flux v1                                                                                                              | Flux v2
---------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Emits "custom Flux events" to a webhook endpoint                                                                     | Emits Kubernetes events for included custom resources
RPC endpoint can be configured to a 3rd party solution like FluxCloud to be forwarded as notifications to e.g. Slack | Flux v2 components can be configured to POST the events to a `notification-controller` endpoint. Selective forwarding of POSTed events as notifications using `Provider` and `Alert` custom resources.
Webhook receiver is a side-project                                                                                   | Webhook receiver, handling a wide range of platforms, is included
Unstructured logging                                                                                                 | Structured logging for all components
Custom Prometheus metrics                                                                                            | Generic / common `controller-runtime` Prometheus metrics
