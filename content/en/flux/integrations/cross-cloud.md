---
title: "Support for cross-cloud"
linkTitle: "Support for cross-cloud"
description: "Compatibility table for cross-cloud support in Flux"
weight: 50
---

The tables below show the compatibility matrix for Flux running inside a
*source cluster* aiming to get access to resources in a *target cloud provider*
using secret-less authentication.

For each target cloud provider, you can find the authentication docs here:

- [AWS](aws.md#authentication)
- [Azure](azure.md#authentication)
- [GCP](gcp.md#authentication)

#### Authentication at the object level (best for multi-tenant use cases)

| Source Cluster Type | AWS | Azure | GCP |
|---------------------|-----|-------|-----|
| AKS                 | ✅  | ✅    | ✅  |
| EKS                 | ✅  | ✅    | ✅  |
| GKE                 | ✅  | ✅    | ✅  |
| Other (e.g. `kind`) | ✅  | ✅    | ✅  |

#### Authentication at the controller level (best for single-tenant use cases)

| Source Cluster Type | AWS | Azure | GCP |
|---------------------|-----|-------|-----|
| AKS                 | ✅  | ✅    | ✅  |
| EKS                 | ✅  | ✅    | ✅  |
| GKE                 | ✅  | ✅    | ✅  |
| Other (e.g. `kind`) | ✅  | ✅    | ✅  |

> **Note**: Secret-based authentication is supported across all combinations, but
> should be avoided in favor of secret-less authentication when available. Secrets
> can be stolen to abuse the permissions granted to the identities they represent,
> and for public clouds this can be done by simply having Internet access. This
> requires secrets to be regularly rotated and more security controls to be put in
> place, like audit logs, secret management tools, etc. Secret-less authentication
> does not have this problem, as the identity is authenticated using a token that
> is not stored anywhere and is only valid for a short period of time, usually one
> hour. It's much harder to steal an identity this way.

## Source cluster setup

When configuring access from a source cluster to a target cloud provider, you
need to configure the *Issuer URL* of the source cluster as an *OIDC Provider* in
the target cloud provider. In this section we show how to obtain the Issuer URL
of the source cluster. For instructions on how to create an OIDC provider with
this URL in the target cloud provider, go to these links:

- [AWS](aws.md#supported-clusters)
- [Azure](azure.md#supported-clusters)
- [GCP](gcp.md#supported-clusters)

### For managed Kubernetes services from cloud providers

Depending on the type of cluster you are using, the Issuer URL is already publicly
accessible from the Internet and no in-cluster setup is required. These are usually
the managed services from the cloud providers, like AKS, EKS and GKE. All of these
support publicly accessible Issuer URLs by default. In such cases, all you need to
do is find out the Issuer URL of the source cluster with the following `kubectl`
command and follow the docs linked [above](#source-cluster-setup):

```bash
kubectl get --raw /.well-known/openid-configuration | jq
```

Here's an example for a GKE cluster:

```json
{
  "issuer": "https://container.googleapis.com/v1/projects/<projectID>/locations/<location>/clusters/<name>",
  "jwks_uri": "https://<some-ip-address>:443/openid/v1/jwks",
  "response_types_supported": [
    "id_token"
  ],
  "subject_types_supported": [
    "public"
  ],
  "id_token_signing_alg_values_supported": [
    "RS256"
  ]
}
```

In this case, the Issuer URL is:

```
https://container.googleapis.com/v1/projects/<projectID>/locations/<location>/clusters/<name>
```

### For clusters without a built-in public Issuer URL

Some clusters do not have a built-in public Issuer URL, like self-managed, on-premises,
or `kind` clusters running on a local machine or in CI pipelines.

The Kubernetes API Server offers a couple of binary flags that allow customizing the
Issuer URL and JWKS URI of the cluster's *service account token issuer*. See
[docs](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-issuer-discovery).

These flags are:
- `--service-account-issuer`: Allows setting the `issuer` field returned in the
  `/.well-known/openid-configuration` endpoint as shown in the example
  [above](#for-managed-kubernetes-services-from-cloud-providers).
- `--service-account-jwks-uri`: Allows setting the `jwks_uri` field returned in the
  `/.well-known/openid-configuration` endpoint as shown in the example
  [above](#for-managed-kubernetes-services-from-cloud-providers).

This ability to customize the Issuer URL and JWKS URI enables users to host static
discovery documents on public URLs, e.g. with CDNs or object storage systems like
AWS S3, Azure Blob Storage or GCP Cloud Storage.

> **Note**: This customization is achieved *without exposing the Kubernetes API Server
> endpoint to the Internet*. Furthermore, JWKS stands for *JSON Web Key Set*, which in
> the OIDC protocol is a JSON-encoded set of *public* keys that cloud providers can use
> to verify the signatures of JWTs issued by external identity providers, like the
> Kubernetes service account token issuer. In other words, the JWKS document content
> is meant to be public.

> :warning: When performing this operation, remember to set the `--service-account-issuer`
> flag with both the new and the previous value, **in this specific order**, to avoid
> disruption in the cluster. This flag is allowed to be set multiple times for this
> purpose. The first value will be used to issue new tokens, and all the values will be
> used to determine which issuers are accepted by the API Server when authenticating
> requests, i.e. when validating existing tokens. Bear in mind that the service account
> tokens are used not only by Flux to get access on cloud providers, but also by Flux
> and many other core components of Kubernetes to authenticate with the API Server.
> You need to be extremely cautious performing this operation. Make sure to update the
> API Server flags only after you have successfully uploaded the discovery documents
> and confirmed that they are publicly accessible.

Steps to perform this setup:

1. Run the command `kubectl get --raw /.well-known/openid-configuration | jq`
   shown [above](#for-managed-kubernetes-services-from-cloud-providers) to get
   the current discovery document.
2. Change the `issuer` field to the new Issuer URL you want to use. For example,
   if you decide to use AWS S3, the Issuer URL should look like this:
   `https://s3.amazonaws.com/<bucket-name>`.
3. Change the `jwks_uri` field to the new JWKS URI you want to use. For example,
   if you decide to use AWS S3, the JWKS URI should look like this:
   `https://s3.amazonaws.com/<bucket-name>/openid/v1/jwks`.
4. Upload the modified discovery document to the public URL you want to use.
   For example, if you decide to use AWS S3, the object key must be
   `.well-known/openid-configuration` and the bucket must be publicly accessible.
5. Test that the discovery document was correctly uploaded by `curl`ing the URL
   you created. For example, if you decide to use AWS S3, the `curl` command
   should look like this:
   `curl https://s3.amazonaws.com/<bucket-name>/.well-known/openid-configuration`.
   The output should be the modified discovery document you uploaded, with the
   `issuer` field matching `https://s3.amazonaws.com/<bucket-name>` and the
    `jwks_uri` field matching `https://s3.amazonaws.com/<bucket-name>/openid/v1/jwks`.
6. Run the command `kubectl get --raw /openid/v1/jwks | jq` to get the JWKS document.
7. Upload the JWKS document to the public URL you want to use. For example,
   if you decide to use AWS S3, the object key must be `openid/v1/jwks` and
   the bucket must be publicly accessible.
8. Test that the JWKS document was correctly uploaded by `curl`ing the URL
   you created. For example, if you decide to use AWS S3, the `curl` command
   should look like this:
   `curl https://s3.amazonaws.com/<bucket-name>/openid/v1/jwks`. The output
   should be the JWKS document you uploaded.
9. Finally, update the Kubernetes API Server flags mentioned above to use the new
   Issuer URL and JWKS URI.

Here's an example of the output of `kubectl get --raw /openid/v1/jwks`:

```json
{
  "keys": [
    {
      "use": "sig",
      "kty": "RSA",
      "kid": "BfK54vFk8UqizgJVa1BfRfNl-C5c3mWwQ1o_-bA-yAo",
      "alg": "RS256",
      "n": "qN1iYk24aS<... very long redacted public key string ...>IvUY8e4wSaw",
      "e": "AQAB"
    }
  ]
}
```

#### Rotating the private key used by Kubernetes to sign service account tokens

If you manage the cluster yourself, you may (probably!) want to rotate the private
key used by API Server to issue service account tokens from time to time. When
doing so, *you must remember to update the JWKS document upstream*, otherwise
Flux will lose access to your cloud providers.

See how you can manage/rotate the private key used
by API Server to sign the service account tokens
[here](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#serviceaccount-token-volume-projection).
Quote from the docs:

- `--service-account-signing-key-file string`: "Specifies the path to a file that
  contains the current private key of the service account token issuer. The issuer
  signs issued ID tokens with this private key."
- `--service-account-key-file strings`: "Specifies the path to a file containing
  PEM-encoded X.509 private or public keys (RSA or ECDSA), used to verify
  ServiceAccount tokens. The specified file can contain multiple keys, and the
  flag can be specified multiple times with different files. If specified multiple
  times, tokens signed by any of the specified keys are considered valid by the
  Kubernetes API Server."

The ability to specify multiple public keys for signature verification is
for allowing rotations to take place without disruption. Existing tokens
will be valid until they expire or until the public key that can
verify them is removed from the API Server.

> :warning: Bear in mind that service account tokens are used not only by
> Flux to get access on cloud providers, but also by Flux and many other
> core components of Kubernetes to authenticate with the API Server.
> You need to be extremely cautious when rotating this private key.

#### Special feature from GCP Workload Identity Federation

GCP Workload Identity Federation allows you to directly upload the
JWKS document, which frees you from having to customize the API
Server flags and from having to host the discovery documents on
public URLs, *but you still need to update the JWKS document if you
rotate the private key of the cluster*.
See [docs](https://cloud.google.com/iam/docs/workload-identity-federation-with-kubernetes#create_the_workload_identity_pool_and_provider).

As of now, GCP is the only cloud provider that supports this feature.
