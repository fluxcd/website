---
title: "Flux Inter-controller mTLS"
linkTitle: "Inter-controller mTLS"
description: "How to configure mTLS between Flux controllers using SPIFFE"
weight: 15
---

Flux controllers communicate with each other over HTTP to serve and fetch
artifacts and to send and receive events. The `notification-controller` also
receives webhooks through its receiver server, typically from an ingress or
gateway proxy. Inter-controller mTLS uses SPIFFE X509-SVIDs to encrypt the
traffic and authenticate both sides of these connections.

Each controller obtains its own X509-SVID from the SPIFFE Workload API. The
controller's own SVID is used for both client and server authentication.
Authorization is configured by adding flags with the SPIFFE IDs of the peers
that are allowed to connect.

The SPIFFE IDs accepted by these flags follow the format documented in the
[SPIFFE mTLS](/flux/integrations/spiffe-mtls/) page.

## Prerequisites

- Configure the SPIFFE Workload API for all controllers as described in
  [SPIFFE Workload API](/flux/installation/configuration/spiffe/).
- Run a SPIFFE runtime that issues X509-SVIDs to the Flux controller workloads.
- Know the SPIFFE IDs that your SPIFFE runtime assigns to the controllers. Flux
  does not derive these identities from Kubernetes ServiceAccounts. SPIFFE
  runtimes are free to model the workload identity as the workload itself, or to
  use any other mapping, so use the actual identities issued by your runtime in
  the authorization flags.

## Traffic types and flags

Inter-controller mTLS is enabled per traffic type. The presence of at least one
occurrence of a flag enables the corresponding feature in that controller. You
can protect only some types of traffic and leave the others on their existing
transport.

| Flag | Set on | Authorizes |
|------|--------|------------|
| `--authorized-artifact-client-spiffe-id` | `source-controller`, `source-watcher`, and external source controllers | Artifact clients: `kustomize-controller`, `helm-controller`, `source-watcher`, and external source controllers |
| `--authorized-artifact-server-spiffe-id` | `kustomize-controller`, `helm-controller`, and `source-watcher` | Artifact servers: `source-controller`, `source-watcher`, and external source controllers |
| `--authorized-notifier-spiffe-id` | `notification-controller` | Event senders: all other Flux controllers |
| `--authorized-event-server-spiffe-id` | All controllers except `notification-controller` | The `notification-controller` event server |
| `--authorized-receiver-spiffe-id` | `notification-controller` | The ingress or gateway controller that calls the receiver server |
| `--authorized-kube-apiserver-spiffe-id` | All controllers | The Kubernetes API server, when it serves an X509-SVID in the same trust domain |

All authorization flags are repeatable. The value is the SPIFFE ID of the peer,
not of the controller where the flag is set.

## Example configuration

The following bootstrap patch enables inter-controller mTLS for a Flux
installation in the `flux-system` namespace. Replace each controller SPIFFE ID
placeholder with the full identity issued by your SPIFFE runtime.

This example assumes that the SPIFFE Workload API is already configured as
described in [SPIFFE Workload API](/flux/installation/configuration/spiffe/).

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - target:
      kind: Deployment
      name: source-controller
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-artifact-client-spiffe-id=<kustomize-controller-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-artifact-client-spiffe-id=<helm-controller-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-artifact-client-spiffe-id=<source-watcher-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-event-server-spiffe-id=<notification-controller-spiffe-id>
  - target:
      kind: Deployment
      name: source-watcher
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-artifact-client-spiffe-id=<kustomize-controller-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-artifact-client-spiffe-id=<helm-controller-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-artifact-server-spiffe-id=<source-controller-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-event-server-spiffe-id=<notification-controller-spiffe-id>
  - target:
      kind: Deployment
      name: kustomize-controller
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-artifact-server-spiffe-id=<source-controller-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-artifact-server-spiffe-id=<source-watcher-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-event-server-spiffe-id=<notification-controller-spiffe-id>
  - target:
      kind: Deployment
      name: helm-controller
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-artifact-server-spiffe-id=<source-controller-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-artifact-server-spiffe-id=<source-watcher-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-event-server-spiffe-id=<notification-controller-spiffe-id>
  - target:
      kind: Deployment
      name: notification-controller
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-notifier-spiffe-id=<source-controller-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-notifier-spiffe-id=<source-watcher-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-notifier-spiffe-id=<kustomize-controller-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-notifier-spiffe-id=<helm-controller-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-notifier-spiffe-id=<image-reflector-controller-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-notifier-spiffe-id=<image-automation-controller-spiffe-id>
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-receiver-spiffe-id=<gateway-controller-spiffe-id>
  - target:
      kind: Deployment
      name: image-reflector-controller
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-event-server-spiffe-id=<notification-controller-spiffe-id>
  - target:
      kind: Deployment
      name: image-automation-controller
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --authorized-event-server-spiffe-id=<notification-controller-spiffe-id>
```

## Verifying

After the controllers restart, check their logs for the enabled traffic types:

```sh
kubectl -n flux-system logs deploy/source-controller
kubectl -n flux-system logs deploy/source-watcher
kubectl -n flux-system logs deploy/kustomize-controller
kubectl -n flux-system logs deploy/helm-controller
kubectl -n flux-system logs deploy/notification-controller
kubectl -n flux-system logs deploy/image-reflector-controller
kubectl -n flux-system logs deploy/image-automation-controller
```

Each controller logs a message for every traffic type it enables:

- `source-controller`:
  - `artifact server will use inter-controller mTLS via SPIFFE`
  - `event server will use inter-controller mTLS via SPIFFE`
- `source-watcher`:
  - `artifact server will use inter-controller mTLS via SPIFFE`
  - `artifact fetcher will use inter-controller mTLS via SPIFFE`
  - `event server will use inter-controller mTLS via SPIFFE`
- `kustomize-controller`:
  - `artifact fetcher will use inter-controller mTLS via SPIFFE`
  - `event server will use inter-controller mTLS via SPIFFE`
- `helm-controller`:
  - `artifact fetcher will use inter-controller mTLS via SPIFFE`
  - `event server will use inter-controller mTLS via SPIFFE`
- `notification-controller`:
  - `event server will use inter-controller mTLS via SPIFFE`
  - `receiver server will use inter-controller mTLS via SPIFFE`
- `image-reflector-controller`:
  - `event server will use inter-controller mTLS via SPIFFE`
- `image-automation-controller`:
  - `event server will use inter-controller mTLS via SPIFFE`
