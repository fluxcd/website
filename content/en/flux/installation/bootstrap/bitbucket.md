---
title: Flux bootstrap for Bitbucket
linkTitle: Bitbucket
description: "How to bootstrap Flux with Bitbucket Server and Data Center"
weight: 40
---

### Bitbucket Server and Data Center

The `bootstrap bitbucket-server` command creates a Bitbucket Server repository if one doesn't exist and
commits the Flux components manifests to the specified branch. Then it
configures the target cluster to synchronize with that repository by
setting up an SSH deploy key or by using token-based authentication.

{{% alert color="info" title="Bitbucket versions" %}}
This bootstrap command works with Bitbucket Server and Data Center only because it targets the [1.0](https://developer.atlassian.com/server/bitbucket/reference/rest-api/) REST API. Bitbucket Cloud has migrated to the [2.0](https://developer.atlassian.com/cloud/bitbucket/rest/intro/) REST API.
{{% /alert %}}

Generate a [personal access token](https://confluence.atlassian.com/bitbucketserver/http-access-tokens-939515499.html)
that grant read/write access to the repository.

Export your Bitbucket personal access token as an environment variable:

```sh
export BITBUCKET_TOKEN=<your-token>
```

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
