---
title: "ServiceAccount annotations"
linkTitle: "ServiceAccount annotations"
description: "Reference for the ServiceAccount annotations supported by Flux for object-level workload identity, SOPS transit engines, SPIFFE mTLS, and cloud provider authentication."
weight: 10
---

Flux controllers read authentication and mutual TLS settings from annotations
on Kubernetes ServiceAccount objects. The annotations are placed on the
ServiceAccount selected by the Flux object, for example `.spec.serviceAccountName`,
`.spec.decryption.serviceAccountName`, or `.data.serviceAccountName` in a
`.spec.kubeConfig.configMapRef` ConfigMap. Depending on the feature, this can
be an object-level ServiceAccount or the controller's own ServiceAccount.

The `credential.auth.fluxcd.io/provider` annotation selects how Flux acquires
the credential (`kubernetes` or `spiffe`), while the service provider selected
by the Flux object's `.spec.provider` field, or by `.data.provider` in a
`.spec.kubeConfig.configMapRef` ConfigMap, determines what the credential is
used for (`aws`, `azure`, `gcp`, `dockerhub`, or `generic`). The two are
independent: for example, an `OCIRepository` with `.spec.provider: aws` can use
either credential provider. For APIs without a provider field, such as SOPS
decryption, the service provider is inferred from the encrypted data.

> **Note**: The `x509` value for `credential.auth.fluxcd.io/type`, the
> `spiffe.mtls.fluxcd.io/server-ids` annotation, and the `dockerhub` service
> provider will be implemented in Flux 2.11 (Q1 2027). They are documented here
> to describe the API surface they will enable.

## Controller-level setup

Before using the features defined by the ServiceAccount annotations, ensure
that the controller is properly configured. The next sections describe the
setup required for each feature.

### Kubernetes TokenRequest API

The `kubernetes` credential provider requires the controller to have access to the
Kubernetes TokenRequest API to acquire JWTs for the ServiceAccount specified by
the Flux object. The required permission is the `create` verb on the
`serviceaccounts/token` resource granted by a ClusterRoleBinding. Example:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: flux-object-level-workload-identity
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
  name: flux-object-level-workload-identity
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flux-object-level-workload-identity
subjects:
  - kind: ServiceAccount
    name: source-controller
    namespace: flux-system
```

### SPIFFE

The `spiffe` credential provider and the `spiffe.mtls.fluxcd.io` annotations will
require the controller to be configured with the SPIFFE Workload API endpoint via
the environment variable `SPIFFE_ENDPOINT_SOCKET`, the SPIFFE Broker API endpoint
via the flag `--spiffe-broker-endpoint`, and at least one authorized Broker SPIFFE
ID via the repeatable flag [`--spiffe-broker-id`](#spiffe-id-format). The Workload
API provides the controller's X509-SVID used to authenticate to the Broker API.

The SPIFFE Workload API socket can be mounted in the Flux controllers using the
[SPIFFE CSI Driver](https://github.com/spiffe/spiffe-csi). The controller patch
should look like this (make sure to replace the `<...>` placeholders with your
actual values):

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

## Authentication annotations

The following sections describe the annotations used for authentication.

### Credential annotations

The `credential.auth.fluxcd.io` annotations configure how Flux acquires a
credential for the object. The `provider` and `type` annotations must always be
used together. When any `*.auth.fluxcd.io` annotation is present, the `provider`
and `type` annotations become mandatory as well.

#### `credential.auth.fluxcd.io/provider`

The credential provider that issues the credential.

- `kubernetes`: Flux acquires a JWT using the Kubernetes TokenRequest API. The
  identity associated with the credential is the Kubernetes ServiceAccount
  username, `system:serviceaccount:<namespace>:<name>`.
- `spiffe`: Flux acquires an SVID from the SPIFFE Broker API. The identity
  associated with the credential is a SPIFFE ID. The SPIFFE runtime, not Flux,
  decides which SPIFFE ID is issued for the Flux object.

The `kubernetes` provider supports only the `jwt` credential type.

#### `credential.auth.fluxcd.io/type`

The type of credential to acquire.

- `jwt`: Acquire a JSON Web Token.
- `x509`: Acquire an X.509 certificate. This value will be implemented in Flux
  2.11 (Q1 2027). It will be supported by the `aws` and `gcp` service providers
  only, and essentially enables AWS IAM Roles Anywhere and GCP Workload Identity
  Federation with X.509 certificates.

The `kubernetes` credential provider and the `azure` service provider support
only the `jwt` credential type.

#### `credential.auth.fluxcd.io/expiration`

An optional Go duration string specifying the requested expiration time of the
credential, for example `5m` or `1h`. It is supported only by the `kubernetes`
credential provider and controls the lifetime of the initial credential before
any exchange performed by the service provider. If omitted, the Kubernetes API
server default is used.

#### `credential.auth.fluxcd.io/audiences`

An optional list of audiences for the `jwt` credential type. The value is split
on commas and line breaks, whitespace is trimmed, and empty entries are ignored.
This annotation is rejected for the `dockerhub` service provider, which only
supports the fixed audience `https://identity.docker.com`, and for the GKE
built-in workload identity provider, which does not support custom audiences.
Set `gcp.auth.fluxcd.io/workload-identity-provider` when a custom audience is
required.

