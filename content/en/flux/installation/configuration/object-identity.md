---
title: "Flux Object Identity Installation"
linkTitle: "Object Identity"
description: "How to configure Flux controllers for object identity"
weight: 14
---

Before using the [object identity API](/flux/integrations/object-identity/),
ensure that the Flux controllers are properly configured. The next sections
describe the setup required for each credential provider.

## Kubernetes credential provider

The `kubernetes` credential provider requires the controller to have access to the
Kubernetes TokenRequest API to acquire JWTs for the ServiceAccount specified by
the Flux object. The required permission is the `create` verb on the
`serviceaccounts/token` resource granted by a ClusterRoleBinding.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: flux-object-identity
rules:
  - apiGroups:
      - ""
    resources:
      - serviceaccounts/token
    verbs:
      - create
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: flux-object-identity
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flux-object-identity
subjects:
  - kind: ServiceAccount
    name: source-controller
    namespace: flux-system
  - kind: ServiceAccount
    name: kustomize-controller
    namespace: flux-system
  - kind: ServiceAccount
    name: helm-controller
    namespace: flux-system
  - kind: ServiceAccount
    name: notification-controller
    namespace: flux-system
  - kind: ServiceAccount
    name: image-reflector-controller
    namespace: flux-system
  - kind: ServiceAccount
    name: image-automation-controller
    namespace: flux-system
```

## SPIFFE credential provider

The `spiffe` credential provider and the `spiffe.mtls.fluxcd.io` annotations will
require the controller to be configured with the
[SPIFFE Workload API](/flux/installation/configuration/spiffe/), the
SPIFFE Broker API endpoint via the flag `--spiffe-broker-endpoint`, and at
least one authorized Broker SPIFFE ID via the repeatable flag
`--spiffe-broker-id`, which follows the SPIFFE ID format documented in the
[SPIFFE mTLS](/flux/integrations/spiffe-mtls/) page.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - target:
      kind: Deployment
      name: "(source-controller|kustomize-controller|helm-controller|notification-controller|image-reflector-controller|image-automation-controller)"
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --spiffe-broker-endpoint=dns:///<svc name>.<svc namespace>.svc.cluster.local:443
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --spiffe-broker-id=spiffe://<trust domain>/<id path>
```

## Multi-tenancy lockdown

In multi-tenant clusters, platform admins must prevent tenants from using
[workload identity](/flux/installation/configuration/workload-identity/),
as that would give them access to the identity configured for the controller
to access external resources. This can be achieved by forcing the use of
object identity.

The following flags set a default ServiceAccount for object identity
authentication, which is used when a Flux object does not specify a
ServiceAccount:

- `--default-service-account` for `source-controller`, `notification-controller`,
  `image-reflector-controller`, and `image-automation-controller`. Default for the
  `.spec.serviceAccountName` field from the APIs of those controllers.
- `--default-kubeconfig-service-account` in `kustomize-controller` and
  `helm-controller` for applying resources to remote clusters. Default
  for the `.data.serviceAccountName` field in a ConfigMap pointed at
  by the field `.spec.kubeConfig.configMapRef` from the APIs of those
  controllers.
- `--default-decryption-service-account` in `kustomize-controller` for SOPS
  decryption. Default for `Kustomization.spec.decryption.serviceAccountName`.

The default ServiceAccount is looked up in the namespace of the Flux object.
The example below uses the `default` ServiceAccount, which exists in every
namespace and should not have any identity configured. As a result, tenants
must use object identity and explicitly set the ServiceAccount to use in the
Flux object.

The following patch enables the lockdown during bootstrap:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - target:
      kind: Deployment
      name: "(source-controller|notification-controller|image-reflector-controller|image-automation-controller)"
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --default-service-account=default
  - target:
      kind: Deployment
      name: "(kustomize-controller|helm-controller)"
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --default-kubeconfig-service-account=default
  - target:
      kind: Deployment
      name: "kustomize-controller"
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --default-decryption-service-account=default
```
