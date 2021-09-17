---
title: "Uninstall Flux"
weight: 530
---

## Run the uninstall command

Use the ``flux uninstall`` command:

```bash
flux uninstall --namespace=flux-system
```

{{% note %}}
`flux uninstall` will not remove any Kubernetes objects
or Helm releases that were reconciled on the cluster by Flux.
It is safe to uninstall Flux and rerun the bootstrap, any existing workloads
will not be affected.
{{% /note %}}

The above command performs the following operations:

- deletes Flux components (deployments and services)
- deletes Flux network policies
- deletes Flux RBAC (service accounts, cluster roles and cluster role bindings)
- removes the Kubernetes finalizers from Flux custom resources
- deletes Flux custom resource definitions and custom resources
- deletes the namespace where Flux was installed

If you've installed Flux in a namespace that you wish to preserve, you
can skip the namespace deletion with:

```bash
flux uninstall --namespace=infra --keep-namespace
```


