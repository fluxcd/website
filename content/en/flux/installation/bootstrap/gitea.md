---
title: Flux bootstrap for Gitea
linkTitle: Gitea
description: "How to bootstrap Flux with Gitea"
weight: 20
---

The [flux bootstrap gitea](/flux/cmd/flux_bootstrap_gitea/) command deploys the Flux controllers
on a Kubernetes cluster and configures the controllers to sync the cluster state from a Gitea repository.
Besides installing the controllers, the bootstrap command pushes the Flux manifests to the Gitea repository
and configures Flux to update itself from Gitea.

After running the bootstrap command, any operation on the cluster (including Flux upgrades)
can be done via Git push, without the need to connect to the Kubernetes cluster.

{{% alert color="danger" title="Required permissions" %}}
To bootstrap Flux, the person running the command must have **cluster admin rights** for the target Kubernetes cluster.
It is also required that the person running the command to be the **owner** of the Gitea repository,
or to have admin rights of a Gitea organization.
{{% /alert %}}

## Gitea PAT 

For accessing the Gitea API, the boostrap command requires a Gitea personal access token (PAT)
with administration permissions.

The Gitea PAT can be exported as an environment variable:

```sh
export GITEA_TOKEN=<gt-token>
```

If the `GITEA_TOKEN` env var is not set, the bootstrap command will prompt you to type it the token.

You can also supply the token using a pipe e.g. `echo "<gt-token>" | flux bootstrap gitea`.

## Gitea Personal Account

If you want to bootstrap Flux for a repository owned by a personal account, you can generate a
[Gitea PAT](https://gitea.com/user/settings/applications)
that can create repositories by checking all permissions under `Select permissions` drop down menu.

If you want to use an existing repository, the PAT's user must have `admin`
[permissions](https://docs.gitea.com/development/oauth2-provider#scopes).

Run the bootstrap for a repository on your personal Gitea account:

```sh
flux bootstrap gitea \
  --token-auth \
  --owner=my-gitea-username \
  --repository=my-repository-name \
  --branch=main \
  --path=clusters/my-cluster \
  --personal
```

If the specified repository does not exist, Flux will create it for you as private. If you wish to create
a public repository, set `--private=false`.

When using `--token-auth`, the CLI and the Flux controllers running on the cluster will use the Gitea PAT
to access the Git repository over HTTPS.

{{% alert color="danger" title="PAT secret" %}}
Note that the Gitea PAT is stored in the cluster as a **Kubernetes Secret** named `flux-system`
inside the `flux-system` namespace. If you want to avoid storing your PAT in the cluster,
please see how to configure [Gitea Deploy Keys](#gitea-deploy-keys).
{{% /alert %}}

## Gitea Organization

If you want to bootstrap Flux for a repository owned by a Gitea organization,
it is recommended to create a dedicated user for Flux under your organization.

Generate a Gitea PAT for the Flux user that can create repositories by checking all permissions under `Select permissions`.

If you want to use an existing repository, the Flux user must have `admin` permissions for that repository.

Run the bootstrap for a repository owned by a Gitea organization:

```sh
flux bootstrap gitea \
  `--token-auth` \
  --owner=my-gitea-organization \
  --repository=my-repository \
  --branch=main \
  --path=clusters/my-cluster
```

## Gitea Deploy Keys

If you want to bootstrap Flux using SSH instead of HTTP/S, you can set `--token-auth=false` and the Flux CLI
will use the Gitea PAT to set a deploy key for your repository.

When using SSH, the bootstrap command will generate a SSH private key. The private key is stored
in the cluster as a Kubernetes secret named `flux-system` inside the `flux-system` namespace.

The generated SSH key defaults to `ECDSA P-384`, to change the format use `--ssh-key-algorithm` and `--ssh-ecdsa-curve`.

The SSH public key, is used to create a Gitea deploy key.
The deploy key is linked to the personal access token used to authenticate.

By default, the Gitea deploy key is set to read-only access.
If you're using Flux image automation, you must give it write access with `--read-write-key=true`.

{{% alert color="info" title="Deploy Key rotation" %}}
Note that when the PAT is removed or when it expires, the Gitea deploy key will stop working.
To regenerate the deploy key, delete the `flux-system` secret from the cluster and re-run
the bootstrap command using a valid Gitea PAT.
{{% /alert %}}

## Bootstrap without a Gitea PAT

For existing Gitea repositories, you can bootstrap Flux over SSH without using a Gitea PAT.

To use a SSH key instead of a Gitea PAT, the command changes to `flux bootstrap git`:

```shell
flux bootstrap git \
  --url=ssh://git@gitea.com/<org>/<repository> \
  --branch=<my-branch> \
  --private-key-file=<path/to/ssh/private.key> \
  --password=<key-passphrase> \
  --path=clusters/my-cluster
```

**Note** that you must generate a SSH private key and set the public key as a deploy key on Gitea in advance.

For more information on how to use the `flux bootstrap git` command,
please see the generic Git server [documentation](generic-git-server.md).
