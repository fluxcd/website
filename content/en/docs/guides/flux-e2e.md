---
title: "Flux from End-to-End"
linkTitle: "Flux from End-to-End"
description: "A narrative of the life of a commit as it relates to Flux components."
weight: 75
---

Below we describe the life of a commit as it is seen from all angles by a Flux user.

Assuming a standard Flux installation, with all optional features enabled, we then explain how Flux users can expect their changes to flow through the system as a commit, and interfaces as they pass through the system and the cluster, chronologically, at every step. We cover every supported opportunity that users have to inspect and interact with their changes through Flux, with a focus on the commit, and special attention to show the role of each component of the GitOps toolkit.

It should be clear from reading this document when any Flux component interacts with the cluster resources or APIs, or any commit or registry data. This document narrates through those interactions so that there can be an end-to-end analysis of how Flux works that includes mention of any authentication or security hardening procedures that are in play for Flux at runtime.

Security and hardening procedures that the Flux development team may be taking to guarantee Flux release-engineering standards for testing, runtime safety, and release quality are considered outside of the scope of this document.

See one of: [Security](https://fluxcd.io/docs/security/), [Contributing: Acceptance Policy](https://fluxcd.io/docs/contributing/flux/#acceptance-policy) for more information about those standards and practices. An exhaustive description of the precautions with regard to sensitive and/or secret data and flow of information related to sensitive access, is out of the scope of this document.

## Terminology

Flux uses the following terms throughout the codebase and documentation:

* **Cluster** - Any number of Kubernetes nodes, joined into a group to run containerized applications.
* **Commit** - A snapshot of a Git repository's state (or any Version Control System) at any given time.
* **Client** - Any application or resource manager which implements the "customer" side of any API or Service.
* **Resource** - In Kubernetes, a YAML data structure represents cluster objects that drive workloads like: `Deployment`, `Pod`, `Service`, `Ingress`, `StatefulSet`, `Job`, and many others.
* **Custom Resource** - Kubernetes provides a Custom Resource Definition (CRD) type for defining Custom Resources to be implemented by a controller. In Flux, examples include: `GitRepository`, `Bucket`, `HelmRepository`, `Kustomization`, `HelmRelease`, `Alert`, and others.
* **Field** - YAML resources are collections of data fields, which can be nested to create complex structures like with Array and Map.
* **Event** - A YAML resource emits events while undergoing state transitions, which themselves (`Event`) are also resources.
* **API** - In Kubernetes, an API consists of (usually) a CRD, a control loop, and optionally one or more admission or mutation hooks. Flux's APIs are also known, collectively, as the GitOps Toolkit.
* **Agent** - A process which runs in the cluster and does some work on behalf of users. Flux's controllers are "software agents" that implement a control loop.
* **Service** - When Kubernetes `Deployments` spawn workloads, they are placed in ephemeral `Pods` which usually are not directly addressible. `Services` are used to connect these `Endpoints` to a stable address that can usually be discovered through a DNS lookup in the cluster.


## Microservice architecture

Flux is composed of four separable core components or controllers: [Source Controller][], [Kustomize Controller][], [Helm Controller][], and [Notification Controller][], with two extra components: [Image Automation Controller][Image reflector and automation controllers] and [Image Reflector Controller][Image reflector and automation controllers]. These controllers or Agents run on the Cluster, and they define APIs which are based on Custom Resources that altogether implement the GitOps Toolkit.

**Source Controller** is the Agent responsible for pulling Commit data into the Cluster. Commits are made available as a read-only Service to Clients, which can connect with the Source Controller and fetch Artifacts, `.tar.gz` files containing Kubernetes Resource manifest data.

Besides artifact acquisition from external sources, the responsibilities of the Source Controller also include: verification of source authenticity through cryptographic signatures, detection of source changes based on semantic version policies, outbound notification of Cluster subscribers when updates are available, and also reacting to inbound notifications that represent Git push and Helm chart upload events.

**Kustomize Controller** is the Agent responsible for reconciling the cluster state with the desired state as defined by Commit manifests retrieved through Source controller. Kustomize controller delivers, or applies, resources into a cluster. The `Kustomization` is the Custom Resource or API through which a Flux user defines how Kustomize controller delivers workloads from sources.

The Kustomize controller is responsible for validating manifests against the Kubernetes API, and managing access to permissions in a way that is safe for multi-tenant clusters through Kubernetes Service Account impersonation. The controller supports health assessment of deployed resources and dependency ordering, optionally enabled garbage collection or "pruning" of deleted resources from the cluster when they are removed from the source, and also notification of when cluster state changes – Kustomizations can also target and deliver resources onto a remote cluster, (which can, but does not necessarily also run its own local independent set of Flux controllers.)

The Kustomization API is designed from the beginning with support for multi-tenancy as a primary concern.

**Helm Controller** is the Agent responsible for managing Helm artifacts (with some parts of the work shared in the Source Controller). The Source Controller acquires Helm charts from Helm repositories or other sources. The desired state of a Helm release is described through a Custom Resource named `HelmRelease`. Based on the creation, mutation or removal of a `HelmRelease` resource in the cluster, Helm actions are performed by the controller.

Helm Controller (and its predecessor, Helm Operator) stand alone in the GitOps world as Go client implementations of the Helm package library. While there are many projects in the GitOps space that can perform "Helm Chart Inflation" which can also be explained through the activities of merging `values` from different sources, rendering templates, applying the changes to the cluster, and then waiting to become healthy, other projects usually cannot claim strict compatibility with all Helm features. Helm Controller boasts full compatibility and reliably identical behavior in Flux with all released Helm features.

Examples of some Helm Controller features that directly leverage upstream features of Helm today include [Helm Chart Hooks][], Helm Release Lifecycle events and the optional health checking that's performed by `helm --wait` to determine if a release is successful, Helm tests, rollbacks and uninstalls, and an implementation of Helm's [Post Rendering][] feature that allows safety and security while using the Kustomize post-renderer in Flux Continuous Delivery pipelines (that is, without requiring untrusted execution of any external scripts or binaries.)

**Notification Controller**

**Image Automation Controller**

**Image Reflector Controller**

## Config repo and the Flux CLI

Describe any critical components in the reference architecture that are not microservices or controllers

## High level architecture

Describe at an operational level, without connecting to specific Flux controllers or invoking any specific custom resources by name, what is the behavior of Flux at a high level?

## Commit flow

### Overview

A brief outline of the life cycle of a change as it's processed through Flux, centered around a git commit:

1. Flux resources are generated interactively through `flux create ...`
2. The user can preview any changes to the cluster before or after making a commit with `flux diff kustomization`
3. Image Update Automation resources are a way for Flux to generate commits when there are updated images available
4. A git commit is represented internally as an "Artifact" in Flux, and it makes a footprint on the cluster through Source Controller
5. The "git push" event fires a webhook that Flux can receive 

### 1. `flux create ...`

Before the commit, the Flux CLI provides `create` generators with an `--export` option so that users have some guide for how to create valid Flux resources.

`flux create source git --help`

`flux create kustomization --help`

These generators can be used interactively to imperatively create Flux resources in the cluster, or as preferred for GitOps: when called with the `--export` option, `flux create ...` can emit YAML on stdout, that can be captured in a file and committed to create the resource.

For more information, see: [`flux create`](https://fluxcd.io/docs/cmd/flux_create/).

Some resource options are not available through generators and can only be accessed through fields in YAML, (users are generally expected to write resources in YAML and commit them, and should do so when they require access to those features.) Flux's OpenAPI specification can also assist users in producing valid YAML for creating resources in Flux APIs.

### 2. `flux diff kustomization`

Users have an opportunity to inspect the change of a repository from the Flux CLI, ahead of where Flux actually applies it to the cluster.

Run `flux diff kustomization --path=./clusters/my-cluster flux-system` from the bootstrap repo, or point it at any other Flux Kustomization and the matching path in your configuration repository to observe what changes Flux will apply, even before they are committed and pushed. This takes account of the cluster state and so it can also be used at any time to check for drift on the cluster that Flux would revert back to the state in Git as soon as the Kustomization is reconciled, or at its next interval.

Any diff containing secret data is obscured so that no secret data is accidentally divulged from the diff output.

### 3. `ImageRepository` and `ImageUpdateAutomation` with `ImagePolicy`

Flux can create git commits to apply updates to the cluster, that are applied in the standard GitOps way to the cluster (as a git commit), written by a Flux agent called Image Automation Controller. It works through these resources with the help of the Image Reflector Controller to determine when updates are available and apply them to the cluster.

### 4. `git commit`

Except when it happens as a result of Image Automation, the commit itself happens outside of Flux's purview, so the commit event itself has no effect on remote systems until it is pushed.

When the cluster reconciles a Source resource (like `GitRepository` or `Bucket`) the content in the new revision is captured on the cluster through a set of filters (sourceignore, spec.ignore, ...) and collected in a tar file to be stored; this file is known as an Artifact in Flux, and it can be accessed by any agent in the `flux-system` namespace.

When pushed, the receipt of a new commit activates the Git host to fire a webhook to notify subscribers about a `push` event, which Flux can consume via its `Receiver` API.

### 4.5 `NetworkPolicy` and the `flux-system` namespace

Arbitrary clients cannot connect to any service in the `flux-system` namespace, as a precaution to limit the potential for new features to create and expose attack surfaces within the cluster. A set of default network policies restricts communication in and out of the `flux-system` namespace according to three rules:

1. `allow-scraping` permits clients from any namespace to reach port 8080 on any pods in the cluster, for the purpose of collecting metrics. (This can be further restricted when the metrics collectors are known to be deployed in a specific namespace.)

2. `allow-webhooks` permits clients from any namespace to reach the Flux notification controller on any port, for the purpose of sending notifications via webhook when events are emitted from sources that the Notification Controller can be subscribed to.

3. `allow-egress` permits agents in the `flux-system` namespace to send traffic outside of the namespace, (for the purpose of reaching any remote `GitRepository`, `HelmRepository`, `ImageRepository`, or `Provider`), and denies ingress for any traffic from pods or other clients outside of `flux-system` to prevent any traffic directed into the namespace.

### 5. `git push` - Webhook Receivers

When activated by an event from a `Receiver`, Flux's Notification controller activates `GitRepository` or other Flux "sources" ahead of schedule, without first waiting for a `spec.interval` to elapse.

If `Receivers` are not configured, the `GitRepository` will activate on an interval, or can be reconciled on-demand ahead of the interval through the `flux reconcile source git`. This is a difference between Flux controllers and the Kubernetes Controller Runtime at-large, which Flux's code is directly based upon, where reconciling is usually done immediately upon detecting a change, rather than at intervals, and this is able to be accomplished roughly instantaneously through a publisher-subscriber model.

Resources like GitRepository and Bucket (and other Source API kinds) can be also be activated by webhook receivers to provide a similar experience. Webhook receivers are used to make Flux's pull-based model as fast and responsive as push-based pipelines, but importantly they do not make Flux "push-based" as the event contains no instructions, and only serves as an "early wake-up call" to notify Flux controllers. (It is not intended to be possible for Receivers to change anything else about the behavior of Flux, except for reconciling ahead of schedule.)

Any Flux resource that subscribes to any outside service (those that are external to the Kubernetes cluster) can be instrumented via webhooks that publish the events. These events can come from container image registries, Helm chart repositories, Git Repositories, or other arbitrary systems that are capable of sending a generic event through HTTP POST to notify when a new artifact is made available.

This capability allows Flux to manage resources outside of the cluster with like-native performance, and helps users avoid creating a performance bottleneck by polling on excessively short intervals.

The period of waiting for the reconciliation interval can be increased or reduced for each Flux resource that reconciles an outside, but generally 30s is the lower bound on Flux's reconciling intervals. This is mentioned here because Flux is specifically used by many organizations seeking to better their development practices by improving their DORA metrics (from the DevOps Research and Assessment team at Google Cloud).

One of the measures generally considered important is how long it takes for developers to get feedback from CI/CD systems. It's commonly put forth that "the CI feedback loop should not take longer than 10 minutes." It should be clear from those relevant materials that for tasks we do many times every day, seconds add up to minutes quickly. For this reason it is recommended to use Receivers wherever possible, or at least whenever shortening the feedback loop is to be considered as an important goal.

### 6. GitRepository Source (Artifacts and Revisions)

### 7. Kustomize Controller (Decryption via SOPS)

### 8. Kustomize Controller (Server Side Apply)

### 9. Helm Controller (`HelmRelease` Custom Resource)

### 10. HelmRepository and HelmChart (Sources for Helm)

### 11. GitRepository and HelmChart (Alternative Sources for Helm)

### 12. Notifications Part 1 - Notification Providers

### 13. Notifications Part 2 - Git Commit Status Providers

### 14. Kustomize Controller (Health Checks and Wait)

### 15. ...

[Source controller]: https://fluxcd.io/docs/components/source/
[Kustomize controller]: https://fluxcd.io/docs/components/kustomize/
[Helm controller]: https://fluxcd.io/docs/components/helm/
[Notification controller]: https://fluxcd.io/docs/components/notification/
[Image reflector and automation controllers]: https://fluxcd.io/docs/components/image/
[Helm Chart Hooks]: https://helm.sh/docs/topics/charts_hooks/
[Post Rendering]: https://helm.sh/docs/topics/advanced/#post-rendering
