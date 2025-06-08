---
title: "Flux multi-tenancy"
linkTitle: "Multi-tenancy lockdown"
description: "How to configure Flux multi-tenancy lockdown"
weight: 12
---

Flux allows different organizations and/or teams to share the same Kubernetes control plane; this is
referred to as "multi-tenancy". To make this safe, Flux supports segmentation and isolation of
resources by using namespaces and role-based access control (RBAC).

## Flux authorization model

Flux defers to Kubernetes' native RBAC to specify which operations are authorized when processing
its custom resources. By default, this means operations are constrained by the
service account under which the controllers run, which has the `cluster-admin`
role bound to it. This is convenient for a deployment in which all users are trusted.

In a multi-tenant deployment, each tenant needs to be restricted in the operations that can be done
on their behalf. Since tenants control Flux via its API objects, this becomes a matter of attaching
RBAC rules to Flux API objects.

To give users control over the authorization, the Flux controllers can _impersonate_ (assume the
identity of) a service account mentioned in the apply specification (e.g., the field
`.spec.serviceAccountName` in
a [`Kustomization` object](https://fluxcd.io/flux/components/kustomize/kustomizations/#role-based-access-control)
or in a [`HelmRelease` object](https://fluxcd.io/flux/components/helm/helmreleases/#role-based-access-control))
for both accessing resources and applying configuration.
This lets a user constrain the operations performed by the Flux controllers with RBAC.

## Flux user roles

The tenancy model assume two types of users: platform admins and tenants.
Besides installing Flux, all the other operations (deploy applications, configure ingress, policies, etc)
do not require users to have direct access to the Kubernetes API. Flux acts as a proxy between users and
the Kubernetes API, using Git and OCI as the source of truth for the cluster desired state.

### Platform Admins

The platform admins have unrestricted access to Kubernetes API.
They are responsible for installing Flux and granting Flux
access to the sources (Git, Helm, OCI repositories) that make up the cluster(s) control plane desired state.
The repository(s) owned by the platform admins are reconciled on the cluster(s) by Flux, under
the [cluster-admin](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)
Kubernetes cluster role.

Example of operations performed by platform admins:

- Bootstrap Flux onto cluster(s).
- Extend the Kubernetes API with custom resource definitions and validation webhooks.
- Configure various controllers for ingress, storage, logging, monitoring, progressive delivery, etc.
- Set up namespaces for tenants and define their level of access with Kubernetes RBAC.
- Onboard tenants by registering their Git repositories with Flux.

### Tenants

The tenants have restricted access to the cluster(s) according to the Kubernetes RBAC configured
by the platform admins. The repositories owned by tenants are reconciled on the cluster(s) by Flux,
under the Kubernetes account(s) assigned by platform admins.

Example of operations performed by tenants:

- Register their sources with Flux (`GitRepositories`, `HelmRepositories` and `Buckets`).
- Deploy workload(s) into their namespace(s) using Flux custom resources (`Kustomizations` and `HelmReleases`).
- Automate application updates using Flux custom resources (`ImageRepositories`, `ImagePolicies`
  and `ImageUpdateAutomations`).
- Configure the release pipeline(s) using Flagger custom resources (`Canaries` and `MetricsTemplates`).
- Setup webhooks and alerting for their release pipeline(s) using Flux custom resources (`Receivers` and `Alerts`).

## How to configure Flux multi-tenancy

A platform admin can lock down Flux on multi-tenant clusters [during bootstrap](boostrap-customization.md) with the following patches:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --no-cross-namespace-refs=true
    target:
      kind: Deployment
      name: "(kustomize-controller|helm-controller|notification-controller|image-reflector-controller|image-automation-controller)"
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --no-remote-bases=true
    target:
      kind: Deployment
      name: "kustomize-controller"
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --default-service-account=default
    target:
      kind: Deployment
      name: "(kustomize-controller|helm-controller)"
  - patch: |
      - op: add
        path: /spec/serviceAccountName
        value: kustomize-controller
    target:
      kind: Kustomization
      name: "flux-system"
```

With the above configuration, Flux will:

- Deny cross-namespace access to Flux custom resources, thus ensuring that a tenant can't use another tenant's sources
  or subscribe to their events.
- Deny accesses to Kustomize remote bases, thus ensuring all resources refer to local files, meaning only the Flux
  Sources can affect the cluster-state.
- All `Kustomizations` and `HelmReleases` which don't have `spec.serviceAccountName` specified, will use the `default`
  account from the tenant's namespace.
  Tenants have to specify a service account in their Flux resources to be able to deploy workloads in their namespaces
  as the `default` account has no permissions.
- The flux-system `Kustomization` is set to reconcile under a service account with cluster-admin role,
  allowing platform admins to configure cluster-wide resources and provision the tenant's namespaces, service accounts
  and RBAC.

{{% alert color="info" title="Multi-tenancy example" %}}
The Flux team maintains a dedicated repository
at [github.com/fluxcd/flux2-multi-tenancy](https://github.com/fluxcd/flux2-multi-tenancy)
to showcase how platform admins can onboard tenants
and limit their access to the cluster resources with various policies.
{{% /alert %}}

### Flux cluster role aggregations

By default, Flux [RBAC](/flux/security/#controller-permissions) grants Kubernetes builtin
`view`, `edit` and `admin` roles access to Flux custom resources.

This allows tenants to manage Flux resources in their own namespaces using a Service Account
with a role binding to `admin`.

If you wish to disable the RBAC aggregation, you can remove the `flux-view` and `flux-edit`
cluster roles with:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      apiVersion: rbac.authorization.k8s.io/v1
      kind: ClusterRole
      metadata:
        name: flux
      $patch: delete
    target:
      kind: ClusterRole
      name: "(flux-view|flux-edit)-flux-system"
```

### Flux Object-level Workload Identity RBAC

Starting with v2.6, Flux supports object-level workload identity, which requires
additional RBAC permissions to be granted to the controllers so that they can create `ServiceAccount` tokens:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: crd-controller
rules:
  # excerpt from the existing rules
  - apiGroups:
      - ""
    resources:
      - serviceaccounts/token
    verbs:
      - create
```

If you wish to disable the object-level workload identity RBAC in Flux 2.6 or later, you can do so with the following patch:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      - op: remove
        path: /rules/10
    target:
      kind: ClusterRole
      name: "crd-controller-flux-system"
```
