---
title: "SPIFFE Workload API"
linkTitle: "SPIFFE"
description: "How to configure the SPIFFE Workload API for Flux controllers"
weight: 16
---

The SPIFFE Workload API provides the Flux controllers with their X509-SVID,
which is used directly for
[inter-controller mTLS](/flux/installation/configuration/intercontroller-mtls/)
and to authenticate to the SPIFFE Broker API when using the `spiffe` credential
provider for
[object identity](/flux/installation/configuration/object-identity/#spiffe).

## Prerequisites

The SPIFFE runtime must be deployed before Flux. `flux bootstrap` does not
install these prerequisites. Use a bootstrap mechanism that supports them,
for example the
[Flux Operator Bootstrap Terraform module](https://github.com/controlplaneio-fluxcd/terraform-kubernetes-flux-operator-bootstrap).

## Configuration

The controller must be configured with the SPIFFE Workload API endpoint via the
go-spiffe environment variable `SPIFFE_ENDPOINT_SOCKET`.

The SPIFFE Workload API socket must be made available to the Flux controllers.
For example, you can mount it using the
[SPIFFE CSI Driver](https://github.com/spiffe/spiffe-csi). Other mechanisms for
exposing the Workload API socket to the controller pods can also be used, as long
as the socket is available at the path referenced by `SPIFFE_ENDPOINT_SOCKET`.

The following patch is an example that uses the SPIFFE CSI Driver:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - target:
      kind: Deployment
      name: "(source-controller|kustomize-controller|helm-controller|notification-controller|image-reflector-controller|image-automation-controller|source-watcher)"
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: SPIFFE_ENDPOINT_SOCKET
          value: unix:///spiffe-workload-api/<socket path>
      - op: add
        path: /spec/template/spec/volumes/-
        value:
          name: spiffe-workload-api
          csi:
            driver: csi.spiffe.io
            readOnly: true
      - op: add
        path: /spec/template/spec/containers/0/volumeMounts/-
        value:
          name: spiffe-workload-api
          mountPath: /spiffe-workload-api
          readOnly: true
```
