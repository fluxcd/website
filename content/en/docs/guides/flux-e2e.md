---
title: "Flux from End-to-End"
linkTitle: "Flux from End-to-End"
description: "A narrative of the life of a commit as it relates to Flux components."
weight: 75
---

Below we describe the life of a commit as it is seen from all angles by a Flux user.

Assuming a standard Flux installation, with all optional features enabled, we then explain how Flux users can expect their changes to flow through the system as a commit, and interfaces as they pass through the system and the cluster, chronologically, at every step. We cover every supported opportunity that users have to inspect and interact with their changes through Flux, with a focus on the commit, and special attention to show the role of each component of the [GitOps toolkit](https://fluxcd.io/docs/components/).

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
* **Service** - When Kubernetes `Deployments` spawn workloads, they are placed in ephemeral `Pods` which usually are not directly addressable. `Services` are used to connect these `Endpoints` to a stable address that can usually be discovered through a DNS lookup in the cluster.


## Microservice architecture

Flux is composed of four separable core components or controllers: [Source Controller][], [Kustomize Controller][], [Helm Controller][], and [Notification Controller][], with two extra components: [Image Automation Controller][Image reflector and automation controllers] and [Image Reflector Controller][Image reflector and automation controllers]. These controllers or Agents run on the Cluster, and they define APIs which are based on Custom Resources that altogether implement the GitOps Toolkit.

**Source Controller** is the Agent responsible for pulling Commit data into the Cluster. Commits are made available as a read-only Service to Clients, which can connect with the Source Controller and fetch Artifacts, `.tar.gz` files containing Kubernetes Resource manifest data.

Besides artifact acquisition from external sources, the responsibilities of the Source Controller also include: verification of source authenticity through cryptographic signatures, detection of source changes based on semantic version policies, outbound notification of Cluster subscribers when updates are available, and also reacting to inbound notifications that represent Git push and Helm chart upload events.

**Kustomize Controller** is the Agent responsible for reconciling the cluster state with the desired state as defined by Commit manifests retrieved through Source controller. Kustomize controller delivers, or applies, resources into a cluster. The `Kustomization` is the Custom Resource or API through which a Flux user defines how Kustomize controller delivers workloads from sources.

The Kustomize controller is responsible for validating manifests against the Kubernetes API, and managing access to permissions in a way that is safe for multi-tenant clusters through Kubernetes Service Account impersonation. The controller supports health assessment of deployed resources and dependency ordering, optionally enabled garbage collection or "pruning" of deleted resources from the cluster when they are removed from the source, and also notification of when cluster state changes – Kustomizations can also target and deliver resources onto a remote cluster, (which can, but does not necessarily also run its own local independent set of Flux controllers.)

The Kustomization API is designed from the beginning with support for multi-tenancy as a primary concern.

**Helm Controller** is the Agent responsible for managing Helm artifacts (with some parts of the work shared in the Source Controller). The Source Controller acquires Helm charts from Helm repositories or other sources. The desired state of a Helm release is described through a Custom Resource named `HelmRelease`. Based on the creation, mutation or removal of a `HelmRelease` resource in the cluster, Helm actions are performed by the controller.

Helm Controller (and its predecessor, Helm Operator) stand alone in the GitOps world as Go client implementations of the Helm package library. While there are many projects in the GitOps space that can perform "Helm Chart Inflation" which can also be explained through the activities of merging `values` from different sources, rendering templates, applying the changes to the cluster, and then waiting to become healthy, other projects usually cannot claim strict compatibility with all Helm features. Helm Controller boasts full compatibility and reliably identical behavior in Flux with all released Helm features.

Examples of some Helm Controller features that directly leverage upstream features of Helm today include [Helm Chart Hooks][], Helm Release Lifecycle events and the optional health checking that's performed by `helm --wait` to determine if a release is successful, Helm tests, rollbacks and uninstalls, and an implementation of Helm's [Post Rendering][] feature that allows safety and security while using the Kustomize post-renderer in Flux Continuous Delivery pipelines (that is, without requiring untrusted execution of any external scripts or binaries.)

**Notification Controller**
The Notification Controller is a Kubernetes operator, specialized in handling inbound and outbound events. The controller handles:
events coming from external systems (GitHub, GitLab, Bitbucket, Harbor, Jenkins, etc) and notifies the GitOps toolkit controllers about source changes.
events emitted by the GitOps toolkit controllers (source, kustomize, helm) and dispatches them to external systems (Slack, Microsoft Teams, Discord, RocketChat) based on event severity and involved objects.


 Links/resources:
Notification Controller: https://fluxcd.io/docs/components/notification/


**Image Automation Controller**
The Image Automation Controller automates updates to YAML when new container images are available.

Links/Resources:
Image Automation Controllers: https://fluxcd.io/docs/components/image/
Image update automation API reference: https://fluxcd.io/docs/components/image/automation-api/

**Image Reflector Controller**
The Image Reflector Controller scans image repositories and reflects the image metadata in Kubernetes resources.

Links/resources:
Image reflector API reference: https://fluxcd.io/docs/components/image/reflector-api/

The image-reflector-controller and image-automation-controller work together to update a Git repository when new container images are available.

## Config repo and the Flux CLI

Describe any critical components in the reference architecture that are not microservices or controllers

## High level architecture

Describe at an operational level, without connecting to specific Flux controllers or invoking any specific custom resources by name, what is the behavior of Flux at a high level?

## Commit flow

### Overview

A brief outline of the life cycle of a change as it's processed through Flux, centered around a git commit:

1. Flux resources are generated interactively through `flux create ...`.
2. The user can preview any changes to the cluster before or after making a commit with `flux diff kustomization`.
3. Image Update Automation resources are a way for Flux to generate commits when there are updated images available.
4. A git commit is represented internally as an "Artifact" in Flux, and it makes a footprint on the cluster through Source Controller.
5. The "git push" event fires a webhook that Flux can receive, which triggers the `GitRepository` to reconcile (or the waiting period of the `GitRepository.spec.interval` passes, which similarly triggers the `GitRepository` to reconcile.
6. The Source controller fetches the GitRepository data from the backing resource (Git, S3, ...).
7. If an optional decryption configuration is provided with the Flux Kustomization, any encrypted secret manifests that are stored in the Kustomization's path are decrypted.
7.5 The Kustomize Controller runs the go library equivalent of a `kustomize build` against the `Kustomization.spec.path` to recursively generate and render (or inflate) any Kustomize overlays. (All manifests are passed through Kustomize, even those that don't include a `kustomization.yaml`.)
8. Kustomize build outputs are then validated against the cluster through a server-side dry-run, and if it succeeds the manifests are applied to the cluster with a server-side apply operation.
9. `HelmRelease` resources applied to the cluster are picked up by Helm Controller, which reconciles them through the Helm client library.
10. Before `HelmReleases` can be installed, Source controller fetches the release index via `HelmRepository` and generates a `HelmChart`.
11. Alternatively, `GitRepository` sources can be used instead of `HelmRepository`. (Source controller still generates a `HelmChart`.)
12. The resources being reconciled generates `Events` as they undergo successful or unsuccessful state transitions, and the Notification controller collects them through `Alerts` to forward them to `Providers`.
13. Besides the "event stream" or channel-based providers, there are also `Providers` that map to Git hosting providers, so the success or failure of a `Kustomization` can be recorded on the commit through the "Checks API" or similar.
14. An optional Health Assessment enabled through `Kustomization.spec.wait` can revert or prevent an update from being applied if some resources do not become ready before the `Kustomization.spec.timeout` expires.

### 1. `flux create ...`

Before the commit, the Flux CLI provides `create` generators with an `--export` option so that users have some guide for how to create valid Flux resources.

`flux create source git --help`

`flux create kustomization --help`

These generators can be used interactively to imperatively create Flux resources in the cluster, or as preferred for GitOps: when called with the `--export` option, `flux create ...` can emit YAML on stdout, that can be captured in a file and committed to create the resource.

For more information, see: [`flux create`](https://fluxcd.io/docs/cmd/flux_create/).

Some resource options are not available through generators and can only be accessed through fields in YAML, (users are generally expected to write resources in YAML and commit them, and should do so when they require access to those features.) Flux's OpenAPI specification can also assist users in producing valid YAML for creating resources in Flux APIs.

### 2. `flux diff kustomization` / `flux build kustomization`

Users have an opportunity to inspect the change of a repository from the Flux CLI, ahead of where Flux actually applies it to the cluster.

Run `flux diff kustomization --path=./clusters/my-cluster flux-system` from the bootstrap repo, or point it at any other Flux Kustomization and the matching path in your configuration repository to observe what changes Flux will apply, even before they are committed and pushed. This takes account of the cluster state and so it can also be used at any time to check for drift on the cluster that Flux would revert back to the state in Git as soon as the Kustomization is reconciled, or at its next interval.

Any diff containing secret data is obscured so that no secret data is accidentally divulged from the diff output.

TODO: add mention of `flux build`

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

### 6. `GitRepository` Source (Artifacts and Revisions)

When a `GitRepository` resource is created in Flux, that resource is reconciled on an interval.

A GitRepository Custom Resource is a read-only view of the latest observed revision of a Source reference. All artifacts managed by Source Controller are stored as `.tar.gz` and for the majority of Flux, it doesn't matter what type of resource is behind the Source – it can be Git, S3, (or perhaps in the future OCI image.) Even Helm Charts that come from Helm Repositories are of course stored as tarballs.

(The one notable exception to this pattern is Image Update Automation, which does not read data from GitRepository source service, but reads the definition of the GitRepository and writes through its secretRef.)

The Git repository itself is usually an external entity with respect to the cluster (even if it might be hosted inside of the cluster.) The source is authenticated through either an SSH host key or TLS certificate verification to ensure that the host is valid. The source may also optionally be checked for [TODO ???]

### 7. Kustomize Controller (Decryption via SOPS)

The Kustomize Controller has the capability to decrypt secrets that have been encrypted and pushed to the repository. There are two easy ways to utilize decryption with Mozilla SOPS: Users can keep the decryption key inside the cluster or they can use an external key management system (Flux supports several options and you can find more information about them [here](https://fluxcd.io/docs/guides/mozilla-sops/). For more general information on the Kustomize Controller check out the documentation [here](https://fluxcd.io/docs/components/kustomize/)!


Kustomize Controller has the capability to decrypt secrets that are encrypted in the repository. Generally 2 easy ways to go about it:
Keep key inside cluster
External key management system (flux has support for several)

Links/Resources:
Kustomize Controller: https://fluxcd.io/docs/components/kustomize/
Mozilla SOPS: https://fluxcd.io/docs/guides/mozilla-sops/


### 8. Kustomize Controller (Server Side Apply) - Kingdon

Server-side reconciliation makes Flux more performant and improves overall observability among other things. The Kustomize Controller reads in the artifacts in the path and renders them through Kustomize build and then applies them. Server side apply allows Flux to transmit the Kubernetes resources to the cluster without shelling out to an external binary such as kubectl or passing stream data through a pipe. Server side apply improves the overall observability of the reconciliation process by reporting in real-time the garbage collection and health assessment actions. This whole operation is synchronous rather than asynchronous, so if the resources fail to become ready the transaction can be aborted after a timeout.

After secrets have been decrypted the resources need to be applied to the cluster. Kustomize Controller takes resources, gathers them, selects a path from that source and applies all the resources in it through Kustomize.
A server-side dry run is performed before the server-side apply to check for validity of the resources. The apply is then completed in two stages; if there are CRDs, namespaces, or other cluster-wide resources, they are applied first so they can be defined before any subordinate resources (custom resources, namespaced resources) that would depend on their creation.

<insert sequence diagram>?

FAQ: https://fluxcd.io/docs/faq/#what-is-the-behavior-of-kustomize-used-by-flux


### 9. Helm Controller (`HelmRelease` Custom Resource)
(Adjacent concept to Kustomize apply)

A [HelmRelease](https://fluxcd.io/docs/components/helm/api/) is a composition of a chart, the chart values (parameters to the chart), and any inputs like secrets or config maps that are used to compose the values. Declaring a HelmRelease will cause the Helm Controller to perform an install using the Helm client libraries. Any changes made to the HelmRelease will trigger the Helm Controller to perform an upgrade to actuate those changes. You can find more information about HelmReleases [here](https://fluxcd.io/docs/guides/helmreleases/) and more general info about Helm for Flux users [here](https://fluxcd.io/docs/use-cases/helm/).


### 10. HelmRepository and HelmChart (Sources for Helm)

A Helm Repository is the native and preferred source for Helm. The Helm Controller works in tandem with the Source Controller to provide a [HelmRepository API](https://fluxcd.io/docs/components/source/helmrepositories/) that collects the correct release version from the helm repo and republishes its data as a [HelmChart](https://fluxcd.io/docs/components/source/helmcharts/) artifact (another .tar.gz).

The helm repo itself is represented internally in the Source Controller as a YAML index of all releases, including any charts in the repository.


### 11. GitRepository and HelmChart (Alternative Sources for Helm)
GR can be used as a source for Helm Release. The Git repo is not a native storage format for helm and there are some idiosyncrasies when you’re using Helm Controller with a Git repository source. You can use a GitRepository as a source, but best practice is to limit it to 1:1 (don’t do mono repo) - bad idea to create a repo with 400 helm charts. The problem is that git repo sources are tgz files end up with lots of artifacts pulled each time (overloading). Orange juice analogy here?

So you have lots of tools at your disposal for making sources narrowly scoped, and if you will use them all, you can avoid any potential issues stemming from Helm Controller accidentally pulling in resources and causing source controller to repackage them again, when you did not need to include them in the chart.

Whatever it says it just needs to get the message across that the Source is really a .tgz at any point in time, which can't be partially downloaded, and the Helm Chart is also a .tgz, so if you want this to perform well, you need to keep irrelevant things out of both TGZ files (and this unfortunately means you will have a lot more GitRepository resources than you wanted, at least for now. Not sure how this can be improved without drastic architectural changes that seem unlikely.)

It's probably important to get across also that whatever winds up in the Helm Chart .tgz will actually be loaded into memory by Helm, and it has no way to know which files are not important. So while you can get away with reusing one GitRepository up to a point, you really need to know for sure that what goes into the HelmChart is not littered with unnecessary files more than what's needed.

Links/resources:
TODO: this all belongs in one of the Helm guides

### 12. Notifications Part 1 - Notification Providers
Notification Providers are used by Flux for outbound notifications to platforms like slack, ms teams, discord. They are driven by `Alerts`, another CRD in the Flux Notification Controller's API. `Alerts` create notifications from events, and all of the flux reconcilers generate events while they are undergoing status transitions.

Links/resources:
Setup Notifications: https://fluxcd.io/docs/guides/notifications/
Alert: https://fluxcd.io/docs/components/notification/alert/
Event? https://fluxcd.io/docs/components/notification/event/

### 13. Notifications Part 2 - Git Commit Status Providers
Git Commit Status Providers work like other notification providers except that they target a specific commit with their event. If you [set up git commit status notications](https://fluxcd.io/docs/guides/notifications/#git-commit-status) through an integration for GitHub, GitLab, Bitbucket (or any supported git providers) Flux will display success or failure reported on each commit from any alerts targeting the provider.

### 14. Kustomize Controller (Health Checks and Wait)
Kustomize Controller can be configured with or without spec.wait which decides whether the Kustomization will be considered ready as soon as the resources are applied, or if the Kustomization will not be considered ready until the resources it created are all marked as ready.

Links/resources:
Health Assessment: https://fluxcd.io/docs/components/kustomize/kustomization/#health-assessment

### 15. ...


[Source controller]: https://fluxcd.io/docs/components/source/
[Kustomize controller]: https://fluxcd.io/docs/components/kustomize/
[Helm controller]: https://fluxcd.io/docs/components/helm/
[Notification controller]: https://fluxcd.io/docs/components/notification/
[Image reflector and automation controllers]: https://fluxcd.io/docs/components/image/
[Helm Chart Hooks]: https://helm.sh/docs/topics/charts_hooks/
[Post Rendering]: https://helm.sh/docs/topics/advanced/#post-rendering
[MORE]
