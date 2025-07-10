---
title: "Flux OpenShift installation"
linkTitle: "OpenShift installation"
description: "How to configure Flux for OpenShift"
weight: 15
---

{{% alert color="danger" title="Required permissions" %}}
To bootstrap Flux, the person running the command must have **cluster admin rights** for the target OpenShift cluster.
It is also required to prepare a Git repository as described in the [bootstrap customization](boostrap-customization.md).
{{% /alert %}}

First copy the [scc.yaml](https://raw.githubusercontent.com/fluxcd/flux2/main/manifests/openshift/scc.yaml) 
to the `flux-system` directory. This manifest contains the RBAC necessary to allow the Flux controllers
to run as non-root on OpenShift.

Then add the `scc.yaml` and the following patches to the flux-system `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
  - scc.yaml
patches:
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: all
      spec:
        template:
          spec:
            securityContext:
              $patch: delete
            containers:
              - name: manager
                securityContext:
                  runAsUser: 65534
                  seccompProfile:
                    $patch: delete
    target:
      kind: Deployment
      labelSelector: app.kubernetes.io/part-of=flux
  - patch: |-
      - op: remove
        path: /metadata/labels/pod-security.kubernetes.io~1warn
      - op: remove
        path: /metadata/labels/pod-security.kubernetes.io~1warn-version
    target:
      kind: Namespace
      labelSelector: app.kubernetes.io/part-of=flux
```

Finally, push the changes to the Git repository and run [flux bootstrap](/flux/installation#bootstrap-with-flux-cli).

## OperatorHub

Flux can be installed on Red Hat OpenShift cluster directly
from [OperatorHub](https://operatorhub.io/operator/flux-operator) using Flux Operator.

The [Flux Operator](https://github.com/controlplaneio-fluxcd/flux-operator) is an open-source project
part of the [Flux ecosystem](/ecosystem/#flux-extensions) that provides a declarative API for the
lifecycle management of the Flux controllers on OpenShift.

First create a `Subscription` resource in the `flux-system` namespace to install the Flux Operator:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: flux-operator
  namespace: flux-system
spec:
  channel: stable
  name: flux-operator
  source: operatorhubio-catalog
  sourceNamespace: olm
  config:
    env:
      - name: DEFAULT_SERVICE_ACCOUNT
        value: "flux-operator"
```

After the subscription, create a `FluxInstance` resource with `.spec.cluster.type` set to `openshift`:

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: FluxInstance
metadata:
  name: flux
  namespace: flux-system
  annotations:
    fluxcd.controlplane.io/reconcileEvery: "1h"
spec:
  distribution:
    version: "2.x"
    registry: "ghcr.io/fluxcd"
  components:
    - source-controller
    - kustomize-controller
    - helm-controller
    - notification-controller
    - image-reflector-controller
    - image-automation-controller
  cluster:
    type: openshift
    multitenant: true
    networkPolicy: true
    domain: "cluster.local"
  sync:
    kind: GitRepository
    url: "https://my-git-server.com/my-org/my-fleet.git"
    ref: "refs/heads/main"
    path: "clusters/my-cluster"
    pullSecret: "flux-system"
```

For more information on how to configure the Flux instance, refer to the following resources:

- [Flux controllers configuration](https://fluxcd.control-plane.io/operator/flux-config/)
- [Flux instance customization](https://fluxcd.control-plane.io/operator/flux-kustomize/)
- [Cluster sync configuration](https://fluxcd.control-plane.io/operator/flux-sync/)
- [Flux controllers sharding](https://fluxcd.control-plane.io/operator/flux-sharding/)
- [Flux monitoring and reporting](https://fluxcd.control-plane.io/operator/monitoring/)
- [Using ResourceSets for Application Definitions](https://fluxcd.control-plane.io/operator/resourcesets/app-definition/)
