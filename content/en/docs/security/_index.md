---
title: "Security Documentation"
linkTitle: "Security"
description: "Flux Security documentation."
---

<!-- For doc writers: Step-by-step security instructions should live on the appropriate documentation pages. To fulfil our primise to end users, we should briefly outline the context here, and link to the more detailed instruction pages from each relevant part of this outline. -->

{{% alert color="info" title="✍️⏳ Work in progress" %}}
This document is a work in progress.
Please follow [this GitHub issue](https://github.com/fluxcd/website/issues/598) to stay updated on goals and progress as we complete this page.
{{% /alert %}}

## Introduction

Flux has a multi-component design, and integrates with many other systems.

This document outlines an overview of security considerations for Flux components, project processes, artifacts, as well as Flux configurable options and what they enable for both Kubernetes cluster and external system security.

See our [security processes document](/security) for vulnerability reporting, handling, and disclosure of information for the Flux project and community.

## Controller permissions

While Flux integrates with other systems it is built on Kubernetes core controller-runtime and properly adheres to Kubernetes security model including RBAC.

<!-- See [Flux RBAC manifests](https://github.com/fluxcd/flux2/tree/main/manifests/rbac)
- Scott: spell out here in high-level human-readable terms -->

Flux installs a set of [RBAC manifests](https://github.com/fluxcd/flux2/tree/main/manifests/rbac).
These include:

1. A `crd-controller` `ClusterRole`, which:
    - Has full access to all the Custom Resource Definitions defined by Flux controllers
    - Can get, list, and watch namespaces and secrets
    - Can get, list, watch, create, patch, and delete configmaps and their status
    - Can get, list, watch, create, patch, and delete coordination.k8s.io leases
2. A `crd-controller` `ClusterRoleBinding`:
    - References `crd-controller` `ClusterRole` above
    - Bound to a service accounts for every Flux controller
3. A `cluster-reconciler` `ClusterRoleBinding`:
    - References `cluster-admin` `ClusterRole`
    - Bound to service accounts for only `kustomize-controller` and `helm-controller`

Flux uses these two `ClusterRoleBinding` strategies in order to follow the principle of least privilege, and to allow for clear access separation using tools purpose built for policy enforcement (OPA, Kyverno, admission controllers).

For example, the design allows all controllers to access Flux CRDs (binds to `crd-controller` `ClusterRole`), but only binds the Flux reconciler controllers for Kustomize and Helm to `cluster-admin` `ClusterRole`, as these are the only two controllers that manage resources in the cluster.

However in a soft multi-tenancy setup, Flux does not reconcile a tenant's repo under the `cluster-admin` role.
Instead you specify a different service account in your manifest, and the Flux controllers will use the Kubernetes Impersonation API under `cluster-admin` to impersonate that service account.
In this way, policy restrictions for this service account are applied to the manifests being reconciled.
If the binding is not defined for the correct service account and namespace, it will fail.
The roles and permissions for this multi-tenancy approach are described in detail here: https://github.com/fluxcd/flux2-multi-tenancy
