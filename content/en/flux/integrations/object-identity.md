---
title: "Flux Object Identity API"
linkTitle: "Object Identity"
description: "Reference for Object Identity in Flux, including the ServiceAccount annotations for SOPS transit engines, SPIFFE mTLS, and cloud provider authentication."
weight: 10
---

Flux controllers read authentication and mutual TLS settings from annotations
on Kubernetes ServiceAccount objects. The annotations are placed on the
ServiceAccount selected by the Flux object, for example `.spec.serviceAccountName`,
`.spec.decryption.serviceAccountName`, or `.data.serviceAccountName` in a
`.spec.kubeConfig.configMapRef` ConfigMap.

The `credential.auth.fluxcd.io/provider` annotation selects how Flux acquires
the credential (`kubernetes` or `spiffe`), while the service provider selected
by the Flux object's `.spec.provider` field, or by `.data.provider` in a
`.spec.kubeConfig.configMapRef` ConfigMap, determines what the credential is
used for (`aws`, `azure`, `gcp`, `dockerhub`, or `generic`). The two are
independent: for example, an `OCIRepository` with `.spec.provider: aws` can use
either credential provider. For APIs without a provider field, such as SOPS
decryption, the service provider is inferred from the encrypted data.

The `spiffe.mtls.fluxcd.io/server-ids` annotation specifies the SPIFFE IDs of
the servers that the Flux controller is allowed to connect over mTLS to when
reconciling the Flux object.

> **Note**: The `x509` value for `credential.auth.fluxcd.io/type`, the
> `spiffe.mtls.fluxcd.io/server-ids` annotation, and the `dockerhub` service
> provider will be implemented in Flux 2.11 (Q1 2027). They are documented here
> to describe the API surface they will enable.

## Prerequisites

For the controller-level setup required by the `kubernetes` and `spiffe`
credential providers, see the
[Object identity installation](/flux/installation/configuration/object-identity/).

## Configuring Flux resources

To use object identity, set the provider and the ServiceAccount fields in the
Flux resource:

- Set the `.spec.provider` field to the service provider, for example `aws`,
  `azure`, `gcp`, `dockerhub`, or `generic`.
- Set the `.spec.serviceAccountName` field to the name of the ServiceAccount in
  the same namespace as the Flux resource.

For remote cluster access with the `Kustomization` and `HelmRelease` APIs, set
the `.data.provider` field of the `ConfigMap` referenced by
`.spec.kubeConfig.configMapRef`, and set `.data.serviceAccountName` to the name
of the ServiceAccount in the same namespace as the Flux resource.

For SOPS decryption with the `Kustomization` API, there is no provider field,
as the provider is described in the SOPS metadata embedded in the encrypted
Secret. The ServiceAccount is set in `.spec.decryption.serviceAccountName`.

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
object identity, set the STS endpoint with this annotation
instead of `Bucket.spec.sts.endpoint`. See the
[AWS integration docs](/flux/integrations/aws/) for provider-specific
configuration.

#### `gcp.auth.fluxcd.io/workload-identity-provider`

The fully qualified GCP Workload Identity Provider resource name, for example:

```text
projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID
```

It is required outside GKE when using the `gcp` service provider, and for any
GCP integration using the `spiffe` credential provider. On GKE, the built-in
workload identity provider is used when this annotation is omitted. See the
[GCP integration docs](/flux/integrations/gcp/) for provider-specific
configuration.

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
them for a consistent identity experience across managed and self-hosted
clusters. They are placed on the ServiceAccount of the Flux object. For using
object identity across multiple cloud providers, see
[Support for cross-cloud](/flux/integrations/cross-cloud/).

#### `eks.amazonaws.com/role-arn`

The ARN of the AWS IAM Role that the ServiceAccount assumes. This annotation is
required when using the `aws` service provider with object identity. See the
[AWS integration docs](/flux/integrations/aws/) for provider-specific
configuration.

#### `azure.workload.identity/tenant-id`

The Microsoft Entra tenant ID. This annotation is required when using the
`azure` service provider with object identity. See the
[Azure integration docs](/flux/integrations/azure/) for provider-specific
configuration.

#### `azure.workload.identity/client-id`

The Microsoft Entra client ID of the managed identity. This annotation is
required when using the `azure` service provider with object identity.

#### `iam.gke.io/gcp-service-account`

The email address of the GCP Service Account to impersonate. It is optional.
When omitted, the subject under the GCP Workload Identity Pool is the IAM
Principal to which GCP IAM Roles should be granted. See the
[GCP integration docs](/flux/integrations/gcp/#to-kubernetes-service-accounts)
for more details.

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

Each entry uses one of the [SPIFFE ID formats](/flux/integrations/spiffe-mtls/)
accepted by Flux.

The mTLS annotations are independent of credential acquisition. On their own,
they do not require `credential.auth.fluxcd.io/provider` or
`credential.auth.fluxcd.io/type`. If any authentication annotation is present
alongside them, however, the credential provider and type must also be set.

The annotation is rejected when `.spec.certSecretRef` is set, or when
certificates or CAs come from `.spec.secretRef`.

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

Object identity with a Kubernetes JWT for an OCI registry:

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

SPIFFE JWT-SVID for SOPS authentication to an OpenBao transit engine:

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

SPIFFE JWT-SVID for a remote Kubernetes cluster:

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

SPIFFE X509-SVID for AWS IAM Roles Anywhere and GCP Workload Identity
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
