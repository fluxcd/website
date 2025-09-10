---
title: "Google Cloud Platform"
linkTitle: "Google Cloud Platform"
description: "How to configure access for the Flux integrations with Google Cloud Platform."
weight: 50
---

The Flux APIs integrate with the following Google Cloud Platform (GCP) services:

- The source-controller integrates the [OCIRepository](/flux/components/source/ocirepositories/) API with
  [Google Cloud Artifact Registry (GAR)](https://cloud.google.com/artifact-registry/docs/overview)
  for pulling OCI artifacts into the cluster.
- The image-reflector-controller integrates the [ImageRepository](/flux/components/image/imagerepositories/) and
  [ImagePolicy](/flux/components/image/imagepolicies/) APIs with GAR for scanning tags and digests of OCI artifacts
  and reflecting them into the cluster.
- The source-controller integrates the [Bucket](/flux/components/source/buckets/) API with
  [Google Cloud Storage (GCS)](https://cloud.google.com/storage/docs/introduction)
  for pulling manifests from buckets and packaging them as artifacts inside the cluster.
- The kustomize-controller integrates the [Kustomization](/flux/components/kustomize/kustomizations/) API with
  [Google Cloud Key Management Service (KMS)](https://cloud.google.com/kms/docs/key-management-service)
  for decrypting SOPS-encrypted secrets when applying manifests in the cluster.
- The kustomize-controller integrates the Kustomization API with
  [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine/docs/concepts/kubernetes-engine-overview)
  for applying manifests in remote GKE clusters.
- The helm-controller integrates the [HelmRelease](/flux/components/helm/helmreleases/) API with
  GKE for applying Helm charts in remote GKE clusters.
- The notification-controller integrates the [Provider](/flux/components/notification/providers/) API with
  [Google Cloud Pub/Sub](https://cloud.google.com/pubsub/docs/overview)
  for sending notifications about Flux resources outside the cluster.

The next sections briefly describe [GCP IAM](https://cloud.google.com/iam/docs/overview),
GCP's identity and access management system, and how it can be used to grant Flux access
to resources offered by the services above. Bear in mind that GCP IAM has more features
than the ones described here. We describe only the features that are relevant for the
Flux integrations.

> **Note**: Flux also supports Google Chat webhooks, but Google Chat webhooks do
> not support GCP IAM. For more information about the notification-controller
> integration with Google Chat, see the [Provider](/flux/components/notification/providers/) API docs.

## Identity

For all the integrations with GCP, GCP will authenticate two types of identities for Flux:

- [GCP Service Accounts](https://cloud.google.com/iam/docs/service-account-overview)
- [Kubernetes Service Accounts](https://kubernetes.io/docs/concepts/security/service-accounts/)

Each has its own methods of authentication. In particular, GCP Service Accounts
support both secret-based and secret-less authentication. Kubernetes Service
Accounts support only secret-less authentication. The latter is more secure and
easier to configure, but has a few limitations (a small number of GCP services
and edge cases do not have support for it, see the list
[here](https://cloud.google.com/iam/docs/federated-identity-supported-services#list)).

For further understanding how to configure authentication for both types of
identities, refer to the [Authentication](#authentication) section.

## Access Management

Identities in GCP need [permissions](https://cloud.google.com/iam/docs/overview#permissions)
to access resources from GCP services. Permissions cannot be granted directly to identities.
Instead, GCP uses [roles](https://cloud.google.com/iam/docs/overview#permissions) to group
permissions, and only roles can be granted to identities. Each role has a title and a globally
unique ID. For example, the role `Storage Object Viewer`, whose ID is `roles/storage.objectViewer`,
groups the following permissions (most omitted for brevity):

- `storage.objects.get`
- `storage.objects.list`
- ...

The structure of permissions is usually `<service>.<resource type>.<action>`.

GCP has a large number of
[predefined roles](https://cloud.google.com/iam/docs/roles-permissions),
but users can also create
[custom roles](https://cloud.google.com/iam/docs/creating-custom-roles)
inside their GCP projects.

For an identity to be allowed to perform an action on a resource, the identity
needs to be granted, *on that resource*, a role that contains the permission
required for that action. The role needs to be granted directly on the resource,
or on a parent resource in the
[resource hierarchy](https://cloud.google.com/iam/docs/overview#policy-inheritance):

- *Resource*
- *Project* (set of resources)
- *Folder* (set of projects)
- *Organization* (set of folders)

If the role is granted on a parent resource, the relationship will be inherited
by all the descendants. For example, if a role is granted on a folder, all the
projects and resources inside that folder will inherit the grant.

> **Reminder**: The grant relationship has *three* involved entities:
> - The identity that will use the permissions to perform actions.
> - The resource that will be the target of the actions.
> - The role containing the permissions required for the actions.

### Granting permissions

When granting roles, GCP IAM uses the term
[Principal](https://cloud.google.com/iam/docs/overview#principals), formerly
*Member*, to refer to the string that globally identifies the identity which
will receive the grant.

#### To GCP Service Accounts

The IAM Principal for a GCP Service Account is the email address of the Service
Account prefixed with `serviceAccount:`:

```
serviceAccount:SA_NAME@PROJECT_ID.iam.gserviceaccount.com
```

#### To Kubernetes Service Accounts

The IAM Principal for a Kubernetes Service Account from a *GKE cluster* has the
following format:

```
serviceAccount:PROJECT_ID.svc.id.goog[NAMESPACE/KSA_NAME]
```

Flux running inside non-GKE Kubernetes clusters (e.g. EKS, AKS, `kind` running locally
or in CI, etc.) can also get access to GCP resources. For Service Accounts from such
clusters, the IAM Principal has the following format:

```
principal://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/subject/system:serviceaccount:NAMESPACE:KSA_NAME
```

Where the portion `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID`
globally identifies the
[Workload Identity Pool](https://cloud.google.com/iam/docs/workload-identity-federation#pools)
configured for the non-GKE cluster.

See more details about how this works in the GCP docs
[Workload Identity Federation with Kubernetes](https://cloud.google.com/iam/docs/workload-identity-federation-with-kubernetes) and how to configure this
for Flux in the [Workload Identity Federation](#with-workload-identity-federation) section.

#### Via Config Connector IAM custom resources

To use [Config Connector](https://cloud.google.com/config-connector/docs/overview) for
granting roles you can use one of the following custom resources:

- [`IAMPolicy`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampolicy)
- [`IAMPartialPolicy`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampartialpolicy)
- [`IAMPolicyMember`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampolicymember)

All of them support both the `Organization`, `Folder` and `Project` high-level hierarchical
resource kinds, and the kinds for all the individual resource types that Flux integrates with.
For the individual resource types, see the [Authorization](#authorization) section below.

> **Note**: Config Connector is the most GitOps-friendly way of managing GCP
> resources. With it you can even use Flux itself to deploy and continuously reconcile
> your GCP custom resources (the Kubernetes ones), and Config Connector itself will
> [continuously reconcile](https://cloud.google.com/config-connector/docs/concepts/reconciliation)
> the actual GCP resources.

#### Via Terraform/OpenTofu IAM resources

To use Terraform/OpenTofu for granting roles you can use one of the following resources:

- `google_<resource type>_iam_policy`
- `google_<resource type>_iam_binding`
- `google_<resource type>_iam_member`

See the docs for the high-level hierarchical resources:

- [`organization`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_organization_iam)
- [`folder`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_folder_iam)
- [`project`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam)

For the Terraform/OpenTofu resources for the individual resource types that Flux integrates with,
see the [Authorization](#authorization) section below.

> **Note**: Terraform/OpenTofu is a great declarative way of managing GCP resources,
> but it's not as GitOps-friendly as Config Connector, as these tools do not prescribe
> continuous reconciliation of the resources. There are alternatives to achieve that,
> but they are not a core part of the tools.

#### Via the `gcloud` CLI

To use the `gcloud` CLI for granting roles you can use one of the following commands:

- `gcloud <resource type command> set-iam-policy`
- `gcloud <resource type command> add-iam-policy-binding`

See the docs for the high-level hierarchical resource commands:

- [`organizations`](https://cloud.google.com/sdk/gcloud/reference/organizations)
- [`resource-manager folders`](https://cloud.google.com/sdk/gcloud/reference/resource-manager/folders)
- [`projects`](https://cloud.google.com/sdk/gcloud/reference/projects)

For the `gcloud` commands for the individual resource types that Flux integrates with,
see the [Authorization](#authorization) section below.

> **Note**: The `gcloud` CLI is a great tool for experimenting with GCP resources and
> their integrations with Flux, but it's not a GitOps-friendly way of managing GCP
> resources. If you need continuous reconciliation of the resources, prefer using
> Config Connector or Terraform/OpenTofu.

## Authorization

In this section we describe the recommended roles and permissions for
enabling the Flux integrations with GCP services.

### For Google Cloud Artifact Registry

The `OCIRepository`, `ImageRepository` and `ImagePolicy` Flux APIs are integrated with
GAR. The `OCIRepository` API can be used to pull OCI artifacts from GAR repositories
into the cluster, while the `ImageRepository` and `ImagePolicy` APIs
can be used to reflect tags and digests of such artifacts also inside the cluster.

The recommended role containing the required permissions for the `OCIRepository`,
`ImageRepository` and `ImagePolicy` APIs is:

- [Artifact Registry Reader (`roles/artifactregistry.reader`)](https://cloud.google.com/iam/docs/roles-permissions/artifactregistry#artifactregistry.reader)

The Config Connector resource kinds for use with the IAM custom resources are:

- [`ArtifactRegistryRepository`](https://cloud.google.com/config-connector/docs/reference/resource-docs/artifactregistry/artifactregistryrepository)

The Terraform/OpenTofu IAM resource types are:

- [`artifact_registry_repository`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam)

The commands for the `gcloud` CLI are:

- [`artifacts repositories`](https://cloud.google.com/sdk/gcloud/reference/artifacts/repositories)

### For Google Cloud Storage

The `Bucket` Flux API is integrated with GCS. The `Bucket` API can be used
to pull manifests from GCS buckets and package them as artifacts inside the cluster.

The recommended roles containing the required permissions for the `Bucket` API are:

- [Storage Bucket Viewer (`roles/storage.bucketViewer`)](https://cloud.google.com/iam/docs/roles-permissions/storage#storage.bucketViewer)
- [Storage Object Viewer (`roles/storage.objectViewer`)](https://cloud.google.com/iam/docs/roles-permissions/storage#storage.objectViewer)

In the specific case of the `Bucket` API, both roles are needed because Flux needs to
confirm the existence of the bucket. If the bucket does not exist Flux can error out
earlier in the reconciliation process and give an error message that is easier to debug.

Alternatively, you can create a
[custom role](https://cloud.google.com/iam/docs/creating-custom-roles)
containing the following permissions:

- `storage.buckets.get`
- `storage.objects.get`
- `storage.objects.list`

The Config Connector resource kinds for use with the IAM custom resources are:

- [`StorageBucket`](https://cloud.google.com/config-connector/docs/reference/resource-docs/storage/storagebucket)

The Terraform/OpenTofu IAM resource types are:

- [`storage_bucket`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam)

The commands for the `gcloud` CLI are:

- [`storage buckets`](https://cloud.google.com/sdk/gcloud/reference/storage/buckets)

### For Google Cloud Key Management Service

The `Kustomization` Flux API is integrated with KMS.
The `Kustomization` API is used to apply manifests in the cluster, and it can use KMS to
decrypt SOPS-encrypted secrets before applying them.

The recommended role containing the required permissions for the `Kustomization` API is:

- [Cloud KMS CryptoKey Decrypter (`roles/cloudkms.cryptoKeyDecrypter`)](https://cloud.google.com/iam/docs/roles-permissions/cloudkms#cloudkms.cryptoKeyDecrypter)

This role can be granted either on a Key Ring (a set of keys), or on an individual Crypto Key.

The Config Connector resource kinds for use with the IAM custom resources are:

- [`KMSKeyRing`](https://cloud.google.com/config-connector/docs/reference/resource-docs/kms/kmskeyring)
- [`KMSCryptoKey`](https://cloud.google.com/config-connector/docs/reference/resource-docs/kms/kmscryptokey)

The Terraform/OpenTofu IAM resource types are:

- [`kms_key_ring`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_kms_key_ring_iam)
- [`kms_crypto_key`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_kms_crypto_key_iam)

The commands for the `gcloud` CLI are:

- [`kms keyrings`](https://cloud.google.com/sdk/gcloud/reference/kms/keyrings)
- [`kms keys`](https://cloud.google.com/sdk/gcloud/reference/kms/keys)

### For Google Kubernetes Engine

The `Kustomization` and `HelmRelease` Flux APIs can use [IAM Principals](#granting-permissions)
for applying and managing resources in remote GKE clusters. Two kinds of access must be configured
for this:

- The IAM Principal must have permission to call the `GetCluster` GKE API for the target
  remote cluster. The Flux controllers need to call this API for retrieving details required
  for connecting to the remote cluster, like the cluster's API server endpoint and certificate
  authority data. This is done by granting an IAM role to the IAM Principal that allows
  this action on the target remote cluster.
- The IAM Principal must have permissions inside the remote cluster to apply and manage the target
  resources. There are two ways of granting these permissions: via Kubernetes RBAC, or via IAM roles.
  The former means simply referencing the IAM Principal in `RoleBinding` or `ClusterRoleBinding`
  objects inside the remote cluster as the Kubernetes username. The latter means granting
  [IAM roles](https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control#iam-interaction)
  that grant Kubernetes permissions to the IAM Principal on the target remote cluster.
  The resulting set of permissions granted to the IAM Principal will be the union of the
  permissions granted via Kubernetes RBAC with the permissions granted via IAM roles.

In GCP a GKE cluster is regarded as a project-level resource, so IAM roles granting
access to GKE APIs can only be granted at the project level or higher in the
[resource hierarchy](#access-management).

#### Permissions for the GKE API

The recommended role containing the required permissions for calling the `GetCluster` GKE API is:

- [Kubernetes Engine Cluster Viewer (`roles/container.clusterViewer`)](https://cloud.google.com/iam/docs/roles-permissions/container#container.clusterViewer)

Alternatively, you can create a
[custom role](https://cloud.google.com/iam/docs/creating-custom-roles)
containing the following permission:

- `container.clusters.get`

#### Permissions inside the remote cluster

For granting Kubernetes RBAC to the IAM Principal, simply create the corresponding
`RoleBinding` or `ClusterRoleBinding` objects inside the remote cluster using the
principal as the Kubernetes username.

For granting cluster-scoped permissions through IAM roles, you can grant either
[built-in roles](https://cloud.google.com/kubernetes-engine/docs/how-to/iam#predefined) or
[custom roles](https://cloud.google.com/iam/docs/creating-custom-roles).

For an exhaustive list of the permissions that can be added to a custom IAM role for
cluster-scoped permissions, go to the page of the
[Kubernetes Engine Admin](https://cloud.google.com/kubernetes-engine/docs/how-to/iam#container.admin)
role and expand the collapsed section `container.*` at the very top of the
`Permissions` column.

> **Note**: Namespaced permissions can only be granted via Kubernetes RBAC.
> IAM roles can only grant cluster-scoped permissions. See
> [docs](https://cloud.google.com/kubernetes-engine/docs/how-to/iam#interaction_with_rbac).

### For Google Cloud Pub/Sub

The `Provider` Flux API is integrated with Pub/Sub. The `Provider` API can be used
to send notifications about Flux resources to Pub/Sub topics.

The recommended role containing the required permissions for the `Provider` API is:

- [Pub/Sub Publisher (`roles/pubsub.publisher`)](https://cloud.google.com/iam/docs/roles-permissions/pubsub#pubsub.publisher)

The Config Connector resource kinds for use with the IAM custom resources are:

- [`PubSubTopic`](https://cloud.google.com/config-connector/docs/reference/resource-docs/pubsub/pubsubtopic)

The Terraform/OpenTofu IAM resource types are:

- [`pubsub_topic`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam)

The commands for the `gcloud` CLI are:

- [`pubsub topics`](https://cloud.google.com/sdk/gcloud/reference/pubsub/topics)

## Authentication

As mentioned in the [Identity](#identity) section, GCP supports two types of
identities for Flux: GCP Service Accounts and Kubernetes Service Accounts.
This section describes how to authenticate each type of identity. Both types
support Workload Identity Federation (secret-less), but only GCP Service
Accounts support secret-based authentication.

> **Recommendation**: Always prefer secret-less over secret-based authentication
> if the alternative is available. Secrets can be stolen to abuse the permissions
> granted to the identities they represent, and for public clouds like GCP this can
> be done by simply having Internet access. This requires secrets to be regularly
> rotated and more security controls to be put in place, like audit logs, secret
> management tools, etc. Secret-less authentication does not have this problem, as
> the identity is authenticated using a token that is not stored anywhere and is
> only valid for a short period of time, usually one hour. It's much harder to
> steal an identity this way.

### With Workload Identity Federation

Workload Identity Federation is a GCP feature that allows external identities
to authenticate with GCP services without the need for a per-identity static credential.
This is done by exchanging a short-lived token issued by the external identity
provider (in this case, Kubernetes) for a short-lived Google OAuth 2.0 Access
Token. This access token is then used to authenticate with GCP services.
This process is more broadly known as *OIDC federation*.

#### Supported clusters

GCP supports Workload Identity Federation for both
[GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
and
[non-GKE](https://cloud.google.com/iam/docs/workload-identity-federation-with-kubernetes)
clusters.

In GKE Autopilot, Workload Identity Federation is always enabled, no cluster setup is required.
In GKE Standard, follow these
[docs](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#enable_on_clusters_and_node_pools).

For non-GKE clusters you need to
[create a Workload Identity Pool and a Workload Identity Provider](https://cloud.google.com/iam/docs/workload-identity-federation-with-kubernetes#create_the_workload_identity_pool_and_provider)
with the [Issuer URL](cross-cloud.md#source-cluster-setup) of the cluster.

To create a Workload Identity Pool and a Workload Identity Provider using Config Connector,
you can use the following custom resources:

- [`IAMWorkloadIdentityPool`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iamworkloadidentitypool)
- [`IAMWorkloadIdentityPoolProvider`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iamworkloadidentitypoolprovider)

To create a Workload Identity Pool and a Workload Identity Provider using Terraform/OpenTofu,
you can use the following resources:

- [`google_iam_workload_identity_pool`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool)
- [`google_iam_workload_identity_pool_provider`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider)

To create a Workload Identity Pool and a Workload Identity Provider using the `gcloud` CLI,
you can use the following commands:

- [`iam workload-identity-pools`](https://cloud.google.com/sdk/gcloud/reference/iam/workload-identity-pools)
- [`iam workload-identity-pools providers`](https://cloud.google.com/sdk/gcloud/reference/iam/workload-identity-pools/providers)

#### Supported identity types

When using Workload Identity Federation, Kubernetes Service Accounts are the
identity type used by default. In this case, roles must be granted using the
IAM Principal formats described in [this](#to-kubernetes-service-accounts)
section, with the appropriate format depending on whether the cluster is GKE
or not.

You can also optionally use the roles granted to a GCP Service Account
instead of the roles granted to a Kubernetes Service Account with
Workload Identity Federation, but a Kubernetes Service Account is still
required. This is done by a process called *impersonation*. To configure
a Kubernetes Service Account to impersonate a GCP Service Account,
two steps are required:

1. **Allow the Kubernetes Service Account to impersonate the GCP Service Account.**
   This is done by granting the
   [Workload Identity User (`roles/iam.workloadIdentityUser`)](https://cloud.google.com/iam/docs/roles-permissions/iam#iam.workloadIdentityUser)
   role to the Kubernetes Service Account on the GCP Service Account. The IAM Principals
   required for this are the same described [here](#to-kubernetes-service-accounts).

To perform this step using Config Connector, you can use one of the IAM custom resources
mentioned [here](#via-config-connector-iam-custom-resources) with the following kind:

- [`IAMServiceAccount`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iamserviceaccount)

To perform this step using Terraform/OpenTofu, you can use one of the IAM resources mentioned
[here](#via-terraformopentofu-iam-resources) with the following resource type:

- [`service_account`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_iam)

To perform this step using the `gcloud` CLI, you can use one of the IAM commands mentioned
[here](#via-the-gcloud-cli) with the following command:

- [`iam service-accounts`](https://cloud.google.com/sdk/gcloud/reference/iam/service-accounts)

2. **Annotate the Kubernetes Service Account with the GCP Service Account email.**
   This is done by adding the annotation
   `iam.gke.io/gcp-service-account: SA_NAME@PROJECT_ID.iam.gserviceaccount.com`
   to the Kubernetes Service Account:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: KSA_NAME
  namespace: NAMESPACE
  annotations:
    iam.gke.io/gcp-service-account: SA_NAME@PROJECT_ID.iam.gserviceaccount.com
```

Configuring Flux to use a Kubernetes Service Account to authenticate with GCP,
regardless if it's configured to impersonate a GCP Service Account or not, can
be done either [at the object level](#at-the-object-level) or
[at the controller level](#at-the-controller-level).

### With GCP Service Account Keys

All GCP integrations except for GAR support configuring
authentication through a GCP Service Account Key.

GCP Service Accounts support static
[private keys](https://cloud.google.com/iam/docs/service-account-creds#user-managed-keys)
that can be used to generate temporary access tokens for authenticating with GCP services.
Such a key is exported as a JSON document containing the key itself and other metadata.

The best way to create a GCP Service Account Key is using the following Config Connector
custom resource:

- [`IAMServiceAccountKey`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iamserviceaccountkey)

This custom resource will automatically create a Kubernetes Secret inside the cluster
containing the GCP Service Account Key in the JSON format.

To create the key using Terraform/OpenTofu, you can use the following resource:

- [`google_service_account_key`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_key)

To create the key using the `gcloud` CLI, you can use the following command:

- [`iam service-accounts keys create`](https://cloud.google.com/sdk/gcloud/reference/iam/service-accounts/keys/create)

Configuring Flux to use a GCP Service Account Key can be done either
[at the object level](#at-the-object-level) or
[at the controller level](#at-the-controller-level).

### At the object level

All the Flux APIs support configuring authentication at the object level.
This allows users to adhere to the
[Least Privilege Principle](https://en.wikipedia.org/wiki/Principle_of_least_privilege),
as each Flux resource can be configured with its own identity and therefore its own
permissions. This is useful for multi-tenancy scenarios, where different
teams can use the same cluster but need to be isolated from each other
inside their own namespaces.

#### For Workload Identity Federation

Before following the steps below, make sure to complete the cluster setup
described [here](#supported-clusters), and to configure the Kubernetes
Service Account as described [here](#supported-identity-types).

For configuring authentication through a Kubernetes Service Account
at the object level, regardless if the Kubernetes Service Account is
configured to impersonate a GCP Service Account or not, the following
steps are required:

1. Enable the feature gate `ObjectLevelWorkloadIdentity` in the target Flux controller Deployment
   [during bootstrap](/flux/installation/configuration/bootstrap-customization.md):

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - target:
      kind: Deployment
      name: (some-controller)
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --feature-gates=ObjectLevelWorkloadIdentity=true
```

2. Set the `.spec.provider` field to `gcp` in the Flux resource.
   For SOPS decryption with the `Kustomization` API, this field is not
   required/does not exist, SOPS detects the provider from the metadata
   in the SOPS-encrypted Secret. For remote cluster access with the
   `Kustomization` and `HelmRelease` APIs the field is `.data.provider`
   inside the referenced `ConfigMap` from `.spec.kubeConfig.configMapRef`.
3. Use the `.spec.serviceAccountName` field to specify the name of the
   Kubernetes Service Account in the same namespace as the Flux resource.
   For SOPS decryption with the `Kustomization` API, the field is
   `.spec.decryption.serviceAccountName`. For remote cluster access with
   the `Kustomization` and `HelmRelease` APIs the field is
   `.data.serviceAccountName` inside the referenced `ConfigMap` from
   `.spec.kubeConfig.configMapRef`.
4. **Only if the cluster is not GKE**, annotate the Kubernetes Service Account
   with the fully qualified name of the Workload Identity Provider:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: KSA_NAME
  namespace: NAMESPACE
  annotations:
    iam.gke.io/gcp-service-account: SA_NAME@PROJECT_ID.iam.gserviceaccount.com # GCP Service Account impersonation is optional
    gcp.auth.fluxcd.io/workload-identity-provider: projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID
```

> **Note**: The `iam.gke.io/gcp-service-account` annotation is defined by GKE,
> but Flux also uses it to identify the GCP Service Account to impersonate in
> non-GKE clusters. This is for providing users with a seamless experience.

#### For GCP Service Account Keys

All GCP integrations except for GAR and GKE support configuring
authentication through a GCP Service Account Key at the object
level.

For configuring authentication through a GCP Service Account Key, the
`.spec.secretRef.name` field must be set to the name of the Kubernetes
Secret in the same namespace as the Flux resource containing the GCP
Service Account Key. In the case of the `Kustomization` API, the field
is `.spec.decryption.secretRef.name`.

The provider field and the key inside the `.data` field of the Secret
depend on the specific Flux API:

- For the `Bucket` API the `.spec.provider` field must be set to `gcp`,
  and the key inside the `.data` field of the Secret must be `serviceaccount`.
- For the `Provider` API, the `.spec.type` field must be set to `googlepubsub`
  and the key inside the `.data` field of the Secret must be `token`.
- For SOPS decryption with the `Kustomization` API, there's no provider field as
  SOPS detects the provider from the metadata in the SOPS-encrypted Secret. The
  key inside the `.data` field of the Secret must be `sops.gcp-kms`.

### At the controller level

All the Flux APIs support configuring authentication at the controller level.
This is more appropriate for single-tenant scenarios, where all the Flux resources
inside the cluster belong to the same team and hence can share the same identity
and permissions.

At the controller level, regardless if authenticating with Workload Identity Federation
or GCP Service Account Keys, all Flux resources must have the provider field set to `gcp`
according to the rules below.

For all Flux resource kinds except for `Kustomization` and `HelmRelease`, set
the `.spec.provider` field to `gcp` and leave `.spec.serviceAccountName` unset.

For SOPS decryption with the `Kustomization` API, leave the
`.spec.decryption.serviceAccountName` field unset. There's
no provider field for SOPS decryption.

For remote cluster access with the `Kustomization` and `HelmRelease` APIs,
set the `.data.provider` field of the `ConfigMap` referenced by the
`.spec.kubeConfig.configMapRef` field to `gcp` and leave the
`.data.serviceAccountName` field unset.

The controller-level configuration is described in the following sections.

#### For Workload Identity Federation

Before following the steps below, make sure to complete the cluster setup
described [here](#supported-clusters), and to configure the Kubernetes
Service Account as described [here](#supported-identity-types).

If the cluster is GKE, the Kubernetes Service Account of the controller can optionally
be configured to impersonate a GCP Service Account. This is done by adding the
`iam.gke.io/gcp-service-account` annotation to the controller Service Account
[during bootstrap](/flux/installation/configuration/bootstrap-customization.md):

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - target:
      kind: ServiceAccount
      name: "(some-controller)"
    patch: |
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: controller
        annotations:
          iam.gke.io/gcp-service-account: SA_NAME@PROJECT_ID.iam.gserviceaccount.com # GCP Service Account impersonation is optional
```

If the configuration above is done after bootstrap, restart (delete) the controller
for the binding to take effect.

> **Hint**: As discussed in the [Workload Identity Federation](#with-workload-identity-federation)
> section, impersonating a GCP Service Account is entirely optional. If not configured, the controller
> Kubernetes Service Account will be used for authentication, in which case the roles must be granted
> directly to it according to what is described in [this](#to-kubernetes-service-accounts) section.

If the cluster *is not* GKE, the controller Deployment must be patched
[during bootstrap](/flux/installation/configuration/bootstrap-customization.md) according to these
[docs](https://cloud.google.com/iam/docs/workload-identity-federation-with-kubernetes#deploy):

- A projected volume must be mounted in the controller Deployment with a Kubernetes
  Service Account token whose audience is set to the Workload Identity Provider URL.
- A ConfigMap volume must be mounted in the controller Deployment with the JSON
  configuration below.
- The environment variable `GOOGLE_APPLICATION_CREDENTIALS` must be set to the path
  of the mounted JSON configuration file.

The controller patch should look like this:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - target:
      kind: Deployment
      name: "(some-controller)"
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: GOOGLE_APPLICATION_CREDENTIALS
          value: /etc/workload-identity/credential-configuration.json
      - op: add
        path: /spec/template/spec/volumes/-
        value:
          name: gcp-token
          projected:
            sources:
            - serviceAccountToken:
                audience: https://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID
                expirationSeconds: 3600
                path: gcp-token
      - op: add
        path: /spec/template/spec/volumes/-
        value:
          name: workload-identity-credential-configuration
          configMap:
            name: some-controller-workload-identity-federation
      - op: add
        path: /spec/template/spec/containers/0/volumeMounts/-
        value:
          name: gcp-token
          mountPath: /var/run/service-account
          readOnly: true
      - op: add
        path: /spec/template/spec/containers/0/volumeMounts/-
        value:
          name: workload-identity-credential-configuration
          mountPath: /etc/workload-identity
          readOnly: true
```

For direct access using the roles granted to the controller Kubernetes Service account,
the ConfigMap containing the JSON configuration should look like this (it should contain
the `token_info_url` field set to `https://sts.googleapis.com/v1/introspect`):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: some-controller-workload-identity-federation
  namespace: flux-system
data:
  credential-configuration.json: |
    {
      "universe_domain": "googleapis.com",
      "type": "external_account",
      "audience": "//iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID",
      "subject_token_type": "urn:ietf:params:oauth:token-type:jwt",
      "token_url": "https://sts.googleapis.com/v1/token",
      "token_info_url": "https://sts.googleapis.com/v1/introspect",
      "credential_source": {
        "file": "/var/run/service-account/gcp-token",
        "format": {
          "type": "text"
        }
      }
    }
```

For impersonating a GCP Service Account using the controller Kubernetes Service Account,
the ConfigMap containing the JSON configuration should look like this (it should contain
the `service_account_impersonation_url` field instead of the `token_info_url` field):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: some-controller-workload-identity-federation
  namespace: flux-system
data:
  credential-configuration.json: |
    {
      "universe_domain": "googleapis.com",
      "type": "external_account",
      "audience": "//iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID",
      "subject_token_type": "urn:ietf:params:oauth:token-type:jwt",
      "token_url": "https://sts.googleapis.com/v1/token",
      "service_account_impersonation_url": "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/SA_NAME@PROJECT_ID.iam.gserviceaccount.com:generateAccessToken",
      "credential_source": {
        "file": "/var/run/service-account/gcp-token",
        "format": {
          "type": "text"
        }
      }
    }
```

#### For GCP Service Account Keys

Mount the Kubernetes Secret containing the GCP Service Account Key inside
the controller Deployment as a volume, and set the environment variable
`GOOGLE_APPLICATION_CREDENTIALS` to the path of the mounted JSON file
[during bootstrap](/flux/installation/configuration/bootstrap-customization.md):

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - target:
      kind: Deployment
      name: "(some-controller)"
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: GOOGLE_APPLICATION_CREDENTIALS
          value: /etc/gcp-service-account/key.json
      - op: add
        path: /spec/template/spec/volumes/-
        value:
          name: gcp-service-account
          secret:
            secretName: some-controller-gcp-service-account
      - op: add
        path: /spec/template/spec/containers/0/volumeMounts/-
        value:
          name: gcp-service-account
          mountPath: /etc/gcp-service-account
          readOnly: true
```

The Secret should look like this:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: some-controller-gcp-service-account
  namespace: flux-system
type: Opaque
stringData:
  key.json: |
    JSON_GCP_SERVICE_ACCOUNT_KEY
```

### At the node level

Only for the GAR integrations Flux supports authentication
at the node level for GKE. This is because users often already have to configure
authentication at the node level for GKE to be able to pull container images from
GAR in order to start pods. By supporting this authentication method Flux allows
users to configure GAR authentication in a single way.
See [docs](https://cloud.google.com/artifact-registry/docs/integrate-gke).

> :warning: Node level authentication may work for other integrations as well,
> but Flux only has continuous integration tests for the GAR integration in
> order to support the specific use case described above.

For node-level authentication to work, the `.spec.provider` field of the Flux
resources must be set to `gcp`.
