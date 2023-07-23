---
title: Flux bootstrap for Bitbucket
linkTitle: Bitbucket
description: "How to bootstrap Flux with Bitbucket Server and Data Center"
weight: 40
---

The [flux bootstrap bitbucket-server](/flux/cmd/flux_bootstrap_bitbucket-server/) command deploys the Flux controllers	
on a Kubernetes cluster and configures the controllers to sync the cluster state from a Bitbucket project.	
Besides installing the controllers, the bootstrap command pushes the Flux manifests to the Bitbucket project	
and configures Flux to update itself from Git.	

After running the bootstrap command, any operation on the cluster (including Flux upgrades)	
can be done via Git push, without the need to connect to the Kubernetes cluster.

{{% alert color="danger" title="Required permissions" %}}
To bootstrap Flux, the person running the command must have **cluster admin rights** for the target Kubernetes cluster.
It is also required that the person running the command to be the **owner** of the Bitbucket project,
or to have admin rights of a Bitbucket group.
{{% /alert %}}

{{% alert color="info" title="Bitbucket versions" %}}
This bootstrap command works with Bitbucket Server and Data Center only because it targets the [1.0](https://developer.atlassian.com/server/bitbucket/reference/rest-api/) REST API. Bitbucket Cloud has migrated to the [2.0](https://developer.atlassian.com/cloud/bitbucket/rest/intro/) REST API.
{{% /alert %}}

## Bitbucket HTTP Access Token 

For accessing the Bitbucket API, the bootstrap command requires a [Bitbucket HTTP Access Token](https://confluence.atlassian.com/bitbucketserver/http-access-tokens-939515499.html) 
with administration permissions.

The Bitbucket HTTP access token can be exported as an environment variable:

```sh
export BITBUCKET_TOKEN=<bb-token>
```

If the `BITBUCKET_TOKEN` env var is not set, the bootstrap command will prompt you to type it the token.
You can also supply the token using a pipe e.g. `echo "<bb-token>" | flux bootstrap bitbucket-server`.

## Bitbucket Personal Account

Run the bootstrap for a repository on your personal Bitbucket Server account:

```sh
flux bootstrap bitbucket-server \
  --owner=my-bitbucket-username \
  --repository=my-repository \
  --branch=main \
  --path=clusters/my-cluster \
  --hostname=my-bitbucket-server.com \
  --personal
```
## Bitbucket Personal Project

Run the bootstrap for a repository owned by a Bitbucket Server project:

```sh
flux bootstrap bitbucket-server \
  --owner=my-bitbucket-project \
  --username=my-bitbucket-username \
  --repository=my-repository \
  --path=clusters/my-cluster \
  --hostname=my-bitbucket-server.com \
  --group=group-name 
```

When you specify a list of groups, those teams will be granted write access to the repository.

**Note:** The `username` is mandatory for `project` owned repositories. The specified user must own the `BITBUCKET_TOKEN` and have sufficient rights on the target `project` to create repositories.

## Bootstrap with a different SSH hostname

To run the bootstrap for a repository with a different SSH hostname (e.g. with a different port):

```sh
flux bootstrap bitbucket-server \
  --hostname=my-bitbucket-server.com \
  --ssh-hostname=my-bitbucket-server.com:7999 \
  --owner=my-bitbucket-project \
  --username=my-bitbucket-username \
  --repository=my-repository \
  --branch=main \
  --path=clusters/my-cluster
```

## Bootstrap with SSH disabled

If your Bitbucket Server has SSH access disabled, you can use HTTPS and token authentication with:

```sh
flux bootstrap bitbucket-server \
  --token-auth \
  --hostname=my-bitbucket-server.com \
  --owner=my-bitbucket-project \
  --username=my-bitbucket-username \
  --repository=my-repository \
  --branch=main \
  --path=clusters/my-cluster
```
