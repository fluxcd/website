---
title: "Installation"
description: "Flux install, bootstrap, upgrade and uninstall documentation."
weight: 30
---

This guide walks you through setting up Flux to
manage one or more Kubernetes clusters.

## Prerequisites

You will need a Kubernetes cluster that matches one of the following versions:

| Kubernetes version | Minimum required |
|--------------------|------------------|
| `v1.24`            | `>= 1.24.0`      |
| `v1.25`            | `>= 1.25.0`      |
| `v1.26`            | `>= 1.26.0`      |
| `v1.27` and later  | `>= 1.27.1`      |

{{% alert color="info" title="Kubernetes EOL" %}}
Note that Flux may work on older versions of Kubernetes e.g. 1.19,
but we don't recommend running [EOL versions](https://endoflife.date/kubernetes)
in production nor do we offer support for these versions.
{{% /alert %}}

## Install the Flux CLI

The Flux CLI is available as a binary executable for all major platforms,
the binaries can be downloaded from GitHub
[releases page](https://github.com/fluxcd/flux2/releases).

{{< tabpane text=true >}}
{{% tab header="Homebrew" %}}

With [Homebrew](https://brew.sh) for macOS and Linux:

```sh
brew install fluxcd/tap/flux
```

{{% /tab %}}
{{% tab header="bash" %}}

With [Bash](https://www.gnu.org/software/bash/) for macOS and Linux:

```sh
curl -s https://fluxcd.io/install.sh | sudo bash
```

{{% /tab %}}
{{% tab header="yay" %}}

With [yay](https://github.com/Jguer/yay) (or another [AUR helper](https://wiki.archlinux.org/title/AUR_helpers)) for Arch Linux:

```sh
yay -S flux-bin
```

{{% /tab %}}
{{% tab header="nix" %}}

With [nix-env](https://nixos.org/manual/nix/unstable/command-ref/nix-env.html) for NixOS:

```sh
nix-env -i fluxcd
```

{{% /tab %}}
{{% tab header="Chocolatey" %}}

With [Chocolatey](https://chocolatey.org/) for Windows:

```powershell
choco install flux
```

{{% /tab %}}
{{< /tabpane >}}

To configure your shell to load `flux` [bash completions](./cmd/flux_completion_bash.md) add to your profile:

```sh
. <(flux completion bash)
```

[`zsh`](./cmd/flux_completion_zsh.md), [`fish`](./cmd/flux_completion_fish.md),
and [`powershell`](./cmd/flux_completion_powershell.md)
are also supported with their own sub-commands.

A container image with `kubectl` and `flux` is available on DockerHub and GitHub:

* `docker.io/fluxcd/flux-cli:<version>`
* `ghcr.io/fluxcd/flux-cli:<version>`

## Bootstrap

Using the `flux bootstrap` command you can install Flux on a
Kubernetes cluster and configure it to manage itself from a Git
repository.

If the Flux components are present on the cluster, the bootstrap
command will perform an upgrade if needed. The bootstrap is
idempotent, it's safe to run the command as many times as you want.

The Flux component images are published to DockerHub and GitHub Container Registry
as [multi-arch container images](https://docs.docker.com/docker-for-mac/multi-arch/)
with support for Linux `amd64`, `arm64` and `armv7` (e.g. 32bit Raspberry Pi)
architectures.

If your Git provider is **AWS CodeCommit**, **Azure DevOps**, **Bitbucket Server**, **GitHub** or **GitLab** please
follow the specific bootstrap procedure:

* [AWS CodeCommit](./use-cases/aws-codecommit.md#flux-installation-for-aws-codecommit)
* [Azure DevOps](./use-cases/azure.md#flux-installation-for-azure-devops)
* [Bitbucket Server and Data Center](#bitbucket-server-and-data-center)
* [GitHub.com and GitHub Enterprise](#github-and-github-enterprise)
* [GitLab.com and GitLab Enterprise](#gitlab-and-gitlab-enterprise)

### Generic Git Server

The `bootstrap git` command takes an existing Git repository, clones it and
commits the Flux components manifests to the specified branch. Then it
configures the target cluster to synchronize with that repository.

{{% alert color="warning" %}}
:warning: Note that if set, your SSH hostname and port could be overwritten by your [ssh_config](https://linux.die.net/man/5/ssh_config).
{{% /alert %}}

Run bootstrap for a Git repository and authenticate with your SSH agent:

```sh
flux bootstrap git \
  --url=ssh://git@<host>/<org>/<repository> \
  --branch=<my-branch> \
  --path=clusters/my-cluster
```

The above command will generate an SSH key (defaults to ECDSA P-384 but can be changed with `--ssh-key-algorithm` and 
`--ssh-ecdsa-curve`), and it will prompt you to add the SSH public key as a deploy key to your repository.

If you want to use your own SSH key, you can provide a private key using
`--private-key-file=<path/to/private.key>` (you can supply the passphrase with `--password=<key-passphrase>`).
This option can also be used if no SSH agent is available on your machine.

{{% alert color="info" title="Bootstrap options" %}}
There are many options available when bootstrapping Flux, such as installing a subset of Flux components,
setting the Kubernetes context, changing the Git author name and email, enabling Git submodules, and more.
To list all the available options run `flux bootstrap git --help`.
{{% /alert %}}

If your Git server doesn't support SSH, you can run bootstrap for Git over HTTPS:

```sh
flux bootstrap git \
  --url=https://<host>/<org>/<repository> \
  --username=<my-username> \
  --password=<my-password> \
  --token-auth=true \
  --path=clusters/my-cluster
```

If your Git server uses a self-signed TLS certificate, you can specify the CA file with
`--ca-file=<path/to/ca.crt>`.

With `--path` you can configure the directory which will be used to reconcile the target cluster.
To control multiple clusters from the same Git repository, you have to set a unique path per
cluster e.g. `clusters/staging` and `clusters/production`:

```sh
./clusters/
├── staging # <- path=clusters/staging
│   └── flux-system # <- namespace dir generated by bootstrap
│       ├── gotk-components.yaml
│       ├── gotk-sync.yaml
│       └── kustomization.yaml
└── production # <- path=clusters/production
    └── flux-system
```

After running bootstrap you can place Kubernetes YAMLs inside a dir under path
e.g. `clusters/staging/my-app`, and Flux will reconcile them on your cluster.

For examples on how you can structure your Git repository see:

* [flux2-kustomize-helm-example](https://github.com/fluxcd/flux2-kustomize-helm-example)
* [flux2-multi-tenancy](https://github.com/fluxcd/flux2-multi-tenancy)

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

### Air-gapped Environments

To bootstrap Flux on air-gapped environments without access to github.com and ghcr.io, first you'll need 
to download the `flux` binary, and the container images from a computer with access to internet.

List all container images:

```sh
$ flux install --export | grep ghcr.io

image: ghcr.io/fluxcd/helm-controller:v2.0.0-rc.4
image: ghcr.io/fluxcd/kustomize-controller:v2.0.0-rc.4
image: ghcr.io/fluxcd/notification-controller:v2.0.0-rc.4
image: ghcr.io/fluxcd/source-controller:v2.0.0-rc.4
```

Pull the images locally and push them to your container registry:

```sh
docker pull ghcr.io/fluxcd/source-controller:v2.0.0-rc.4
docker tag ghcr.io/fluxcd/source-controller:v2.0.0-rc.4 registry.internal/fluxcd/source-controller:v2.0.0-rc.4
docker push registry.internal/fluxcd/source-controller:v2.0.0-rc.4
```

Copy `flux` binary to a computer with access to your air-gapped cluster,
and create the pull secret in the `flux-system` namespace:

```sh
kubectl create ns flux-system

kubectl -n flux-system create secret generic regcred \
    --from-file=.dockerconfigjson=/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
```

Finally, bootstrap Flux using the images from your private registry:

```sh
flux bootstrap <GIT-PROVIDER> \
  --registry=registry.internal/fluxcd \
  --image-pull-secret=regcred \
  --hostname=my-git-server.internal
```

Note that when running `flux bootstrap` without specifying a `--version`,
the CLI will use the manifests embedded in its binary instead of downloading
them from GitHub. You can determine which version you'll be installing,
with `flux --version`.

## Bootstrap with Terraform

The bootstrap procedure can be implemented with Terraform using the Flux provider published on
[registry.terraform.io](https://registry.terraform.io/providers/fluxcd/flux).
The provider offers a Terraform resource called
[flux_bootstrap_git](https://registry.terraform.io/providers/fluxcd/flux/latest/docs/resources/bootstrap_git)
that can be used to bootstrap Flux in the same way the Flux CLI does it.

Example of Git HTTPS bootstrap:

```hcl
provider "flux" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
  git = {
    url  = var.gitlab_url
    http = {
      username = var.gitlab_user
      password = var.gitlab_token
    }
  }
}

resource "flux_bootstrap_git" "this" {
  path                   = "clusters/my-cluster"
  network_policy         = true
  kustomization_override = file("${path.module}/kustomization.yaml")
}
```

For more details on how to use the Terraform provider
please see the [Flux docs on registry.terraform.io](https://registry.terraform.io/providers/fluxcd/flux/latest/docs).

## Customize Flux manifests

You can customize the Flux components before or after running bootstrap.

Assuming you want to customise the Flux controllers before they get deployed on the cluster,
first you'll need to create a Git repository and clone it locally.

Create the file structure required by bootstrap with:

```sh
mkdir -p clusters/my-cluster/flux-system
touch clusters/my-cluster/flux-system/gotk-components.yaml \
    clusters/my-cluster/flux-system/gotk-sync.yaml \
    clusters/my-cluster/flux-system/kustomization.yaml
```

Add patches to `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1
kind: Kustomization
resources: # manifests generated during bootstrap
  - gotk-components.yaml
  - gotk-sync.yaml

patches: # customize the manifests during bootstrap
  - target:
      kind: Deployment
      labelSelector: app.kubernetes.io/part-of=flux
    patch: |
      # strategic merge or JSON patch
```

Push the changes to main branch:

```sh
git add -A && git commit -m "init flux" && git push
```

And run the bootstrap for `clusters/my-cluster`:

```sh
flux bootstrap git \
  --url=ssh://git@<host>/<org>/<repository> \
  --branch=main \
  --path=clusters/my-cluster
```

To make further amendments, pull the changes locally,
edit the `kustomization.yaml` file, push the changes upstream
and rerun bootstrap or let Flux upgrade itself.

Checkout the [bootstrap cheatsheet](cheatsheets/bootstrap.md) for various examples of how to customize Flux.

### Multi-tenancy lockdown

Assuming you want to lock down Flux on multi-tenant clusters,
add the following patches to `clusters/my-cluster/flux-system/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/0
        value: --no-cross-namespace-refs=true
    target:
      kind: Deployment
      name: "(kustomize-controller|helm-controller|notification-controller|image-reflector-controller|image-automation-controller)"
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --no-remote-bases=true
    target:
      kind: Deployment
      name: "kustomize-controller"
  - patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/0
        value: --default-service-account=default
    target:
      kind: Deployment
      name: "(kustomize-controller|helm-controller)"
  - patch: |
      - op: add
        path: /spec/serviceAccountName
        value: kustomize-controller
    target:
      kind: Kustomization
      name: "flux-system"
```

With the above configuration, Flux will:

- Deny cross-namespace access to Flux custom resources, thus ensuring that a tenant can't use another tenant's sources or subscribe to their events.
- Deny accesses to Kustomize remote bases, thus ensuring all resources refer to local files, meaning only the Flux Sources can affect the cluster-state.
- All `Kustomizations` and `HelmReleases` which don't have `spec.serviceAccountName` specified, will use the `default` account from the tenant's namespace.
  Tenants have to specify a service account in their Flux resources to be able to deploy workloads in their namespaces as the `default` account has no permissions.
- The flux-system `Kustomization` is set to reconcile under a service account with cluster-admin role,
  allowing platform admins to configure cluster-wide resources and provision the tenant's namespaces, service accounts and RBAC.

To apply these patches, push the changes to the main branch and run `flux bootstrap`.

## Dev install

For testing purposes you can install Flux without storing its manifests in a Git repository:

```sh
flux install
```

Or using kubectl:

```sh
kubectl apply -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml
```

Then you can register Git repositories and reconcile them on your cluster:

```sh
flux create source git podinfo \
  --url=https://github.com/stefanprodan/podinfo \
  --tag-semver=">=4.0.0" \
  --interval=1m

flux create kustomization podinfo-default \
  --source=podinfo \
  --path="./kustomize" \
  --prune=true \
  --validation=client \
  --interval=10m \
  --health-check="Deployment/podinfo.default" \
  --health-check-timeout=2m \
  --target-namespace=default
```

You can register Helm repositories and create Helm releases:

```sh
flux create source helm bitnami \
  --interval=1h \
  --url=https://charts.bitnami.com/bitnami

flux create helmrelease nginx \
  --interval=1h \
  --release-name=nginx-ingress-controller \
  --target-namespace=kube-system \
  --source=HelmRepository/bitnami \
  --chart=nginx-ingress-controller \
  --chart-version="5.x.x"
```

## Deploy key rotation

There are several reasons you may want to rotate the deploy key:

- The token used to generate the key has expired.
- The key has been compromised.
- You want to change the scope of the key, e.g. to allow write access using the `--read-write-key` flag to `flux bootstrap`.

While you can run `flux bootstrap` repeatedly, be aware that the `flux-system` Kubernetes Secret is never overwritten.
You need to manually rotate the key as described here.

To rotate the SSH key generated at bootstrap, first delete the secret from the cluster with:

```sh
kubectl -n flux-system delete secret flux-system
```

Then you have two alternatives to generate a new key:

1. Generate a new secret with

   ```sh
   flux create secret git flux-system \
     --url=ssh://git@<host>/<org>/<repository>
   ```
   The above command will print the SSH public key, once you set it as the deploy key,
   Flux will resume all operations.
2. Run `flux bootstrap ...` again. This will generate a new key pair and,
   depending on which Git provider you use, print the SSH public key that you then
   set as deploy key or automatically set the deploy key (e.g. with GitHub).

## Upgrade

{{% alert color="info" title="Patch versions" %}}
It is safe and advised to use the latest PATCH version when upgrading to a
new MINOR version.
{{% /alert %}}

Update Flux CLI to the latest release with `brew upgrade fluxcd/tap/flux` or by
downloading the binary from [GitHub](https://github.com/fluxcd/flux2/releases).

Verify that you are running the latest version with:

```sh
flux --version
```

### Bootstrap upgrade

If you've used the [bootstrap](#bootstrap) procedure to deploy Flux,
then rerun the bootstrap command for each cluster using the same arguments as before:

```sh
flux bootstrap github \
  --owner=my-github-username \
  --repository=my-repository \
  --branch=main \
  --path=clusters/my-cluster \
  --personal
```

The above command will clone the repository, it will update the components manifest in
`<path>/flux-system/gotk-components.yaml` and it will push the changes to the remote branch.

Tell Flux to pull the manifests from Git and upgrade itself with:

```sh
flux reconcile source git flux-system
```

Verify that the controllers have been upgrade with:

```sh
flux check
```

{{% alert color="info" title="Automated upgrades" %}}
You can automate the components manifest update with GitHub Actions
and open a PR when there is a new Flux version available.
For more details please see [Flux GitHub Action docs](/flux/flux-gh-action.md).
{{% /alert %}}

### Terraform upgrade

Update the Flux provider to the [latest release](https://github.com/fluxcd/terraform-provider-flux/releases)
and run `terraform apply`.

Tell Flux to upgrade itself in-cluster or wait for it to pull the latest commit from Git:

```sh
kubectl annotate --overwrite gitrepository/flux-system reconcile.fluxcd.io/requestedAt="$(date +%s)"
```

### In-cluster upgrade

If you've installed Flux directly on the cluster, then rerun the install command:

```sh
flux install
```

The above command will  apply the new manifests on your cluster.
You can verify that the controllers have been upgraded to the latest version with `flux check`.

If you've installed Flux directly on the cluster with kubectl,
then rerun the command using the latest manifests from the `main` branch:

```sh
kustomize build https://github.com/fluxcd/flux2/manifests/install?ref=main | kubectl apply -f-
```

## Uninstall

You can uninstall Flux with:

```sh
flux uninstall --namespace=flux-system
```

The above command performs the following operations:

- deletes Flux components (deployments and services)
- deletes Flux network policies
- deletes Flux RBAC (service accounts, cluster roles and cluster role bindings)
- removes the Kubernetes finalizers from Flux custom resources
- deletes Flux custom resource definitions and custom resources
- deletes the namespace where Flux was installed

If you've installed Flux in a namespace that you wish to preserve, you
can skip the namespace deletion with:

```sh
flux uninstall --namespace=infra --keep-namespace
```

{{% alert color="info" title="Reinstall" %}}
Note that the `uninstall` command will not remove any Kubernetes objects
or Helm releases that were reconciled on the cluster by Flux.
It is safe to uninstall Flux and rerun the bootstrap, any existing workloads
will not be affected.
{{% /alert %}}
