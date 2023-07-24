---
title: Flux bootstrap for Azure DevOps
linkTitle: Azure DevOps
description: "How to bootstrap Flux with Azure DevOps"
weight: 60
---

To install Flux on an AKS cluster using an Azure DevOps Git repository as the source of truth,
you can use the [`flux bootstrap git`](generic-git-server.md) command.

{{% alert color="danger" title="Required permissions" %}}
To bootstrap Flux, the person running the command must have **cluster admin rights** for the target Kubernetes cluster.
It is also required that the person running the command to have **pull and push rights** for the Azure DevOps Git repository.
{{% /alert %}}

## Azure DevOps PAT

For accessing the Azure API, the boostrap command requires an Azure DevOps personal access token (PAT)
with pull and push permissions for Git repositories.

Generate an [Azure DevOps PAT](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page)
and create a new repository to hold your Flux install and other Kubernetes resources.

The Azure DevOps PAT can be exported as an environment variable:

```sh
export GIT_PASSWORD=<az-token>
```

If the `GIT_PASSWORD` env var is not set, the bootstrap command will prompt you to type it the token.

You can also supply the token using a pipe e.g. `echo "<az-token>" | flux bootstrap git`.

## Bootstrap using a DevOps PAT

Run the bootstrap for a repository using token-based authentication:

```sh
flux bootstrap git \
  --token-auth=true \
  --url=https://dev.azure.com/<org>/<project>/_git/<repository> \
  --branch=main \
  --path=clusters/my-cluster
```

When using `--token-auth`, the CLI and the Flux controllers running on the cluster will use the Azure DevOps PAT
to access the Git repository over HTTPS.

Note that the Azure DevOps PAT is stored in the cluster as a **Kubernetes Secret** named `flux-system`
inside the `flux-system` namespace.

{{% alert color="info" title="Token rotation" %}}
Note that Azure DevOps PAT have an expiry date. To rotate the token before it expires,
delete the `flux-system` secret from the cluster and re-run
the bootstrap command using a valid PAT.
{{% /alert %}}

If you want to avoid storing your PAT in the cluster, set `--ssh-hostname` and the Flux controllers will use SSH:

```shell
flux bootstrap git \
  --url=https://dev.azure.com/<org>/<project>/_git/<repository> \
  --branch=main \
  --password=${GIT_PASSWORD} \
  --ssh-hostname=ssh.dev.azure.com \
  --ssh-key-algorithm=rsa \
  --ssh-rsa-bits=4096 \
  --path=clusters/my-cluster
```

The bootstrap command will generate a new SSH private key for the cluster,
and it will prompt you to add the SSH public key to your personal SSH keys.

## Bootstrap without a DevOps PAT

To bootstrap using a SSH key instead of a Azure DevOps PAT, run:

```sh
flux bootstrap git \
  --url=ssh://git@ssh.dev.azure.com/v3/<org>/<project>/<repository>
  --branch=<my-branch> \
  --private-key-file=<path/to/ssh/private.key> \
  --password=<key-passphrase> \
  --path=clusters/my-cluster
```

**Note** that you must generate an SSH private key and set the public key to your personal SSH keys in advance.

For more information on how to use the `flux bootstrap git` command,
please see the generic Git server [documentation](generic-git-server.md).
