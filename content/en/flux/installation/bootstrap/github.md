---
title: Flux bootstrap for GitHub
linkTitle: GitHub
description: "How to bootstrap Flux with GitHub and GitHub Enterprise"
weight: 20
---

The [flux bootstrap github](/flux/cmd/flux_bootstrap_github/) command deploys the Flux controllers
on a Kubernetes cluster and configures the controllers to sync the cluster state from a GitHub repository.
Besides installing the controllers, the bootstrap command pushes the Flux manifests to the GitHub repository
and configures Flux to update itself from Git.

After running the bootstrap command, any operation on the cluster (including Flux upgrades)
can be done via Git push, without the need to connect to the Kubernetes cluster.

{{% alert color="danger" title="Required permissions" %}}
To bootstrap Flux, the person running the command must have **cluster admin rights** for the target Kubernetes cluster.
It is also required that the person running the command to be the **owner** of the GitHub repository,
or to have admin rights of a GitHub organization.
{{% /alert %}}

## GitHub PAT 

For accessing the GitHub API, the boostrap command requires a GitHub personal access token (PAT)
with administration permissions.

The GitHub PAT can be exported as an environment variable:

```sh
export GITHUB_TOKEN=<gh-token>
```

If the `GITHUB_TOKEN` env var is not set, the bootstrap command will prompt you to type it the token.

You can also supply the token using a pipe e.g. `echo "<gh-token>" | flux bootstrap github`.

## GitHub Personal Account

If you want to bootstrap Flux for a repository owned by a personal account, you can generate a
[GitHub PAT](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line)
that can create repositories by checking all permissions under `repo`.

If you want to use an existing repository, the PAT's user must have `admin`
[permissions](https://docs.github.com/en/organizations/managing-access-to-your-organizations-repositories/repository-roles-for-an-organization#permissions-for-each-role).

Run the bootstrap for a repository on your personal GitHub account:

```sh
flux bootstrap github \
  --token-auth \
  --owner=my-github-username \
  --repository=my-repository-name \
  --branch=main \
  --path=clusters/my-cluster \
  --personal
```

If the specified repository does not exist, Flux will create it for you as private. If you wish to create
a public repository, set `--private=false`.

When using `--token-auth`, the CLI and the Flux controllers running on the cluster will use the GitHub PAT
to access the Git repository over HTTPS.

{{% alert color="danger" title="PAT secret" %}}
Note that the GitHub PAT is stored in the cluster as a **Kubernetes Secret** named `flux-system`
inside the `flux-system` namespace. If you want to avoid storing your PAT in the cluster,
please see how to configure [GitHub Deploy Keys](#github-deploy-keys).
{{% /alert %}}

## GitHub Organization

If you want to bootstrap Flux for a repository owned by an GitHub organization,
it is recommended to creat a dedicated user for Flux under your organization.

Generate a GitHub PAT for the Flux user that can create repositories by checking all permissions under `repo`.

If you want to use an existing repository, the Flux user must have `admin` permissions for that repository.

Run the bootstrap for a repository owned by a GitHub organization:

```sh
flux bootstrap github \
  --token-auth \
  --owner=my-github-organization \
  --repository=my-repository \
  --branch=main \
  --path=clusters/my-cluster
```

When creating a new repository, you can specify a list of GitHub teams with `--team=team1-slug,team2-slug`,
those teams will be granted maintainer access to the repository.

## GitHub Enterprise

To run the bootstrap for a repository hosted on GitHub Enterprise, you have to specify your GitHub hostname:

```sh
flux bootstrap github \
  --token-auth \
  --hostname=my-github-enterprise.com \
  --owner=my-github-organization \
  --repository=my-repository \
  --branch=main \
  --path=clusters/my-cluster
```

If you want use SSH and [GitHub deploy keys](#github-deploy-keys),
set `--token-auth=false` and provide the SSH hostname with `--ssh-hostname=my-github-enterprise.com`.

## GitHub Deploy Keys

If you want to bootstrap Flux using SSH instead of HTTP/S, you can set `--token-auth=false` and the Flux CLI
will use the GitHub PAT to set a deploy key for your repository.

When using SSH, the bootstrap command will generate a SSH private key. The private key is stored
in the cluster as a Kubernetes secret named `flux-system` inside the `flux-system` namespace.

The generated SSH key defaults to `ECDSA P-384`, to change the format use `--ssh-key-algorithm` and `--ssh-ecdsa-curve`.

The SSH public key, is used to create a GitHub deploy key.
The deploy key is linked to the personal access token used to authenticate.

By default, the GitHub deploy key is set to read-only access.
If you're using Flux image automation, you must give it write access with `--read-write-key=true`.

{{% alert color="info" title="Deploy Key rotation" %}}
Note that when the PAT is removed or when it expires, the GitHub deploy key will stop working.
To regenerate the deploy key, delete the `flux-system` secret from the cluster and re-run
the bootstrap command using a valid GitHub PAT.
{{% /alert %}}

## Bootstrap without a GitHub PAT

For existing GitHub repositories, you can bootstrap Flux over SSH without using a GitHub PAT.

To use a SSH key instead of a GitHub PAT, the command changes to `flux bootstrap git`:

```shell
flux bootstrap git \
  --url=ssh://git@github.com/<org>/<repository> \
  --branch=<my-branch> \
  --private-key-file=<path/to/ssh/private.key> \
  --password=<key-passphrase> \
  --path=clusters/my-cluster
```

**Note** that you must generate a SSH private key and set the public key as a deploy key on GitHub in advance.

For more information on how to use the `flux bootstrap git` command,
please see the generic Git server [documentation](generic-git-server.md).
