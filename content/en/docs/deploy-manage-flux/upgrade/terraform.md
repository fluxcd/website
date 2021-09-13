---
title: "Upgrade Flux using the Terraform provider"
linkTitle: "With the Terraform Provider"
---

## Update the Flux Provider

Update the Flux provider to the [latest release](https://github.com/fluxcd/terraform-provider-flux/releases)
and run `terraform apply`.

### Tell flux to upgrade itself

Tell Flux to upgrade itself in-cluster or wait for it to pull the latest commit from Git:

```bash
kubectl annotate --overwrite gitrepository/flux-system reconcile.fluxcd.io/requestedAt="$(date +%s)"
```
