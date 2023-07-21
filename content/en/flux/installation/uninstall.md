---
title: Flux uninstall
linkTitle: Uninstall
description: "How to uninstall the Flux controllers"
weight: 50
---

No matter which [installation](_index.md) method you've used to deploy the
Flux controllers on a cluster, you can uninstall them using the Flux CLI.

The uninstallation procedure removes only the Flux components, without touching
reconciled namespaces, tenants, cluster addons, workloads, Helm releases, etc.

Please note that uninstalling Flux by any other means e.g. deleting the deployments
and namespace with **kubectl is not supported**.

## Uninstall with Flux CLI

You can uninstall the Flux controllers running on a cluster with:

```sh
flux uninstall
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
flux uninstall --namespace=flux-system --keep-namespace
```

{{% alert color="info" title="Reinstall" %}}
Note that the `uninstall` command will not remove any Kubernetes objects
or Helm releases that were reconciled on the cluster by Flux.
It is safe to uninstall Flux and rerun the bootstrap, any existing workloads
will not be affected.
{{% /alert %}}
