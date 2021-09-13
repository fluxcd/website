---
title: "Terraform"
date: 2021-09-12T23:51:42+01:00
draft: true
---

## Update the Flux Provider

Update the Flux provider to the [latest release](https://github.com/fluxcd/terraform-provider-flux/releases)
and run `terraform apply`.

### Tell flux to upgrade itself

Tell Flux to upgrade itself in-cluster or wait for it to pull the latest commit from Git:

```bash
kubectl annotate --overwrite gitrepository/flux-system reconcile.fluxcd.io/requestedAt="$(date +%s)"
```
