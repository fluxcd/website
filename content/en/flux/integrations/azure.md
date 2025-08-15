---
title: "Microsoft Azure"
linkTitle: "Microsoft Azure"
description: "How to configure access for the Flux integrations with Microsoft Azure."
weight: 50
---

The Flux APIs integrate with the following Microsoft Azure services:

- The source-controller integrates the [OCIRepository](/flux/components/source/ocirepositories/) API with
  [Azure Container Registry (ACR)](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro)
  for pulling OCI artifacts into the cluster.
- The image-reflector-controller integrates the [ImageRepository](/flux/components/image/imagerepositories/) and
  [ImagePolicy](/flux/components/image/imagepolicies/) APIs with ACR for scanning tags and digests of OCI artifacts
  and reflecting them into the cluster.
- The source-controller integrates the [GitRepository](/flux/components/source/gitrepositories/) API with
  [Azure DevOps (ADO)](https://learn.microsoft.com/en-us/azure/devops/user-guide/services)
  for pulling manifests from Git repositories and packaging them as artifacts inside the cluster.
- The image-automation-controller integrates the [ImageUpdateAutomation](/flux/components/image/imageupdateautomations/)
  API with ADO for automating image updates in Git repositories.
- The notification-controller integrates the [Provider](/flux/components/notification/providers/) API with ADO
  for updating commit statuses in Git repositories upon events related to Flux resources.
- The source-controller integrates the [Bucket](/flux/components/source/buckets/) API with
  [Azure Blob Storage (ABS)](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction)
  for pulling manifests from containers and packaging them as artifacts inside the cluster.
- The kustomize-controller integrates the [Kustomization](/flux/components/kustomize/kustomizations/) API with
  [Azure Key Vault (AKV)](https://learn.microsoft.com/en-us/azure/key-vault/general/overview)
  for decrypting SOPS-encrypted secrets when applying manifests in the cluster.
- The kustomize-controller integrates the Kustomization API with
  [Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/what-is-aks)
  for applying manifests in remote AKS clusters.
- The helm-controller integrates the [HelmRelease](/flux/components/helm/helmreleases/) API with
  AKS for applying Helm charts in remote AKS clusters.
- The notification-controller integrates the Provider API with
  [Azure Event Hubs (AEH)](https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-about)
  for sending notifications about Flux resources outside the cluster.

The next sections briefly describe
[Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/fundamentals/whatis),
formerly known as *Azure Active Directory (AAD)*, and
[Azure RBAC](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview),
Azure's identity and access management systems,
and how they can be used to grant Flux access to resources offered by the services above. Bear in
mind that Microsoft Entra ID and Azure RBAC have more features than the ones described here.
We describe only the features that are relevant for the Flux integrations.

> **Note**: Flux also supports Microsoft Teams webhooks, but Microsoft Teams webhooks do
> not support Microsoft Entra ID. For more information about the notification-controller
> integration with Microsoft Teams, see the [Provider](/flux/components/notification/providers/) API docs.

## Identity

For all the integrations with Azure, Microsoft Entra ID will
authenticate two types of identities for Flux:

- [User-Assigned Managed Identities](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-manage-user-assigned-managed-identities)
- [Applications](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal)

For both types a
[Service Principal](https://learn.microsoft.com/en-us/entra/identity-platform/app-objects-and-service-principals#service-principal-object)
can be enabled, with each identity having its own Service Principal. The
Service Principal is the entity of an identity that is used to integrate
with other Azure systems, such as Azure RBAC and ADO.

Also, each identity type has its own methods of authentication. In particular,
Managed Identities support secret-less authentication, while Applications support
secret-based authentication. The former is more secure.

For further understanding how to configure authentication for both types of
identities, refer to the [Authentication](#authentication) section.

## Access Management

Azure Role-Based Access Control (RBAC) is the system that Azure employs to
manage access for most of its resources. Some services, such as
[ADO](https://learn.microsoft.com/en-us/azure/devops/organizations/security/permissions),
do not use Azure RBAC and instead have their own access control system.

Identities in Azure need *permissions* to access resources from Azure services.
Permissions cannot be granted directly to identities. Instead, Azure RBAC uses
[roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-definitions)
to group permissions, and only roles can be granted to identities. Each role has a
display name and a globally unique ID. For example, the role `Storage Blob Data Reader`,
whose ID is `/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1`,
has the following definition:

```json
{
  "assignableScopes": [
    "/"
  ],
  "description": "Allows for read access to Azure Storage blob containers and data",
  "id": "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1",
  "name": "2a2b9908-6ea1-4ae2-8e65-a410df84e7d1",
  "permissions": [
    {
      "actions": [
        "Microsoft.Storage/storageAccounts/blobServices/containers/read",
        "Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action"
      ],
      "notActions": [],
      "dataActions": [
        "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"
      ],
      "notDataActions": []
    }
  ],
  "roleName": "Storage Blob Data Reader",
  "roleType": "BuiltInRole",
  "type": "Microsoft.Authorization/roleDefinitions"
}
```

The structure of permissions is usually `Microsoft.<service>/<resource type>/<action>`
and they are grouped into two categories:
- *Data actions*: These actions are related to data operations, such as reading or writing data.
- *Non-data actions*: These actions are related to management operations, such as creating or deleting resources.

Azure has a large number of
[predefined roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles),
but users can also create
[custom roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/custom-roles)
inside their Azure subscriptions.

For an identity to be allowed to perform an action on a resource, the identity
needs to be granted, *on a scope covering that resource*, a role that contains
the permission required for that action. The role needs to be granted directly
on the resource scope, or on the scope of a parent resource in the
[resource hierarchy](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-setup-guide/organize-resources#management-levels-and-hierarchy):

- *Resource*
- *Resource Group* (set of resources)
- *Subscription* (set of resource groups)
- *Management Group* (set of subscriptions)

If the role is granted on a parent resource, the relationship will be inherited
by all the descendants. For example, if a role is granted on a subscription, all
the resource groups and resources inside that subscription will inherit the grant.

> **Reminder**: The grant relationship has *three* involved entities:
> - The identity that will use the permissions to perform actions.
> - The scope covering the resource that will be the target of the actions.
> - The role containing the permissions required for the actions.

### Granting permissions

Azure RBAC grants roles to Microsoft Entra identities through the Service Principal
of the identity. The *principal ID* of an identity can be looked up through the
*client ID* (also known as *application ID*) of the identity.

To find a principal ID using Terraform/OpenTofu, use the client ID in the following data source
(look for the `object_id` attribute):

- [`azuread_service_principal`](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal)

To find a principal ID using the `az` CLI, use the client ID in the following command:

- [`az ad sp show --id <client-id> --query id -o tsv`](https://learn.microsoft.com/en-us/cli/azure/ad/sp#az-ad-sp-show)

#### Via Azure Service Operator custom resources

To use [Azure Service Operator (ASO)](https://azure.github.io/azure-service-operator/) for
granting roles you can use the following custom resource:

- [`RoleAssignment`](https://azure.github.io/azure-service-operator/reference/authorization/)

> **Note**: ASO is the most GitOps-friendly way of managing Azure
> resources. With it you can even use Flux itself to deploy and continuously reconcile
> your Azure custom resources (the Kubernetes ones), and ASO itself will
> [continuously reconcile](https://azure.github.io/azure-service-operator/guide/aso-controller-settings-options/#azure_sync_period)
> the actual Azure resources.

#### Via Terraform/OpenTofu resources

To use Terraform/OpenTofu for granting roles you can use the following resource:

- [`azurerm_role_assignment`](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)

> **Note**: Terraform/OpenTofu is a great declarative way of managing Azure resources,
> but it's not as GitOps-friendly as ASO, as these tools do not prescribe
> continuous reconciliation of the resources. There are alternatives to achieve that,
> but they are not a core part of the tools.

#### Via the `az` CLI

To use the `az` CLI for granting roles you can use the following command:

- [`az role assignment create`](https://learn.microsoft.com/en-us/cli/azure/role/assignment#az-role-assignment-create)

> **Note**: The `az` CLI is a great tool for experimenting with Azure resources and
> their integrations with Flux, but it's not a GitOps-friendly way of managing Azure
> resources. If you need continuous reconciliation of the resources, prefer using
> ASO or Terraform/OpenTofu.

## Authorization

In this section we describe the recommended roles and permissions for
enabling the Flux integrations with Azure services.

### For Azure Container Registry

The `OCIRepository`, `ImageRepository` and `ImagePolicy` Flux APIs are integrated with
ACR. The `OCIRepository` API can be used to pull OCI artifacts from ACR repositories
into the cluster, while the `ImageRepository` and `ImagePolicy` APIs
can be used to reflect tags and digests of such artifacts also inside the cluster.

The recommended role containing the required permissions for the `OCIRepository`,
`ImageRepository` and `ImagePolicy` APIs is:

- [AcrPull (`/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d`)](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/containers#acrpull)

The scopes on which the `AcrPull` role can be granted are:

- Registry: `/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME/providers/Microsoft.ContainerRegistry/registries/REGISTRY_NAME`
- Resource Group: `/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME`
- Subscription: `/subscriptions/SUBSCRIPTION_ID`
- Management Group: `/providers/Microsoft.Management/managementGroups/MANAGEMENT_GROUP_NAME`

### For Azure DevOps

The `GitRepository`, `ImageUpdateAutomation` and `Provider` Flux APIs are integrated with
ADO. The `GitRepository` API can be used to pull manifests from ADO Git repositories
and package them as artifacts inside the cluster, the `ImageUpdateAutomation` API
can be used to automate image updates in ADO Git repositories, and the `Provider` API
can be used to update commit statuses in ADO Git repositories upon events related to
Flux resources.

While ADO integrates with Microsoft Entra ID Service Principals, it does not
integrate with Azure RBAC. As mentioned before, ADO has its own access control
system.

The Service Principal must be onboarded into the ADO organization and
added to a group. For the `GitRepository` API, the `Readers` group is sufficient,
while for the `ImageUpdateAutomation` and `Provider` APIs the `Contributors` group
is required for pushing commits to the repository and updating commit statuses,
respectively.

ASO does not support managing ADO resources (see
[issue](https://github.com/Azure/azure-service-operator/issues/3209)).

#### Via Terraform/OpenTofu resources

To grant access to Service Principals using Terraform/OpenTofu, first you need to
configure the ADO provider with the ADO organization and project:

- [`azuredevops`](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs#argument-reference)

Then you can use the following resources:

- [`azuredevops_service_principal_entitlement`](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/service_principal_entitlement):
  This resource onboards a Service Principal into an ADO organization.
- [`azuredevops_group_membership`](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/group_membership):
  This resource adds the Service Principal to an ADO group.

Use the `descriptor` attribute of the `azuredevops_service_principal_entitlement`
in the `members` field of the `azuredevops_group_membership` resource.

Use the
[`azuredevops_group`](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/data-sources/group)
data source to find the ID of the desired group, and use it in the
`group` field of the `azuredevops_group_membership` resource.

#### Via the `az` CLI

To grant access to Service Principals using the `az` CLI, you can use the following commands:

1. Login to ADO:
   [`az devops login`](https://learn.microsoft.com/en-us/cli/azure/devops#az-devops-login)
2. Configure the ADO organization and project:
   [`az devops configure`](https://learn.microsoft.com/en-us/cli/azure/devops#az-devops-configure)
3. Onboard the Service Principal into the ADO organization. This doesn't have a dedicated command yet,
   so use [`az rest`](https://learn.microsoft.com/en-us/cli/azure/reference-index#az-rest) to call the REST API for
   [`Adding Service Principal Entitlements`](https://learn.microsoft.com/en-us/rest/api/azure/devops/memberentitlementmanagement/service-principal-entitlements/add).
4. Find the *member ID* of the Service Principal in the organization using `az rest` with the REST API for
   [`Querying Subjects`](https://learn.microsoft.com/en-us/rest/api/azure/devops/graph/subject-query/query),
   the `query` field of the request body should be set to the principal ID of the Service Principal.
   The response should be a list of `GraphSubject`, the member ID will be the `descriptor` field.
5. List the groups in the organization to find the ID of the desired group:
   [`az devops security group list`](https://learn.microsoft.com/en-us/cli/azure/devops/security/group#az-devops-security-group-list)
6. Add the Service Principal to the group:
   [`az devops security group membership add`](https://learn.microsoft.com/en-us/cli/azure/devops/security/group/membership#az-devops-security-group-membership-add)

### For Azure Blob Storage

The `Bucket` Flux API is integrated with ABS. The `Bucket` API can be used
to pull manifests from ABS containers and package them as artifacts inside the cluster.

The recommended role containing the required permissions for the `Bucket` API is:

- [Storage Blob Data Reader (`/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1`)](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-reader)

The scopes on which the `Storage Blob Data Reader` role can be granted are:

- Container: `/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/STORAGE_ACCOUNT_NAME/blobServices/default/containers/CONTAINER_NAME`
- Storage Account: `/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/STORAGE_ACCOUNT_NAME`
- Resource Group: `/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME`
- Subscription: `/subscriptions/SUBSCRIPTION_ID`
- Management Group: `/providers/Microsoft.Management/managementGroups/MANAGEMENT_GROUP_NAME`

### For Azure Key Vault

The `Kustomization` Flux API is integrated with AKV.
The `Kustomization` API is used to apply manifests in the cluster, and it can use AKV to
decrypt SOPS-encrypted secrets before applying them.

The recommended role containing the required permissions for the `Kustomization` API is:

- [Key Vault Crypto User (`/providers/Microsoft.Authorization/roleDefinitions/12338af0-0e69-4776-bea7-57ae8d297424`)](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/security#key-vault-crypto-user)

The scopes on which the `Key Vault Crypto User` role can be granted are:

- Vault: `/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME/providers/Microsoft.KeyVault/vaults/VAULT_NAME`
- Resource Group: `/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME`
- Subscription: `/subscriptions/SUBSCRIPTION_ID`
- Management Group: `/providers/Microsoft.Management/managementGroups/MANAGEMENT_GROUP_NAME`

### For Azure Kubernetes Service

The `Kustomization` and `HelmRelease` Flux APIs can use Microsoft Entra identities for applying
and managing resources in remote AKS clusters. The AKS cluster must be
[integrated with Microsoft Entra ID](https://learn.microsoft.com/en-us/azure/aks/enable-authentication-microsoft-entra-id)
for this feature work.

> **Note**: If you have a reason not to enable the Microsoft Entra ID integration in
> your cluster, you can still fetch the static `cluster-admin` kubeconfig from Azure
> and use it with the `.spec.kubeConfig.secretRef` field of the
> [`Kustomization`](/flux/components/kustomize/kustomizations/#kubeconfig-remote-clusters) and
> [`HelmRelease`](/flux/components/helm/helmreleases/#kubeconfig-remote-clusters) APIs.

Two kinds of access must be configured for the Microsoft Entra identity:

- The Microsoft Entra identity must have permission to call the `Get` and `ListClusterUserCredentials`
  AKS APIs for the target remote cluster. The Flux controllers need to call these APIs for retrieving
  details required for connecting to the remote cluster, like the cluster's API server endpoint and
  certificate authority data. This is done by granting an Azure RBAC role to the Microsoft Entra
  identity that allows these actions on the target remote cluster.
- The Microsoft Entra identity must have permissions inside the remote cluster to apply and manage
  the target resources. There are two ways of granting these permissions: via Kubernetes RBAC, or
  via Azure RBAC. The former means simply referencing the *principal ID* of the Microsoft Entra identity
  in `RoleBinding` or `ClusterRoleBinding` objects inside the remote cluster as the Kubernetes username.
  The latter means granting [Azure RBAC roles](https://learn.microsoft.com/en-us/azure/aks/manage-azure-rbac)
  that grant Kubernetes permissions to the Microsoft Entra identity on the target remote cluster.
  The resulting set of permissions granted to the Microsoft Entra identity will be the union of
  the permissions granted via Kubernetes RBAC with the permissions granted via Azure RBAC.

#### Permissions for the AKS APIs

The recommended role containing the required permissions for calling the `Get` and
`ListClusterUserCredentials` AKS APIs is:

- [Azure Kubernetes Service Cluster User Role (`/providers/Microsoft.Authorization/roleDefinitions/4abbcc35-e782-43d8-92c5-2d3f1bd2253f`)](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/containers#azure-kubernetes-service-cluster-user-role)

The scopes on which the `Azure Kubernetes Service Cluster User Role` role can be granted are:

- Cluster: `/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME/providers/Microsoft.ContainerService/managedClusters/CLUSTER_NAME`
- Resource Group: `/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME`
- Subscription: `/subscriptions/SUBSCRIPTION_ID`
- Management Group: `/providers/Microsoft.Management/managementGroups/MANAGEMENT_GROUP_NAME`

#### Permissions inside the remote cluster

For granting Kubernetes RBAC to the *principal ID* of a Microsoft Entra identity,
simply create the corresponding `RoleBinding` or `ClusterRoleBinding` objects
inside the remote cluster using the principal ID as the Kubernetes username.

For granting permissions through Azure RBAC roles, you can grant either
[built-in roles](https://learn.microsoft.com/en-us/azure/aks/manage-azure-rbac#aks-built-in-roles) or
[custom roles](https://learn.microsoft.com/en-us/azure/aks/manage-azure-rbac#create-custom-roles-definitions)
to Microsoft Entra identity on the following scopes:

- Namespace: `/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME/providers/Microsoft.ContainerService/managedClusters/CLUSTER_NAME/namespaces/NAMESPACE_NAME`
- Cluster: `/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME/providers/Microsoft.ContainerService/managedClusters/CLUSTER_NAME`
- Resource Group: `/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME`
- Subscription: `/subscriptions/SUBSCRIPTION_ID`
- Management Group: `/providers/Microsoft.Management/managementGroups/MANAGEMENT_GROUP_NAME`

Azure RBAC
[must be enabled](https://learn.microsoft.com/en-us/azure/aks/manage-azure-rbac#create-a-new-aks-cluster-with-managed-microsoft-entra-integration-and-azure-rbac-for-kubernetes-authorization)
for the remote AKS cluster.

### For Azure Event Hubs

The `Provider` Flux API is integrated with AEH. The `Provider` API can be used
to send notifications about Flux resources to Event Hubs.

The recommended role containing the required permissions for the `Provider` API is:

- [Azure Event Hubs Data Sender (`/providers/Microsoft.Authorization/roleDefinitions/2b629674-e913-4c01-ae53-ef4638d8f975`)](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/analytics#azure-event-hubs-data-sender)

The scopes on which the `Azure Event Hubs Data Sender` role can be granted are:

- Event Hub: `/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME/providers/Microsoft.EventHub/namespaces/NAMESPACE_NAME/eventhubs/EVENTHUB_NAME`
- Namespace: `/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME/providers/Microsoft.EventHub/namespaces/NAMESPACE_NAME`
- Resource Group: `/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME`
- Subscription: `/subscriptions/SUBSCRIPTION_ID`
- Management Group: `/providers/Microsoft.Management/managementGroups/MANAGEMENT_GROUP_NAME`

## Authentication

As mentioned in the [Identity](#identity) section, Azure supports two types of
identities for Flux: Managed Identities and Applications.
This section describes how to authenticate each type of identity.
Managed Identities are the recommended way of authenticating to Azure services, as they
support secret-less authentication. Applications are not recommended, as they
require secret-based authentication, which is less secure.

> **Recommendation**: Always prefer secret-less over secret-based authentication
> if the alternative is available. Secrets can be stolen to abuse the permissions
> granted to the identities they represent, and for public clouds like Azure this can
> be done by simply having Internet access. This requires secrets to be regularly
> rotated and more security controls to be put in place, like audit logs, secret
> management tools, etc. Secret-less authentication does not have this problem, as
> the identity is authenticated using a token that is not stored anywhere and is
> only valid for a short period of time, usually one hour. It's much harder to
> steal an identity this way.

### With Workload Identity Federation

[Workload Identity Federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation)
is an Azure feature that allows external identities to authenticate with Azure services
without the need for a per-identity static credential. This is done by exchanging
a short-lived token issued by the external identity provider (in this case,
Kubernetes) for a short-lived Azure Access Token. This access token is then used
to authenticate with Azure services. This process is more broadly known as
*OIDC federation* and is supported only for Managed Identities.

#### Supported clusters

Azure supports Workload Identity Federation for both AKS and non-AKS clusters.

In AKS clusters you need to enable the options
[OIDC Issuer and Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster#create-an-aks-cluster).

For both AKS and non-AKS clusters you need to know the
[Issuer URL](cross-cloud.md#source-cluster-setup) of the cluster,
which is an input required for creating *Federated Credentials*
(see [below](#supported-identity-types)).

#### Supported identity types

As mentioned before, the only identity type supported by Workload Identity Federation is Managed Identities.

Flux acquires the roles granted to a Managed Identity by using a Kubernetes
Service Account to *impersonate* this Managed Identity.
To configure a Kubernetes Service Account to impersonate a Managed Identity, two steps
are required:

1. **Allow the Kubernetes Service Account to impersonate the Managed Identity.**
   This is done by creating a
   [Federated Credential](https://learn.microsoft.com/en-us/graph/api/resources/federatedidentitycredentials-overview)
   that ties together the Kubernetes Service Account and the Managed Identity.

The inputs identifying the Managed Identity for creating the Federated Credential are:

- The Resource Group.
- The Name of the Managed Identity inside the Resource Group.

The inputs identifying the Kubernetes Service Account for creating the Federated Credential are:

- The [Issuer URL](cross-cloud.md#source-cluster-setup) of the cluster.
- The Subject string that Kubernetes uses to identify the Service Account, which is
  `system:serviceaccount:NAMESPACE:KSA_NAME`.

Additionally, the Federated Credential needs:

- A name for itself.
- The *Audience* to be set to `api://AzureADTokenExchange`.

To create a Federated Credential using ASO, you can use the following custom resource:

- [`FederatedIdentityCredential`](https://azure.github.io/azure-service-operator/reference/managedidentity/)

To create a Federated Credential using Terraform/OpenTofu, you can use the following resource:

- [`azurerm_federated_identity_credential`](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential)

to create a Federated Credential using the `az` CLI, you can use the following command:

- [`az identity federated-credential create`](https://learn.microsoft.com/en-us/cli/azure/identity/federated-credential#az-identity-federated-credential-create)

2. **Annotate the Kubernetes Service Account with the Managed Identity Client ID and Tenant ID.**
   This is done by adding the annotations
   `azure.workload.identity/client-id: CLIENT_ID` and
   `azure.workload.identity/tenant-id: TENANT_ID`
   to the Kubernetes Service Account:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: KSA_NAME
  namespace: NAMESPACE
  annotations:
    azure.workload.identity/client-id: CLIENT_ID
    azure.workload.identity/tenant-id: TENANT_ID
```

Configuring Flux to use a Kubernetes Service Account to authenticate with
Azure can be done either [at the object level](#at-the-object-level) or
[at the controller level](#at-the-controller-level).

### With Application Certificates

All Azure integrations except for ACR support configuring
authentication through an Application Certificate.

Applications support static
[certificates](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal#set-up-authentication)
that can be used to generate temporary access tokens for authenticating
with Azure services.

ASO does not support creating Application Certificates (see
[issue](https://github.com/Azure/azure-service-operator/issues/2474)).

To create an Application Certificate using Terraform/OpenTofu, you can use the following resource:

- [`azuread_service_principal_certificate`](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal_certificate)

To create or reset an Application Certificate using the `az` CLI, you can use the following command:

- [`az ad sp credential reset --create-cert`](https://learn.microsoft.com/en-us/cli/azure/ad/sp/credential#az-ad-sp-credential-reset)

Configuring Flux to use an Application Certificate can be done either
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

> :warning: **Attention**: *Only for AKS clusters targeting Azure resources*
> object-level workload identity is currently unstable. In its current state
> the feature may stop working without notice depending on actions taken by
> Azure to meet AKS customers' demands. For continued support the feature
> may need to evolve in a way that additional configuration steps will be
> required for it to continue working in future Flux releases.
> See [this](https://github.com/fluxcd/flux2/issues/5359) issue for more
> information.

For configuring authentication through a Kubernetes Service Account
at the object level the following steps are required:

1. Enable the feature gate `ObjectLevelWorkloadIdentity` in the target Flux controller Deployment
   [during bootstrap](/flux/installation/configuration/boostrap-customization.md):

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

2. Set the `.spec.provider` field to `azure` in the Flux resource.
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

> **Note**: The `azure.workload.identity/client-id` and `azure.workload.identity/tenant-id`
> annotations are defined by AKS, but Flux also uses them to identify the Managed Identity
> to impersonate in non-AKS clusters. This is for providing users with a seamless experience.

At the moment, the ADO integrations with the `GitRepository`, `ImageUpdateAutomation` and
`Provider` APIs and the ABS integration with the `Bucket` API **do not support** configuring
authentication through Workload Identity Federation at the object level.
Support for these integrations will be introduced in Flux v2.7.

#### For Application Certificates

Only the ABS and AKV integrations support configuring
authentication through an Application Certificate at
the object level.

For configuring authentication through an Application Certificate for
the `Bucket` API:

- Set the `.spec.provider` field to `azure`.
- Set the `.spec.secretRef.name` field to the name of the Kubernetes
  Secret in the same namespace as the `Bucket` resource.

The Secret must looks like this:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: SECRET_NAME
  namespace: NAMESPACE
type: Opaque
stringData:
  tenantId: <tenant ID>
  clientId: <client ID>
  clientCertificate: <certificate and private key>
  # Plus optionally
  clientCertificatePassword: <password if the private key is encrypted>
  clientCertificateSendChain: "true" # this boolean value must be quoted
```

For SOPS decryption with the `Kustomization` API:

- Set the `.spec.decryption.secretRef.name` field to the name of the Kubernetes
  Secret in the same namespace as the `Kustomization` resource.

The Secret must look like this:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: SECRET_NAME
  namespace: NAMESPACE
type: Opaque
stringData:
  sops.azure-kv: |
    tenantId: <tenant ID>
    clientId: <client ID>
    clientCertificate: <certificate and private key>
    # Plus optionally
    clientCertificatePassword: <password if the private key is encrypted>
    clientCertificateSendChain: true # this boolean value must NOT be quoted
```

### At the controller level

All the Flux APIs support configuring authentication at the controller level.
This is more appropriate for single-tenant scenarios, where all the Flux resources
inside the cluster belong to the same team and hence can share the same identity
and permissions.

At the controller level, regardless if authenticating with Workload Identity Federation
or Application Certificates, all Flux resources must have the provider field set to
`azure` according to the rules below.

For all Flux resource kinds except for `Kustomization` and `HelmRelease`, set
the `.spec.provider` field to `azure` and leave `.spec.serviceAccountName` unset.

For SOPS decryption with the `Kustomization` API, leave the
`.spec.decryption.serviceAccountName` field unset. There's
no provider field for SOPS decryption.

For remote cluster access with the `Kustomization` and `HelmRelease` APIs,
set the `.data.provider` field of the `ConfigMap` referenced by the
`.spec.kubeConfig.configMapRef` field to `azure` and leave the
`.data.serviceAccountName` field unset.

The controller-level configuration is described in the following sections.

#### For Workload Identity Federation

Before following the steps below, make sure to complete the cluster setup
described [here](#supported-clusters), and to configure the Kubernetes
Service Account as described [here](#supported-identity-types).

If the cluster is AKS, the controller Kubernetes Service Account and Deployment
must be patched
[during bootstrap](/flux/installation/configuration/boostrap-customization.md):

- The Kubernetes Service Account of the controller must be configured
  to impersonate a Managed Identity. This is done by adding the
  `azure.workload.identity/client-id` and `azure.workload.identity/tenant-id`
  annotations.
- The label `azure.workload.identity/use: "true"` must be added to the
  controller Deployment template metadata. This label is used by the AKS mutating
  webhook to automatically configure the controller pod during admission to use
  Workload Identity.

The controller patch should look like this:

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
          azure.workload.identity/client-id: CLIENT_ID
          azure.workload.identity/tenant-id: TENANT_ID
  - target:
      kind: Deployment
      name: "(some-controller)"
    patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: (some-controller)
      spec:
        template:
          metadata:
            labels:
              azure.workload.identity/use: "true"
```

If the configuration above is done after bootstrap, restart (delete) the controller
for the binding to take effect.

If the cluster *is not* AKS, the controller Deployment must be patched
[during bootstrap](/flux/installation/configuration/boostrap-customization.md):

- A projected volume must be mounted in the controller Deployment with a Kubernetes
  Service Account token whose audience is set to `api://AzureADTokenExchange`.
- The environment variables shown below must be set in the controller Deployment.

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
          name: AZURE_TENANT_ID
          value: TENANT_ID
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: AZURE_CLIENT_ID
          value: CLIENT_ID
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: AZURE_AUTHORITY_HOST
          value: https://login.microsoftonline.com/
          # or https://login.microsoftonline.us/ for US Gov
          # or https://login.chinacloudapi.cn/   for China
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: AZURE_FEDERATED_TOKEN_FILE
          value: /var/run/service-account/azure-token
      - op: add
        path: /spec/template/spec/volumes/-
        value:
          name: azure-token
          projected:
            sources:
            - serviceAccountToken:
                audience: api://AzureADTokenExchange
                expirationSeconds: 3600
                path: azure-token
      - op: add
        path: /spec/template/spec/containers/0/volumeMounts/-
        value:
          name: azure-token
          mountPath: /var/run/service-account
          readOnly: true
```

#### For Application Certificates

Mount the Kubernetes Secret containing the certificate and private key in
the controller Deployment and set the environment variables shown below
[during bootstrap](/flux/installation/configuration/boostrap-customization.md):

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
          name: AZURE_TENANT_ID
          value: TENANT_ID
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: AZURE_CLIENT_ID
          value: CLIENT_ID
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: AZURE_CLIENT_CERTIFICATE_PATH
          value: /var/run/app-cert/cert-and-key
      - op: add
        path: /spec/template/spec/volumes/-
        value:
          name: app-cert
          secret:
            secretName: SECRET_NAME
      - op: add
        path: /spec/template/spec/containers/0/volumeMounts/-
        value:
          name: app-cert
          mountPath: /var/run/app-cert/cert-and-key
          subPath: cert-and-key
          readOnly: true

      # ---------------
      # Plus optionally
      # ---------------

      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: AZURE_CLIENT_CERTIFICATE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: SECRET_NAME
              key: key-password
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: AZURE_CLIENT_SEND_CERTIFICATE_CHAIN
          value: "true" # this boolean value must be quoted
```

The Secret should look like this:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: SECRET_NAME
  namespace: flux-system
type: Opaque
stringData:
  cert-and-key: <certificate and private key>
  # Plus optionally
  key-password: <password if the private key is encrypted>
```

### At the node level

Only for the ACR integrations Flux supports authentication
at the node level for AKS. This is because users often already have to configure
authentication at the node level for AKS to be able to pull container images from
ACR in order to start pods. By supporting this authentication method Flux allows
users to configure ACR authentication in a single way. See
[docs](https://learn.microsoft.com/en-us/azure/aks/cluster-container-registry-integration).

> :warning: Node level authentication may work for other integrations as well,
> but Flux only has continuous integration tests for the ACR integration in
> order to support the specific use case described above.

For node-level authentication to work, the `.spec.provider` field of the Flux
resources must be set to `azure`.

## Supported Azure Clouds

Flux integrations described in this document are supported in Azure Public Cloud (the default environment for most Azure users), in specialized environments such as [Azure in China](https://learn.microsoft.com/en-us/azure/china/overview-operations), [Azure US Government Cloud](https://azure.microsoft.com/en-us/explore/global-infrastructure/government) and in private clouds. 

### Private Cloud Configuration

To configure Flux for a private cloud, you must set the `AZURE_ENVIRONMENT_FILEPATH` environment variable at the controller level. This variable should point to a JSON configuration file mounted into the controller pod that defines the custom Azure endpoints. An example configuration file with the list of custom endpoints supported by Flux is shared below. 

```json
{
  "resourceManagerEndpoint": "https://management.core.private/",
  "tokenAudience": "https://management.core.private/",
  "containerRegistryDNSSuffix": "azurecr.private"
}
```

