---
title: Flux bootstrap for GitLab
linkTitle: GitLab
description: "How to bootstrap Flux with GitLab and GitLab Enterprise"
weight: 30
---

The [flux bootstrap gitlab](/flux/cmd/flux_bootstrap_gitlab/) command deploys the Flux controllers
on a Kubernetes cluster and configures the controllers to sync the cluster state from a GitLab project.
Besides installing the controllers, the bootstrap command pushes the Flux manifests to the GitLab project
and configures Flux to update itself from Git.

After running the bootstrap command, any operation on the cluster (including Flux upgrades)
can be done via Git push, without the need to connect to the Kubernetes cluster.

{{% alert color="danger" title="Required permissions" %}}
To bootstrap Flux, the person running the command must have **cluster admin rights** for the target Kubernetes cluster.
It is also required that the person running the command to be the **owner** of the GitLab project,
or to have admin rights of a GitLab group.
{{% /alert %}}

## GitLab PAT

For accessing the GitLab API, the boostrap command requires a GitLab personal access token (PAT)
with complete read/write access to the GitLab API.

The GitLab PAT can be exported as an environment variable:

```sh
export GITLAB_TOKEN=<gl-token>
```

If the `GITLAB_TOKEN` env var is not set, the bootstrap command will prompt you to type it the token.

You can also supply the token using a pipe e.g. `echo "<gl-token>" | flux bootstrap gitlab`.

## GitLab Personal Account

Run the bootstrap for a project on your personal GitLab account:

```sh
flux bootstrap gitlab \
  --deploy-token-auth \
  --owner=my-gitlab-username \
  --repository=my-project \
  --branch=master \
  --path=clusters/my-cluster \
  --personal
```

If the specified project does not exist, Flux will create it for you as private. If you wish to create
a public project, set `--private=false`.

When using `--deploy-token-auth`, the CLI generates a
[GitLab project deploy token](https://docs.gitlab.com/ee/user/project/deploy_tokens/)
and stores it in the cluster as a Kubernetes Secret named `flux-system`
inside the `flux-system` namespace.

{{% alert color="danger" title="Deploy token read-only" %}}
Note that project deploy tokens grant read-only access to Git.
If you want to use Flux image automation, please see how to configure
[GitLab Deploy Keys](#gitlab-deploy-keys) with read-write Git accesses.
{{% /alert %}}

## GitLab Groups

Run the bootstrap for a project owned by a GitLab (sub)group:

```sh
flux bootstrap gitlab \
  --deploy-token-auth \
  --owner=my-gitlab-group/my-gitlab-subgroup \
  --repository=my-project \
  --branch=master \
  --path=clusters/my-cluster
```

## GitLab Enterprise

To run the bootstrap for a project hosted on GitLab on-prem or enterprise, you have to specify your GitLab hostname:

```sh
flux bootstrap gitlab \
  --token-auth \
  --hostname=my-gitlab-enterprise.com \
  --owner=my-gitlab-group \
  --repository=my-project \
  --branch=master \
  --path=clusters/my-cluster
```

If you want use SSH and [GitLab deploy keys](#gitlab-deploy-keys),
set `--token-auth=false` and provide the SSH hostname with `--ssh-hostname=my-gitlab-enterprise.com`.

## GitLab Deploy Keys

If you want to bootstrap Flux using SSH instead of HTTP/S, you can set `--token-auth=false`
and the Flux CLI will use the GitLab PAT to set a deploy key for your project.

When using SSH, the bootstrap command will generate a SSH private key. The private key is stored
in the cluster as a Kubernetes secret named `flux-system` inside the `flux-system` namespace.

The generated SSH key defaults to `ECDSA P-384`, to change the format use `--ssh-key-algorithm` and `--ssh-ecdsa-curve`.

The SSH public key, is used to create a GitLab deploy key.
By default, the GitLab deploy key is set to read-only access.
If you're using Flux image automation, you must give it write access with `--read-write-key=true`.

{{% alert color="info" title="Deploy Key rotation" %}}
To regenerate the deploy key, delete the `flux-system` secret from the cluster and re-run
the bootstrap command using a valid GitLab PAT.
{{% /alert %}}

## Bootstrap without a GitLab PAT

For existing GitLab repositories, you can bootstrap Flux over SSH without using a GitLab PAT.

To use an SSH key instead of a GitLab PAT, the command changes to `flux bootstrap git`:

```shell
flux bootstrap git \
  --url=ssh://git@gitlab.com/<group>/<project> \
  --branch=<my-branch> \
  --private-key-file=<path/to/ssh/private.key> \
  --password=<key-passphrase> \
  --path=clusters/my-cluster
```

**Note** that you must generate an SSH private key and set the public key as a deploy key on GitLab in advance.

For more information on how to use the `flux bootstrap git` command,
please see the generic Git server [documentation](generic-git-server.md).
