---
title: Using Flux on Azure
linkTitle: Azure
weight: 10
---

## AKS Cluster Options

It's important to follow some guidelines when installing Flux on AKS.

### CNI and Network Policy

Previously, there has been an issue with Flux and Network Policy on AKS.
([Upstream Azure Issue](https://github.com/Azure/AKS/issues/2031)) ([Flux Issue](https://github.com/fluxcd/flux2/issues/703))
If you ensure your AKS cluster is upgraded, and your Nodes have been restarted with the most recent Node images,
this could resolve flux reconciliation failures where source-controller is unreachable.
Using `--network-plugin=azure --network-policy=calico` has been tested to work properly.
This issue only affects you if you are using `--network-policy` on AKS, which is not a default option.

{{% alert color="warning" %}}
AKS `--network-policy` is currently in Preview
{{% /alert %}}

### AAD Pod-Identity

Depending on the features you are interested in using with Flux, you may want to install AAD Pod Identity.
With [AAD Pod-Identity](https://azure.github.io/aad-pod-identity/docs/), we can create Pods that have their own
cloud credentials for accessing Azure services like Azure Container Registry(ACR) and Azure Key Vault(AKV).

If you do not use AAD Pod-Identity, you'll need to manage and store Service Principal credentials
in K8s Secrets, to integrate Flux with other Azure Services.

As a pre-requisite, your cluster must have `--enable-managed-identity` configured.

This software can be [installed via Helm](https://azure.github.io/aad-pod-identity/docs/getting-started/installation/)
(unmanaged by Azure).
Use Flux's `HelmRepository` and `HelmRelease` object to manage the aad-pod-identity installation
from a bootstrap repository and keep it up to date.

{{% alert %}}
As an alternative to Helm, the `--enable-aad-pod-identity` flag for the `az aks create` is currently in Preview.
Follow the Azure guide for [Creating an AKS cluster with AAD Pod Identity](https://docs.microsoft.com/en-us/azure/aks/use-azure-ad-pod-identity)
if you would like to enable this feature with the Azure CLI.
{{% /alert %}}

### Cluster Creation

The following creates an AKS cluster with some minimal configuration that will work well with Flux:

```sh
az aks create \
 --network-plugin="azure" \
 --network-policy="calico" \
 --enable-managed-identity \
 --enable-pod-identity \
 --name="my-cluster"
```

{{% alert color="info" %}}
When working with the Azure CLI, it can help to set a default `location`, `group`, and `acr`.
See `az configure --help`, `az configure --list-defaults`, and `az configure --defaults key=value`
{{% /alert %}}

## Flux Installation for Azure DevOps

See [Bootstrap Flux with Azure DevOps](../deploy-manage-flux/bootstrap/azure-devops.md).

### Flux Upgrade

See [Upgrade an Azure DevOps deployment of Flux](../deploy-manage-flux/upgrade/azure-devops.md).

## Helm Repositories on Azure Container Registry

The Flux `HelmRepository` object currently supports
[Chart Repositories](https://helm.sh/docs/topics/chart_repository/)
as well as fetching `HelmCharts` from paths in `GitRepository` sources.

Azure Container Registry has a sub-command ([`az acr helm`](https://docs.microsoft.com/en-us/cli/azure/acr/helm))
for working with ACR-Hosted Chart Repositories, but it is deprecated.
If you are using these deprecated Azure Chart Repositories,
you can use Flux `HelmRepository` objects with them.

[Newer ACR Helm documentation](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-helm-repos)
suggests using ACR as an experimental [Helm OCI Registry](https://helm.sh/docs/topics/registries/).
This will not work with Flux, because using Charts from OCI Registries is not yet supported.

## Secrets Management with SOPS and Azure Key Vault

You will need to create an Azure Key Vault and bind a credential such as a Service Principal or Managed Identity to it.
If you want to use Managed Identities, install or enable [AAD Pod Identity](#aad-pod-identity).

Patch kustomize-controller with the proper Azure credentials, so that it may access your Azure Key Vault, and then begin
committing SOPS encrypted files to the Git repository with the proper Azure Key Vault configuration.

See the [Mozilla SOPS Azure Guide](../guides/mozilla-sops.md#azure) for further detail.

## Image Updates with Azure Container Registry

You will need to create an ACR registry and bind a credential such as a Service Principal or Managed Identity to it.
If you want to use Managed Identities, install or enable [AAD Pod Identity](#aad-pod-identity).

You may need to update your Flux install to include additional components:

```sh
flux install \
  --components-extra="image-reflector-controller,image-automation-controller" \
  --export > ./clusters/my-cluster/flux-system/gotk-components.yaml
```

Follow the [Image Update Automation Guide](../guides/image-update.md) and see the
[ACR specific section](../guides/image-update.md#azure-container-registry) for more details.

Your AKS cluster's configuration can also be updated to
[allow the kubelets to pull images from ACR](https://docs.microsoft.com/en-us/azure/aks/cluster-container-registry-integration)
without ImagePullSecrets as an optional, complimentary step.

## Azure Event Hub with Notification controller

The Notification Controller supports both JWT and SAS based tokens but it also assumes that you will provide the notification-controller with a fresh token when needed.

For JWT token based auth we have created a small example on how to automatically generate a new token that the notification-controller can use.

First you will need to create a Azure Event Hub and bind a [credential](https://docs.microsoft.com/en-us/azure/event-hubs/authenticate-application) such as a Service Principal or Managed Identity to it.
If you want to use Managed Identities, install or enable [AAD Pod Identity](#aad-pod-identity).

We have two ways to [automatically generate](https://github.com/fluxcd/flux2/tree/main/manifests/integrations/eventhub-credentials-sync) new JWT tokens. Ether running as a deployment or a cronjob.

If you are using Azure Event Hub in Azure we recommend that you use aadpodidentity.
If you do you will need to update the [AzureIdentity config example](https://github.com/fluxcd/flux2/blob/main/manifests/integrations/eventhub-credentials-sync/azure/config-patches.yaml).

If you are in none Azure environment like on-prem or another cloud then you can utilize client secret which you will find in the example [generic folder](https://github.com/fluxcd/flux2/tree/main/manifests/integrations/eventhub-credentials-sync/generic).
Just like aadpodidentity you can use deployment based or a cronjob.

For more info on how to use Azure Event Hub with the [notification controller](../components/notification/provider.md#azure-event-hub).
