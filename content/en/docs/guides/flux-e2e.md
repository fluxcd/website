---
title: "Flux from End-to-End"
linkTitle: "Flux from End-to-End"
description: "A narrative of the life of a commit as it relates to Flux components."
weight: 75
---

Below we describe the life of a commit as it is seen from all angles by a Flux user.

Assuming a standard Flux installation, with all optional features enabled, we then explain how Flux users can expect their changes to flow through the system as a commit, and interfaces as they pass through the system and the cluster, chronologically, at every step. We cover every supported opportunity that users have to inspect and interact with their changes through Flux, with a focus on the commit, and special attention to show the role of each component of the GitOps Toolkit.

It should be clear from reading this document when any Flux component interacts with the cluster resources or APIs, or any commit or registry data. This document narrates through those interactions so that there can be an end-to-end analysis of how Flux works that includes mention of any authentication or security hardening procedures that are in play for Flux at runtime.

Security and hardening procedures that the Flux development team may be taking to guarantee Flux release-engineering standards for testing, runtime safety, and release quality are outside of the scope of this document. (See [Editor: Do we have such a document or PR with this focus?](https://no-link-ready) for more information.)

While this document will also mention interfaces with sensitive data from time to time, an exhaustive description of the specific precautions and flow of information related to sensitive data is outside of the scope. (See [Documenting the use of sensitive data by Flux in the cluster](https://github.com/fluxcd/website/issues/595) for more on that.) (Editor: When this document has landed, replace this link with a reference to the permanent home.)

## Terminology

Flux uses the following terms throughout the codebase and documentation:

* **Cluster** - 
* **Commit** - 
* **Client** - 
* **Resource** - 
* **Field** - 
* **Event** - 
* **API** - 
* **Custom Resource** - 
* **Agent** - 
* **Service** - 


## Microservice architecture

Describe the architecture of Flux using terms above

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

Before the commit, Flux provides `create` generators with an `--export` option so that users have some guide for how to create valid Flux resources.

`flux create source git --help`

`flux create kustomization --help`

These generators can be used interactively to imperatively create Flux resources in the cluster, or as preferred for GitOps: when called with the `--export` option, `flux create ...` can emit YAML on stdout, that can be captured in a file and committed to create the resource.

For more information, see: [`flux create`](https://fluxcd.io/docs/cmd/flux_create/).

Some resource options are not available through generators and can only be accessed through fields in YAML, (users are generally expected to write resources in YAML and commit them, and should do so when they require access to those features.) Flux's OpenAPI specification can also assist users in producing valid YAML for creating resources in Flux APIs.

### 2. `flux diff kustomization`

Users have an opportunity to inspect the change of a repository from the Flux CLI, ahead of where Flux actually applies it to the cluster. This new feature landed in Flux 0.26.

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