When omitted, the service provider determines the default audience. Cloud
providers have provider-specific defaults, while the `generic` provider uses
the address of the target service, such as an OCI registry host or a remote
Kubernetes API server.

#### `credential.auth.fluxcd.io/username`

An optional username to use when authenticating to the service. It is valid
only for the OCI APIs (`OCIRepository` and `ImageRepository`) with the
`generic` and `dockerhub` service providers. It is optional for `generic` and
mandatory for `dockerhub`.

For the `generic` service provider, the username controls how the credential is
presented to the registry:

- When `username` is set, Flux uses HTTP Basic authentication, with this value
  as the username and the acquired JWT or JWT-SVID as the password.
- When `username` is omitted, Flux sends the credential as a Bearer token in the
  `Authorization` header.

Docker Hub requires a username for its OIDC connection exchange and only
accepts the audience `https://identity.docker.com`.

### Transit engine annotations

The `transit-engine.auth.fluxcd.io` annotations configure authentication to an
OpenBao or Vault transit engine for SOPS decryption. They are read from the
ServiceAccount referenced by `.spec.decryption.serviceAccountName` and must be
used together. As with the other Flux-defined authentication annotations, using
them also requires `credential.auth.fluxcd.io/provider` and
`credential.auth.fluxcd.io/type` on the same ServiceAccount.

#### `transit-engine.auth.fluxcd.io/login-path`

The HTTP path in the transit engine where the login request must be sent, for
example `auth/jwt/login`.

#### `transit-engine.auth.fluxcd.io/role`

The transit engine role to use when authenticating. The role defines the rules
for matching credentials and the permissions granted to the authenticated
entity.

### Service provider annotations

The `{provider}.auth.fluxcd.io` annotations configure provider-specific
settings.

#### `aws.auth.fluxcd.io/sts-endpoint`

An optional AWS STS endpoint for the ServiceAccount. This annotation makes the
STS endpoint configurable for every AWS integration. It cannot be combined with
the legacy `Bucket.spec.sts.provider: aws` configuration; when opting into
object-level workload identity, set the STS endpoint with this annotation
instead of `Bucket.spec.sts.endpoint`.

#### `gcp.auth.fluxcd.io/workload-identity-provider`

The fully qualified GCP Workload Identity Provider resource name, for example:

```text
projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID
```

It is required outside GKE when using the `gcp` service provider, and for any
GCP integration using the `spiffe` credential provider. On GKE, the built-in
workload identity provider is used when this annotation is omitted.

#### `dockerhub.auth.fluxcd.io/oidc-connection-id`

The Docker Hub OIDC connection ID. This annotation is required for the
`dockerhub` service provider. Docker Hub only accepts the audience
`https://identity.docker.com`, so `credential.auth.fluxcd.io/audiences` cannot
be used with it.

> **Note**: The `dockerhub` service provider will be implemented in Flux 2.11
> (Q1 2027).

### External cloud provider annotations

Flux also supports the ServiceAccount annotations defined by the managed
Kubernetes providers. These annotations are not Flux-specific, but Flux reads
them for a consistent workload identity experience across managed and
self-hosted clusters. They can be used on an object-level ServiceAccount or on
the controller ServiceAccount for controller-level workload identity.

#### `eks.amazonaws.com/role-arn`

The ARN of the AWS IAM Role that the ServiceAccount assumes. This annotation is
required when using the `aws` service provider with object-level workload
identity.

#### `azure.workload.identity/tenant-id`

The Microsoft Entra tenant ID. This annotation is required when using the
`azure` service provider with object-level workload identity.

#### `azure.workload.identity/client-id`

The Microsoft Entra client ID of the managed identity. This annotation is
required when using the `azure` service provider with object-level workload
identity.

#### `iam.gke.io/gcp-service-account`

