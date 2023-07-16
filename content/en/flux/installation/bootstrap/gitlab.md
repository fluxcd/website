---
title: GitLab
linkTitle: GitLab
description: "GitLab installation method"
weight: 30
---

### GitLab and GitLab Enterprise

The `bootstrap gitlab` command creates a GitLab repository if one doesn't exist and
commits the Flux components manifests to specified branch. Then it
configures the target cluster to synchronize with that repository by
setting up an SSH deploy key or by using token-based authentication.

Generate a [personal access token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)
that grants complete read/write access to the GitLab API.

Export your GitLab personal access token as an environment variable:

```sh
export GITLAB_TOKEN=<your-token>
```

Run the bootstrap for a repository on your personal GitLab account:

```sh
flux bootstrap gitlab \
  --owner=my-gitlab-username \
  --repository=my-repository \
  --branch=master \
  --path=clusters/my-cluster \
  --token-auth \
  --personal
```

To use a [GitLab deploy token](https://docs.gitlab.com/ee/user/project/deploy_tokens/) instead of your personal access token
or an SSH deploy key, you can specify the `--deploy-token-auth` option:

```sh
flux bootstrap gitlab \
  --owner=my-gitlab-username \
  --repository=my-repository \
  --branch=master \
  --path=clusters/my-cluster \
  --deploy-token-auth
```

To run the bootstrap for a repository using deploy keys for authentication, you have to specify the SSH hostname:

```sh
flux bootstrap gitlab \
  --ssh-hostname=gitlab.com \
  --owner=my-gitlab-username \
  --repository=my-repository \
  --branch=master \
  --path=clusters/my-cluster
```

{{% alert color="info" title="Authentication" %}}
When providing the `--ssh-hostname`, a read-only (SSH) deploy key will be added
to your repository, otherwise your GitLab personal token will be used to
authenticate against the HTTPS endpoint instead.
{{% /alert %}}

Run the bootstrap for a repository owned by a GitLab (sub)group:

```sh
flux bootstrap gitlab \
  --owner=my-gitlab-group/my-gitlab-subgroup \
  --repository=my-repository \
  --branch=master \
  --path=clusters/my-cluster
```

To run the bootstrap for a repository hosted on GitLab on-prem or enterprise, you have to specify your GitLab hostname:

```sh
flux bootstrap gitlab \
  --hostname=my-gitlab.com \
  --token-auth \
  --owner=my-gitlab-group \
  --repository=my-repository \
  --branch=master \
  --path=clusters/my-cluster
```
