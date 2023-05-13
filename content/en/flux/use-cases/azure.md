---
title: Using Flux on Azure
linkTitle: Azure
description: "How to bootstrap Flux on Azure AKS with DevOps Git repositories."
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

### AAD Workload Identity

[AAD Workload Identities](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview) can be used
to enable access to AAD resources from workloads in your Kubernetes cluster.

In order to leverage AAD Workload Identities, you'll need to have `--enable-oidc-issuer` 
and `--enable-workload-identity` configured in your AKS cluster. 

You will also need to establish an identity that has access to ACR.

You can then [establish a federated identity credential](https://azure.github.io/azure-workload-identity/docs/quick-start.html#6-establish-federated-identity-credential-between-the-identity-and-the-service-account-issuer--subject) 
between the identity and the Flux source-controller ServiceAccount.

Please follow guides for [OCIRepositories and AAD Workload Identities](https://fluxcd.io/flux/components/source/ocirepositories/#workload-identity) 
and [HelmRepositories and AAD Workload Identities](https://fluxcd.io/flux/components/source/helmrepositories/#azure-workload-identity). 

### AAD Pod Identity

{{% warning %}}
[AAD Pod Identity has been deprecated](https://github.com/Azure/aad-pod-identity#-announcement) and replaced with 
Azure Workload Identity. 
{{% /warning %}}

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
 --enable-oidc-issuer \
 --enable-workload-identity \
 --name="my-cluster" 
```

{{% alert color="info" %}}
When working with the Azure CLI, it can help to set a default `location`, `group`, and `acr`.
See `az configure --help`, `az configure --list-defaults`, and `az configure --defaults key=value`
{{% /alert %}}

## Flux Installation for Azure DevOps

You can install Flux using a Azure Devops repository using the [`flux bootsrap git`](../installation.md#bootstrap)
command.
Ensure you can login to [dev.azure.com](https://dev.azure.com) for your proper organization,
and create a new repository to hold your Flux install and other Kubernetes resources.

To bootstrap using HTTPS only, run the following command:
```sh
flux bootstrap git \
  --url=https://dev.azure.com/<org>/<project>/_git/<repository> \
  --branch=main \
  --password=${AZ_PAT_TOKEN} \
  --token-auth=true
```

Please consult the [Azure DevOps documentation](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page)
on how to generate personal access tokens for Git repositories.
Azure DevOps PAT's always have an expiration date, so be sure to have some process for renewing or updating these tokens.
Similar to the lack of repo-specific deploy keys, a user needs to generate a user-specific PAT.
If you are using a machine-user, you can generate a PAT or simply use the machine-user's password which does not expire.

To bootstrap using HTTPS but drive the reconciliation in your cluster by cloning the repository using SSH, run:
```sh
flux bootstrap git \
  --url=https://dev.azure.com/<org>/<project>/_git/<repository> \
  --branch=main \
  --password=${AZ_PAT_TOKEN}} \
  --ssh-hostname=ssh.dev.azure.com
```

To bootstrap using SSH, run:
```sh
flux bootstrap git \
  --url=ssh://git@ssh.dev.azure.com/v3/<org>/<project>/<repository>
  --branch=main \
  --ssh-key-algorithm=rsa \
  --ssh-rsa-bits=4096 \
  --interval=1m
```

The above two commands will prompt you to add a deploy key to your repository, but Azure DevOps
[does not support repository or org-specific deploy keys](https://developercommunity.visualstudio.com/t/allow-the-creation-of-ssh-deploy-keys-for-vsts-hos/365747).
You may add the deploy key to a user's personal SSH keys, but take note that revoking
the user's access to the repository will also revoke Flux's access.
The better alternative is to create a machine-user whose sole purpose is to store credentials
for automation. Using a machine-user also has the benefit of being able to be read-only or
restricted to specific repositories if this is needed.

{{% alert color="info" %}}
Unlike `git`, Flux does not support the ["shorter" scp-like syntax for the SSH
protocol](https://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols#_the_ssh_protocol)
(e.g. `ssh.dev.azure.com:v3`).
Use the [RFC 3986 compatible syntax](https://tools.ietf.org/html/rfc3986#section-3) instead: `ssh.dev.azure.com/v3`.
{{% /alert %}}

## Helm Repositories on Azure Container Registry

The Flux `HelmRepository` object currently supports
[Chart Repositories](https://helm.sh/docs/topics/chart_repository/)
as well as fetching `HelmCharts` from paths in `GitRepository` sources.

Azure Container Registry has a sub-command ([`az acr helm`](https://docs.microsoft.com/en-us/cli/azure/acr/helm))
for working with ACR-Hosted Chart Repositories, but it is deprecated.
If you are using these deprecated Azure Chart Repositories,
you can use Flux `HelmRepository` objects with them.

### Using Helm OCI with Azure Container Registry

You can use Helm OCI Charts in Azure Container Registry with Flux.

You have to declare a `HelmRepository` object on your cluster:

```sh
flux create source helm podinfo \
  --url=oci://my-user.azurecr.io/charts/my-chart
  --username=username \
  --password=password
```

or if you are using a private registry:

```sh
flux create source helm my-helm-repo \
  --url=oci://my-user.azurecr.io/charts/my-chart
  --secret-ref=regcred
```

You can create the secret by running:

```sh
kubectl create secret docker-registry regcred \
 --docker-server=my-user.azurecr.io \
 --docker-username=az-user \
 --docker-password=az-token
```

Then, you can use the `HelmRepository` object in your `HelmRelease`:

```sh
flux create hr my-helm-release \
  --interval=10m \
  --source=HelmRepository/my-helm-repo \
  --chart=my-chart \
  --chart-version=">6.0.0"
```

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
