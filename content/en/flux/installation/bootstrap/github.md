---
title: GitHub
linkTitle: GitHub
description: "How to follow bootstrap procedure for Flux using GitHub"
weight: 20
---
### GitHub and GitHub Enterprise

The `bootstrap github` command creates a GitHub repository if one doesn't exist and
commits the Flux components manifests to specified branch. Then it
configures the target cluster to synchronize with that repository by
setting up an SSH deploy key or by using token-based authentication.

Generate a [personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line)
(PAT) that can create repositories by checking all permissions under `repo`. If
a pre-existing repository is to be used the PAT's user will require `admin`
[permissions](https://docs.github.com/en/organizations/managing-access-to-your-organizations-repositories/repository-roles-for-an-organization#permissions-for-each-role)
on the repository in order to create a deploy key.

Export your GitHub personal access token as an environment variable:

```sh
export GITHUB_TOKEN=<your-token>
```

Run the bootstrap for a repository on your personal GitHub account:

```sh
flux bootstrap github \
  --owner=my-github-username \
  --repository=my-repository \
  --path=clusters/my-cluster \
  --personal
```

{{% alert color="info" title="Deploy key" %}}
The bootstrap command creates an SSH key which it stores as a secret in the
Kubernetes cluster. The key is also used to create a deploy key in the GitHub
repository. The new deploy key will be linked to the personal access token used
to authenticate. **Removing the personal access token will also remove the deploy key.**
{{% /alert %}}

Run the bootstrap for a repository owned by a GitHub organization:

```sh
flux bootstrap github \
  --owner=my-github-organization \
  --repository=my-repository \
  --team=team1-slug \
  --team=team2-slug \
  --path=clusters/my-cluster
```

When you specify a list of teams, those teams will be granted maintainer access to the repository.

To run the bootstrap for a repository hosted on GitHub Enterprise, you have to specify your GitHub hostname:

```sh
flux bootstrap github \
  --hostname=my-github-enterprise.com \
  --ssh-hostname=my-github-enterprise.com \
  --owner=my-github-organization \
  --repository=my-repository \
  --branch=main \
  --path=clusters/my-cluster
```

If your GitHub Enterprise has SSH access disabled, you can use HTTPS and token authentication with:

```sh
flux bootstrap github \
  --token-auth \
  --hostname=my-github-enterprise.com \
  --owner=my-github-organization \
  --repository=my-repository \
  --branch=main \
  --path=clusters/my-cluster
```
