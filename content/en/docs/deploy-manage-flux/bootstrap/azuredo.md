---
title: "Bootstrap Flux on Azure DevOps"
linkTitle: Azure DevOps
---

## Before you begin

To follow this guide you will need the following:

- The Flux CLI. See [Install the Flux CLI](../../installation.md#install-the-flux-cli) for instructions.
- A Kubernetes Cluster. If using a cluster hosted on Azure see the [Azure use cases](../../use-cases/azure.md) guide for recommended cluster settings.
- An Azure DevOps Git Repository to hold your Flux install and Kubernetes resources
- An Azure DevOps account that Flux will use to authenticate with Azure DevOps.
  {{% note %}}
  We recommend you create a machine-user to store credentials for Flux.
  {{% /note %}}
- An Azure Devops personal access token for your Git Repository
  - Please consult the [Azure DevOps documentation](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page) on how to generate personal access tokens for Git repositories.
  - If you are using a machine-user, you can generate a PAT or use the machine-user's password which does not expire.

## Clone your Git repository locally

```bash
git clone ssh://git@ssh.dev.azure.com/v3/<org>/<project>/<my-repository>
cd <my-repository>
```

## Create a directory inside the repository

Create a directory to store Flux system components:

```bash
mkdir -p ./flux-system
```

{{% note %}}
If you are planning to use the same repo for multiple clusters, you can place the ``flux-system`` inside a nested directory. See [Repository Structure](../repository-structure.md) for more information.
{{% /note %}}

## Generate Flux Component Manifests

Generate custom resources and deployments definition for Flux's components.

Run the install command:

```bash
flux install \
  --export > ./flux-system/gotk-components.yaml
```

Commit and push the manifest to the master branch:

```bash
git add -A && git commit -m "add components" && git push

```

## Apply Flux manifests to cluster

Apply the manifests you just generated onto your cluster:

```bash
kubectl apply -f ./flux-system/gotk-components.yaml
```

## Verify Flux is running

Verify that the controllers have started:

```bash
flux check
```

## Create flux-system Git Repository source

Specify the Git Repository Flux will retrieve definitions from.

You can use SSH or HTTPS

{{% tabs %}}
{{% tab "SSH" %}}

Create a `GitRepository` that uses Git over SSH:

```bash
flux create source git flux-system \
  --git-implementation=libgit2 \
  --url=ssh://git@ssh.dev.azure.com/v3/<org>/<project>/<repository> \
  --branch=<branch> \
  --ssh-key-algorithm=rsa \
  --ssh-rsa-bits=4096 \
  --interval=1m
```

{{% /tab %}}
{{% tab "HTTPS" %}}

Create a `GitRepository` that uses Git over HTTPS:

```bash
flux create source git flux-system \
  --git-implementation=libgit2 \
  --url=https://dev.azure.com/<org>/<project>/_git/<repository> \
  --branch=main \
  --username=git \
  --password=${AZ_PAT_TOKEN} \
  --interval=1m
```

{{% note %}}
If you are using a machine-user, you can use the machine-user's password instead of a personal access token.
{{% /note %}}
{{% /tab %}}
{{% /tabs %}}

## Add the deploy key

The above command will prompt you to add a deploy key to your repository.

Add this key to the personal SSH keys of the Azure DevOps user that Flux will use to authenticate to your repo.

## Export the flux-system Git Repository source

Export the Git Repository definition:

```bash
flux export source git flux-system \
  > ./flux-system/gotk-sync.yaml
```

## Create the flux-system Kustomization

Tell flux to apply ``flux-system`` manifests.

Create a `Kustomization` object on your cluster:

```bash
flux create kustomization flux-system \
  --source=flux-system \
  --path="./" \
  --prune=true \
  --interval=10m
```

## Export the flux-system Kustomization

Export the ``flux-system`` Kustomization:

```
flux export kustomization flux-system \
  >> ./flux-system/gotk-sync.yaml
```

## Export and commit Flux Manifests

Generate a `kustomization.yaml`:

```bash
cd ./flux-system && kustomize create --autodetect
```

Commit and push the manifests to Git:

```bash
git add -A && git commit -m "add sync manifests" && git push
```

## Watch Flux reconcile changes

Wait for Flux to reconcile your previous commit with:

```bash
flux get kustomizations --watch
```
