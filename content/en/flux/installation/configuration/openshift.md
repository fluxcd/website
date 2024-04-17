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
