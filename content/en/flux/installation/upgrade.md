---
title: Flux upgrade
linkTitle: Upgrade
description: "Upgrade the Flux CLI and controllers"
weight: 40
---

Flux can be upgrade from any `v2.x` release to any other `v2.x` release (the latest patch version).
For more details about supported versions and upgrades please see the Flux [release documentation](/flux/releases/).

## Flux CLI upgrade

Running `flux check --pre` will tell you if a newer Flux version is available.

Update the Flux CLI to the latest release using a [package manager](/flux/installation/) or by
downloading the binary from [GitHub releases](https://github.com/fluxcd/flux2/releases).

Verify that you are running the latest version with:

```sh
flux --version
```

## Flux controllers upgrade

The Flux controllers have the capability to upgrade themselves if they were installed using the
[bootstrap procedure](flux/installation/bootstrap/).

### Upgrade with Git

To upgrade the Flux controllers with Git, you can generate the new Kubernetes manifests using the
Flux CLI and push them to the Git repository where bootstrap was run.

Note that this procedure **does not require direct access** to the Kubernetes cluster where Flux is installed.

Assuming you've bootstrapped with `--path=/clusters/my-cluster`, you can update the manifests in Git with:

```shell
git clone https://<git-host>/<org>/<bootstrap-repo>
cd <bootstrap-repo>
flux install --export > ./clusters/my-cluster/flux-system/gotk-components.yaml
git add -A && git commit -m "Update $(flux -v) on my-cluster"
git push
```

If you've enabled extra Flux components at bootstrap,
like those required for the [image automation feature](/flux/guides/image-update/).
Ensure to include these components when generating the components manifest:

```shell
flux install \
--components-extra image-reflector-controller,image-automation-controller \
--export > ./clusters/my-cluster/flux-system/gotk-components.yaml
```

Wait for Flux to detect the changes or, tell it to do the upgrade immediately with:

```sh
flux reconcile ks flux-system --with-source
```

{{% alert color="info" title="Automated upgrades" %}}
You can automate the components manifest update with GitHub Actions
and open a PR when there is a new Flux version available.
For more details please see [Flux GitHub Action docs](/flux/flux-gh-action.md).
{{% /alert %}}

### Upgrade with Flux CLI

If you've used the [bootstrap](/flux/installation/bootstrap/) procedure to deploy Flux,
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

Verify that the controllers have been upgrade with:

```sh
flux check
```

### Upgrade with Terraform

If you've used the [Terraform Provider](https://github.com/fluxcd/terraform-provider-flux/) to bootstrap Flux,
then update the provider to the [latest version](https://github.com/fluxcd/terraform-provider-flux/releases)
and run `terraform apply`.

The upgrade performed with Terraform behaves in the same way as the [upgrade with Flux CLI](#upgrade-with-flux-cli).

### Upgrade with kubectl

If you've installed Flux directly on the cluster with kubectl,
then rerun the command using the latest manifests from GitHub releases page:

```sh
kubectl apply --server-side -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml
```
