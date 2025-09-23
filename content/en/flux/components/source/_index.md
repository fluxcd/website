---
title: Source Controllers
linkTitle: Source Controllers
description: "The GitOps Toolkit Source Controllers documentation."
weight: 1
---

## Source controller

The main role of source-controller is to provide a common interface for artifacts acquisition.
The source API defines a set of Kubernetes objects that cluster admins and various automated operators can
interact with to offload the Git and Helm repositories operations to a dedicated controller.

![Source Controller Diagram](/img/source-controller.png)

Features:

- Validate source definitions
- Authenticate to sources (SSH, user/password, API token)
- Validate source authenticity (PGP)
- Detect source changes based on update policies (semver)
- Fetch resources on-demand and on-a-schedule
- Package the fetched resources into a well-known format (tar.gz, yaml)
- Make the artifacts addressable by their source identifier (sha, version, ts)
- Make the artifacts available in-cluster to interested 3rd parties
- Notify interested 3rd parties of source changes and availability (status conditions, events, hooks)

Links:

- Source code [fluxcd/source-controller](https://github.com/fluxcd/source-controller)
- Specification [docs](https://github.com/fluxcd/source-controller/tree/main/docs/spec)

## Source watcher

The source-watcher is a GitOps toolkit controller
that extends Flux with advanced source composition and decomposition patterns.

The source-watcher controller implements the **ArtifactGenerator** API,
which allows Flux users to:

- **Compose** multiple Flux sources (GitRepository, OCIRepository, Bucket) into a single deployable artifact
- **Decompose** monorepos into multiple independent artifacts with separate deployment lifecycles
- **Optimize** reconciliation by only triggering updates when specific paths change
- **Structure** complex deployments from distributed sources maintained by different teams

Links:

- Source code [fluxcd/source-watcher](https://github.com/fluxcd/source-watcher)
- Specification [docs](https://github.com/fluxcd/source-watcher/tree/main/docs/spec)
