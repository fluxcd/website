---
title: "Flux optional components"
linkTitle: "Optional components"
description: "How to install Flux optional components"
weight: 2
---

The `flux bootstrap` command deploys a series of Kubernetes controllers along with their CRDs, RBAC
and network policies in the `flux-system` namespace.

## Default components

The default components are specified with the `--components` flag.

```shell
flux bootstrap git \
  --components source-controller,kustomize-controller,helm-controller,notification-controller
```

The minim required components for bootstrapping are `source-controller` and `kustomize-controller`.

When not specifying the `--components` flag, both `flux bootstrap` and `flux install` will
deploy the default components.

## Extra components

To enable the Flux [image automation feature](/flux/guides/image-update/), the extra components
can be specified with the `--components-extra` flag.

```shell
flux bootstrap git \
  --components-extra image-reflector-controller,image-automation-controller
```

By default, both `flux bootstrap` and `flux install` commands do not include any extra components.

## Network policies

Flux relies on Kubernetes network policies to ensure that only Flux components
have direct access to the source artifacts kept in the `source-controller`.

The default network policies block all ingress access to the `flux-system` namespace,
except for `notification-controller` webhook receiver.

While not recommend, you can deploy the Flux components without network policies
using the `--network-policy` flag.

```shell
flux bootstrap git \
  --network-policy false
```

## Cluster domain

The Flux components are communicating over HTTP with `source-controller` and `notification-controller`.
To reduce the DNS queries performed by each component, the cluster internal domain name is used to
compose the FQDN of each service e.g. `http://source-controller.flux-system.svc.cluster.local./`. 

The cluster domain name can be set using the `--cluster-domain` flag.

```shell
flux bootstrap git \
  --cluster-domain cluster.internal
```

When not specified, the cluster domain defaults to `cluster.local`.
