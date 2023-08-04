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

First allow Flux controllers to run as non-root:

```shell
#!/usr/bin/env bash
set -e

FLUX_NAMESPACE="flux-system"
FLUX_CONTROLLERS=(
"source-controller"
"kustomize-controller"
"helm-controller"
"notification-controller"
"image-reflector-controller"
"image-automation-controller"
)

for i in ${!FLUX_CONTROLLERS[@]}; do
  oc adm policy add-scc-to-user nonroot system:serviceaccount:${FLUX_NAMESPACE}:${FLUX_CONTROLLERS[$i]}
done
```

Then add the following patches to the flux-system `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: all
      spec:
        template:
          spec:
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