The email address of the GCP Service Account to impersonate. It is optional.
When omitted, the subject under the GCP Workload Identity Pool is the IAM
Principal to which GCP IAM Roles should be granted. See the
[GCP docs](./gcp.md#to-kubernetes-service-accounts) for more details.

## Mutual TLS annotations

The following sections describe the annotations used for mutual TLS (mTLS).

### SPIFFE mTLS annotations

The `spiffe.mtls.fluxcd.io` annotations specify the configuration for
mTLS provided by X509-SVIDs when Flux connects to an external service
described in a Flux objects.

#### `spiffe.mtls.fluxcd.io/server-ids`

An optional list of server SPIFFE IDs to authorize when connecting to the
service associated with the Flux object. This opts the connection into mTLS
backed by SPIFFE. The value is split on commas and line breaks, whitespace is
trimmed, and empty entries are ignored.

The annotation will be implemented in Flux 2.11 (Q1 2027). It will enable
SPIFFE mTLS for self-hosted infrastructure, including the `generic` service provider
in most Flux CRDs and GitHub Enterprise Server through the `github` provider in
`GitRepository` and the GitHub provider types in the notification-controller
`Provider` CRD. The public `aws`, `azure`, `gcp`, `dockerhub`, and GitHub.com
services do not support it.

Each entry uses the [SPIFFE ID format](#spiffe-id-format).

The mTLS annotations are independent of credential acquisition. On their own,
they do not require `credential.auth.fluxcd.io/provider` or
`credential.auth.fluxcd.io/type`. If any authentication annotation is present
alongside them, however, the credential provider and type must also be set.

The annotation is rejected when `.spec.certSecretRef` is set, or when
certificates or CAs come from `.spec.secretRef`.

## SPIFFE ID format

The `--spiffe-broker-id` controller flag and the
`spiffe.mtls.fluxcd.io/server-ids` annotation accept the same SPIFFE ID format.
The flag can be repeated, while the annotation value is split on commas and
line breaks.

Each value can be one of the following:

- `spiffe://<trust domain>` to authorize any SPIFFE ID in the trust domain.
- `spiffe://<trust domain>/<path>` to authorize an exact SPIFFE ID.
- `spiffe://<trust domain>/<path>/` to authorize a SPIFFE ID prefix. The
  trailing slash identifies a prefix.
- `spiffe://self`, `spiffe://self/<path>`, or `spiffe://self/<path>/` to use
  the `self` trust domain, defined below.

For `--spiffe-broker-id`, `self` refers to the trust domain of the controller's
own X509-SVID. For `spiffe.mtls.fluxcd.io/server-ids`, `self` refers to the
trust domain of the Flux object's X509-SVID, acquired through the SPIFFE Broker
API.

## Migration notes

The annotation-based API cannot be combined with the following legacy
configuration:

- A `kubeConfig` ConfigMap with an `audiences` key. Use
  `credential.auth.fluxcd.io/audiences` instead.
- The `--sops-vault-configmap` controller flag. Use
  `transit-engine.auth.fluxcd.io/login-path` and
  `transit-engine.auth.fluxcd.io/role` instead.
- A `Bucket` with `.spec.sts.provider: aws`. Use
  `aws.auth.fluxcd.io/sts-endpoint` instead.

## Examples

Object-level Kubernetes JWT for an OCI registry:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tenant-a
  namespace: apps
  annotations:
    credential.auth.fluxcd.io/provider: kubernetes
    credential.auth.fluxcd.io/type: jwt
    credential.auth.fluxcd.io/audiences: registry.example.com
```

SPIFFE JWT-SVID with SOPS authentication to an OpenBao transit engine:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sops-decrypter
  namespace: apps
  annotations:
    credential.auth.fluxcd.io/provider: spiffe
    credential.auth.fluxcd.io/type: jwt
    credential.auth.fluxcd.io/audiences: https://openbao.example.com
    transit-engine.auth.fluxcd.io/login-path: auth/jwt/login
    transit-engine.auth.fluxcd.io/role: sops-spiffe
```

SPIFFE JWT for a remote Kubernetes cluster:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: remote-apps
  namespace: apps
spec:
  # ... other fields omitted for brevity
  kubeConfig:
    configMapRef:
      name: remote-cluster
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: remote-cluster
  namespace: apps
data:
  provider: generic
  serviceAccountName: remote-cluster-auth
  address: https://remote-cluster.example.com:6443
  ca.crt: |
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: remote-cluster-auth
  namespace: apps
  annotations:
    credential.auth.fluxcd.io/provider: spiffe
    credential.auth.fluxcd.io/type: jwt
    credential.auth.fluxcd.io/audiences: https://remote-cluster.example.com:6443
```

SPIFFE X.509 credentials for AWS IAM Roles Anywhere and GCP Workload Identity
Federation (planned for Flux 2.11):

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-tenant
  namespace: apps
  annotations:
    credential.auth.fluxcd.io/provider: spiffe
    credential.auth.fluxcd.io/type: x509
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/tenant-a
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gcp-tenant
  namespace: apps
  annotations:
    credential.auth.fluxcd.io/provider: spiffe
    credential.auth.fluxcd.io/type: x509
    gcp.auth.fluxcd.io/workload-identity-provider: projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID
```

Docker Hub OIDC connection (planned for Flux 2.11):

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dockerhub-tenant
  namespace: apps
  annotations:
    credential.auth.fluxcd.io/provider: spiffe
    credential.auth.fluxcd.io/type: jwt
    credential.auth.fluxcd.io/username: tenant-a
    dockerhub.auth.fluxcd.io/oidc-connection-id: OIDC_CONNECTION_ID
```

SPIFFE mTLS to a self-hosted service (planned for Flux 2.11):

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tenant-a
  namespace: apps
  annotations:
    spiffe.mtls.fluxcd.io/server-ids: spiffe://example.org/some-service
```
