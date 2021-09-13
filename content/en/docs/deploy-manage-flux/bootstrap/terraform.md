---
title: "Bootstrap Flux using the Flux Terraform provider"
description: Use the Terraform provider for Flux
linkTitle: Terraform Provider
---

You can bootstrap Flux with Terraform using the Flux provider published on
[registry.terraform.io](https://registry.terraform.io/providers/fluxcd/flux).

The provider consists of two data sources (`flux_install` and `flux_sync`) for generating the
Kubernetes manifests that can be used to install or upgrade Flux:

```terraform
data "flux_install" "main" {
  target_path    = "clusters/my-cluster"
  network_policy = false
  version        = "latest"
}

data "flux_sync" "main" {
  target_path = "clusters/my-cluster"
  url         = "<https://github.com/${var.github_owner}/${var.repository_name}>"
  branch      = "main"
}
```

For more details on how to use the Terraform provider
please see [fluxcd/terraform-provider-flux](https://github.com/fluxcd/terraform-provider-flux).
