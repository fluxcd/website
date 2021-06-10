---
title: "Changing the source repository"
linkTitle: "Change source repository"
description: "How to change the repository containing your Flux configuration"
weight: 50
---

This guide walks you through changing the Git repository containing the configurations that Flux applies.
An example use case is moving from one Git provider to another. For example, between self-hosted Git, GitHub, or GitLab.

## Prerequisites
To follow the next steps you will first need to migrate your current Git repository to the final destination. This step is not
covered in this guide. An example of migrating (mirroring) a repository can be found [in the GitHub documentation](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-repository-on-github/duplicating-a-repository).

Please ensure that you have migrated the complete repository to the final destination before continuing. This includes branches, commits, and anything else you find important to migrate.

## Create a new GitRepository resource

In this step you will create a new [GitRepository](https://fluxcd.io/docs/components/source/gitrepositories/#specification) resource that matches your new repository. The configuration depends on where you are migrating your repository, your new branch name, a `secretRef` if you are using credentials, and so on.

You can use the [GitRepository](https://fluxcd.io/docs/components/source/gitrepositories/#specification) specification to guide you if you need a very specific configuration. Below is an example for a basic configuration. Save your configuration in a file but do not apply it yet.

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: GitRepository
metadata:
  name: my-new-gitrepository
  namespace: flux-system
spec:
  interval: 5m0s
  ref:
    branch: main
  secretRef:
    name: my-new-secret
  timeout: 20s
  url: https://example.com/my-new-project/infra/flux-configuration.git
```

## Create credentials for your new repository

If you need credentials to access your new Git repository, then they should be referred to in your [GitRepository](https://fluxcd.io/docs/components/source/gitrepositories/#specification) configuration. The credentials are standard [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/). The example GitRepository above contains a reference to a secret called `my-new-secret`.

As seen in the [GitRepository specification](https://fluxcd.io/docs/components/source/gitrepositories/#specification) the secret must contain a `username` and `password` for HTTPS authentication, or `identity`, `identity.pub` and `known_hosts` for SSH authentication.

The credential fields must be base64 encoded. This can for example be done with the `base64` tool.
```bash
$ echo -n exampleUser | base64
ZXhhbXBsZVVzZXI=
$ echo -n secretPassword | base64
c2VjcmV0UGFzc3dvcmQ=
```

{{% alert color="info" title="Encrypting secrets" %}}
Base64 encoding is not encryption. To safely store your secrets in a Git repository use [sealed-secrets](https://fluxcd.io/docs/guides/sealed-secrets/) or [Mozilla SOPS](https://fluxcd.io/docs/guides/mozilla-sops/).
{{% /alert %}}

### HTTPS credentials

The HTTPS credential can contain either a password or an access token if your new Git provider offers this feature, e.g. [GitHub access tokens](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token) or [GitLab access tokens](https://docs.gitlab.com/ee/security/token_overview.html). Below is an example of a secret used for HTTPS. Save your secret in a file but do not apply it yet.

```yaml
apiVersion: v1
data:
  username: ZXhhbXBsZVVzZXI=
  password: c2VjcmV0UGFzc3dvcmQ=
kind: Secret
metadata:
  name: my-new-secret
  namespace: flux-system
type: Opaque
```
### SSH credentials

If you prefer to use SSH authentication please see the following example. The SSH key secret contains three fields -- `identity`, `identity.pub` and `known_hosts`.

First, you need to create an SSH key that can access the new repository following the instructions of your new Git provider. For an example, see [GitHub](https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) or [GitLab](https://docs.gitlab.com/ee/ssh/#generate-an-ssh-key-pair) instructions. The resulting SSH key has a private part and a public part. Make sure that you can access the repository using that SSH key.

To get the `known_hosts` field you can use `ssh-keyscan` with the URL of your new Git provider. For example:

```sh
ssh-keyscan example.com > ./known_hosts
```

Then you need to base64 encode the `known_hosts` file that you created as well as the private part and public part of the SSH key. Make sure to use `-w0` to have the output as one line. 
```sh
cat known_hosts | base64 -w0
Z2l0bGFiLmNvbSBzc2gtcnNhIEFBQUFCM056YUMxeWMyRUFBQUFEQVFBQkFBQUJBUUNzA ...
cat ~/my_key | base64 -w0
RWRXVC9pYTFORUtqdW5VcXUxeE9CL1N0S0RITW9YNC9PS3lJenVTMHEvVDF6T0FUdGh2Y ...
cat ~/my_key.pub | base64 -w0
TFZYVllyVTlRbFlXck9MWEJwUTZLV2pialREVGREa29vaEZ6Z2JFWT0KZ2l0PS3lJenVT ...
```

Copy the base64 encoded output into a [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/) as seen below. Save your secret in a file but do not apply it yet.
```yaml
apiVersion: v1
data:
  identity: base-64-encoded-secret-key-here
  identity.pub: base-64-encoded-public-key-here
  known_hosts: base-64-encoded-known-hosts-here
kind: Secret
metadata:
  name: my-new-secret
  namespace: flux-system
type: Opaque
```

## Create an updated Kustomization for your new repository

The next step is to create an updated [Kustomization](https://fluxcd.io/docs/components/kustomize/kustomization/) definition that points to your new repository. You can use your old Kustomization as a base in case you will keep using a similar configuration. The minimum change will be a new name for the Kustomization and changing the `sourceRef.name` field that should point to your new Git repository.

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
kind: Kustomization
metadata:
  name: my-new-kustomization
  namespace: flux-system
spec:
  interval: 10m0s
  path: ./my/path
  prune: true
  sourceRef:
    kind: GitRepository
    name: my-new-gitrepository
```

## Applying the new configuration

Now you are ready to update the configuration and perform the switch to your new Git repository. The first step is to create the new secret and the [GitRepository](https://fluxcd.io/docs/components/source/gitrepositories/#specification) as Kubernetes resources.

The new configuration can either be added using Flux or simply applied, e.g. with `kubectl apply -f my-new-gitrepository.yaml`. If you manage all of your configuration with Flux you should remember to add the new secret and [GitRepository](https://fluxcd.io/docs/components/source/gitrepositories/#specification) definition both to the old and the new Git repository.

If you store the Kustomization in Git, please make sure that your new Kustomization is also added to the new Git repository.

### Ensuring that the new Git repository works

The next step is to ensure that the new Git repository works and is accessible to your current Flux setup. If there is any error at this step you cannot continue, because it means you cannot reach your new repository. A common error is that the credentials are wrong or that the secret is formatted in the wrong way. Please verify your credentials and make sure that they are correct. Do not continue until the repository can be reconciled.

```sh
$ flux reconcile source git my-new-gitrepository
► annotating GitRepository flux-system in flux-system namespace
✔ GitRepository annotated
◎ waiting for GitRepository reconciliation
✔ GitRepository reconciliation completed
✔ fetched revision main/commit-hash-of-your-new-git-repository
```
### Pointing the Kustomization(s) to the new repository

The last step is to update the `sourceRef.name` in the Kustomization in your old repository to point to the new repository. If you have many Kustomization resources you need to update all of them.

If you manage your Kustomization with Git and Flux, then the Kustomization can simply be updated, committed and reconciled. If you do not manage it with Git and prefer to edit it manually, you can edit the `sourceRef.name` in your old Kustomization, for example, with `kubectl edit kustomization my-old-kustomization` and then reconcile the Kustomization.

An example with Flux and Git:
```sh
$ flux export kustomization --all > my-old-kustomization.yaml
$ vim my-old-kustomization.yaml
$ git add my-old-kustomization.yaml
$ git commit -m "Point my-old-kustomization to new repository"
$ git push

$ flux reconcile source git my-old-repository
► annotating GitRepository flux-system in flux-system namespace
✔ GitRepository annotated
◎ waiting for GitRepository reconciliation
✔ GitRepository reconciliation completed
✔ fetched revision main/commit-hash-of-your-old-repository

$ flux reconcile kustomization my-old-kustomization
► annotating Kustomization flux-system in flux-system namespace
✔ Kustomization annotated
◎ waiting for Kustomization reconciliation
✔ Kustomization reconciliation completed
✔ reconciled revision main/commit-hash-of-your-new-repository
```

{{% alert color="info" title="Verify the new repository" %}}
Ensure that the reconciliation of your old Kustomization points to a revision with the correct branch and commit hash of your new repository.
{{% /alert %}}

After this step you can clean up the old resources as necessary and start using the new repository.

