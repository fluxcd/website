---
title: Upgrade
linkTitle: Upgrade
description: "Upgrade Flux using bootstrap"
weight: 40
---

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

If you've used the [bootstrap](/flux/installation#bootstrap) procedure to deploy Flux,
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
