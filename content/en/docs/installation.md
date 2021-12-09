---
title: "Installation"
linkTitle: "Installation"
description: "Flux install, bootstrap, upgrade and uninstall documentation."
weight: 30
---

This guide walks you through setting up Flux to
manage one or more Kubernetes clusters.

## Prerequisites

You will need a Kubernetes cluster version **1.19** or newer.

Older versions are also supported, but we don't recommend running EOL Kubernetes versions in production:

| Kubernetes version | Minimum required\* |
| --- | --- |
| `v1.16` | `>= 1.16.11` |
| `v1.17` | `>= 1.17.7` |
| `v1.18` | `>= 1.18.4` |
| `v1.19` and later | `>= 1.19.0` |

*\* Update 2021-10-11:*

If you are using `APIService` objects (for example
[metrics-server](https://github.com/kubernetes-sigs/metrics-server)),
you will need to update to `1.18.18`, `1.19.10`, `1.20.6` or `1.21.0`
at least. See [this
post](https://github.com/fluxcd/flux2/discussions/1916#discussioncomment-1458041)
for more information.

## Install the Flux CLI

The Flux CLI is available as a binary executable for all major platforms,
the binaries can be downloaded form GitHub
[releases page](https://github.com/fluxcd/flux2/releases).

{{% tabs %}}
{{% tab "Homebrew" %}}

With [Homebrew](https://brew.sh) for macOS and Linux:

```sh
brew install fluxcd/tap/flux
```

{{% /tab %}}
{{% tab "GoFish" %}}

With [GoFish](https://gofi.sh) for Windows, macOS and Linux:

```sh
gofish install flux
```

{{% /tab %}}
{{% tab "bash" %}}

With [Bash](https://www.gnu.org/software/bash/) for macOS and Linux:

```sh
curl -s https://fluxcd.io/install.sh | sudo bash
```

{{% /tab %}}
{{% tab "yay" %}}

With [yay](https://github.com/Jguer/yay) (or another [AUR helper](https://wiki.archlinux.org/title/AUR_helpers)) for Arch Linux:

```sh
yay -S flux-bin
```

{{% /tab %}}
{{% tab "nix" %}}

With [nix-env](https://nixos.org/manual/nix/unstable/command-ref/nix-env.html) for NixOS:

```sh
nix-env -i fluxcd
```

{{% /tab %}}
{{%  tab "Chocolatey" %}}

With [Chocolatey](https://chocolatey.org/) for Windows:

```powershell
choco install flux
```

{{% /tab %}}
{{% /tabs %}}

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

Run bootstrap for a Git repository and authenticate with your SSH agent:

```sh
flux bootstrap git \
  --url=ssh://git@<host>/<org>/<repository> \
  --branch=<my-branch> \
  --path=clusters/my-cluster
```

The above command will generate an SSH key (defaults to RSA 2048 but can be changed with `--ssh-key-algorithm`),
and it will prompt you to add the SSH public key as a deploy key to your repository.

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

image: ghcr.io/fluxcd/helm-controller:v0.8.0
image: ghcr.io/fluxcd/kustomize-controller:v0.9.0
image: ghcr.io/fluxcd/notification-controller:v0.9.0
image: ghcr.io/fluxcd/source-controller:v0.9.0
```

Pull the images locally and push them to your container registry:

```sh
docker pull ghcr.io/fluxcd/source-controller:v0.9.0
docker tag ghcr.io/fluxcd/source-controller:v0.9.0 registry.internal/fluxcd/source-controller:v0.9.0
docker push registry.internal/fluxcd/source-controller:v0.9.0
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

The provider consists of two data sources (`flux_install` and `flux_sync`) for generating the
Kubernetes manifests that can be used to install or upgrade Flux:

```hcl
data "flux_install" "main" {
  target_path    = "clusters/my-cluster"
  network_policy = false
  version        = "latest"
}

data "flux_sync" "main" {
  target_path = "clusters/my-cluster"
  url         = "https://github.com/${var.github_owner}/${var.repository_name}"
  branch      = "main"
}
```

For more details on how to use the Terraform provider
please see [fluxcd/terraform-provider-flux](https://github.com/fluxcd/terraform-provider-flux).

## Customize Flux manifests

You can customize the Flux components before or after running bootstrap.

Assuming you want to customise the Flux controllers before they get deployed on the cluster,
first you'll need to create a Git repository and clone it locally.

Create the file structure required by bootstrap with:

```sh
mkdir -p clusters/my-cluster/flux-system
touch clusters/my-cluster/flux-system/gotk-components.yaml \
    clusters/my-cluster/flux-system/gotk-patches.yaml \
    clusters/my-cluster/flux-system/gotk-sync.yaml \
    clusters/my-cluster/flux-system/kustomization.yaml
```

Assuming you want to add custom annotations and labels to the Flux controllers,
edit `clusters/my-cluster/flux-system/gotk-patches.yaml` and set the metadata for source-controller and kustomize-controller pods:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: source-controller
  namespace: flux-system
spec:
  template:
    metadata:
      annotations:
        custom: annotation
      labels:
        custom: label
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kustomize-controller
  namespace: flux-system
spec:
  template:
    metadata:
      annotations:
        custom: annotation
      labels:
        custom: label
```

Edit `clusters/my-cluster/flux-system/kustomization.yaml` and set the resources and patches:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patchesStrategicMerge:
  - gotk-patches.yaml
```

Push the changes to main branch:

```sh
git add -A && git commit -m "add flux customisations" && git push
```

Now run the bootstrap for `clusters/my-cluster`:

```sh
flux bootstrap git \
  --url=ssh://git@<host>/<org>/<repository> \
  --branch=main \
  --path=clusters/my-cluster
```

When the controllers are deployed for the first time on your cluster, they will contain all
the customisations from `gotk-patches.yaml`.

You can make changes to the patches after bootstrap and Flux will apply them in-cluster on its own.

### Pod Security Policy

Assuming you want to make the Flux controllers conform to Pod Security Policy or equivalent webhooks,
create a file at `clusters/my-cluster/flux-system/psp-patch.yaml` with the following content:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: all-flux-components
spec:
  template:
    metadata:
      annotations:
        # Required by Kubernetes node autoscaler
        cluster-autoscaler.kubernetes.io/safe-to-evict: "true"
    spec:
      securityContext:
        runAsUser: 10000
        fsGroup: 1337
      containers:
        - name: manager
          securityContext:
            readOnlyRootFilesystem: true
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
```

Edit `clusters/my-cluster/flux-system/kustomization.yaml` and enable the patch:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- gotk-components.yaml
- gotk-sync.yaml
patches:
  - path: psp-patch.yaml
    target:
      kind: Deployment
```

Push the changes to the main branch and run `flux bootstrap`.

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
  --health-check-timeout=2m
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
For more details please see [Flux GitHub Action docs](https://github.com/fluxcd/flux2/tree/main/action).
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
It is safe to uninstall Flux and rerun the boostrap, any existing workloads
will not be affected.
{{% /alert %}}
