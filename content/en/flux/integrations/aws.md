---
title: "Amazon Web Services"
linkTitle: "Amazon Web Services"
description: "How to configure access for the Flux integrations with Amazon Web Services."
weight: 50
---

The Flux APIs integrate with the following Amazon Web Services (AWS) services:

- The source-controller integrates the [OCIRepository](/flux/components/source/ocirepositories/) API with
  [Amazon Elastic Container Registry (ECR)](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)
  for pulling OCI artifacts into the cluster.
- The source-controller integrates the OCIRepository API with
  [Amazon Public Elastic Container Registry (Public ECR)](https://docs.aws.amazon.com/AmazonECR/latest/public/what-is-ecr.html)
  for pulling OCI artifacts into the cluster.
- The image-reflector-controller integrates the [ImageRepository](/flux/components/image/imagerepositories/) and
  [ImagePolicy](/flux/components/image/imagepolicies/) APIs with ECR and public ECR for scanning tags and digests
  of OCI artifacts and reflecting them into the cluster.
- The source-controller integrates the [Bucket](/flux/components/source/buckets/) API with
  [Amazon Simple Storage Service (S3)](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)
  for pulling manifests from buckets and packaging them as artifacts inside the cluster.
- The kustomize-controller integrates the [Kustomization](/flux/components/kustomize/kustomizations/) API with
  [Amazon Key Management Service (KMS)](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html)
  for decrypting SOPS-encrypted secrets when applying manifests in the cluster.

The next sections briefly describe [AWS IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html), AWS's identity and access management system, and how it can be used to grant Flux access
to resources offered by the services above. Bear in mind that AWS IAM has more features
than the ones described here. We describe only the features that are relevant for the
Flux integrations.

## Identity

For all the integrations with AWS, AWS will authenticate two types of identities for Flux:

- [IAM Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)
- [IAM Users](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html)

Each has its own methods of authentication. In particular, IAM Roles support
secret-less authentication, while IAM Users support secret-based authentication.
The former is more secure.

For further understanding how to configure authentication for both types of
identities, refer to the [Authentication](#authentication) section.

## Access Management

Identities in AWS need *permissions* to access resources from AWS services.
Those can be granted using
[permission policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html).
Policies group statements that allow specific actions to be performed on specific
resources of specific services. Each policy has a name and a globally unique
[Amazon Resource Name (ARN)](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference-arns.html).
For example, the policy `AmazonS3ReadOnlyAccess`, whose ARN is `arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess`,
groups the following statements:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:Describe*",
                "s3-object-lambda:Get*",
                "s3-object-lambda:List*"
            ],
            "Resource": "*"
        }
    ]
}
```

The structure of actions is usually `<service>:<action>`.

AWS has a large number of
[AWS-managed policies](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/policy-list.html),
but users can also create
[customer-managed policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_managed-vs-inline.html#customer-managed-policies)
inside their AWS accounts.

AWS supports also
[inline policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_managed-vs-inline.html#inline-policies).

Managed and inline policies can be
[attached to identities](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_id-based),
which is a good strategy for when the identity and the resource are in the same AWS account.

Only inline policies can be
[attached to resources](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_resource-based). This is required when the target resource is in a different
AWS account than the identity.

> **Note**: As an exception, KMS does not support identity-based policies by default. To enable it, follow these
> [docs](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-root-enable-iam).

### Granting permissions

When attaching permission policies to identities, a statement must enumerate the resources
it applies to. This can be done using ARNs, but it can also be done using
wildcards. For example, the `AmazonS3ReadOnlyAccess` policy above uses the wildcard `*`
to allow access to all S3 resources. This is not recommended, as it violates the
[Least Privilege Principle](https://en.wikipedia.org/wiki/Principle_of_least_privilege).
The recommended way of granting permissions to Flux is to use specific ARNs, for example:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowReadObjects",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::flux-bucket",
                "arn:aws:s3:::flux-bucket/*"
            ]
        }
    ]
}
```

When attaching (inline) permission policies to resources, a statement must enumerate also the identities
it applies to, through identity ARNs. For example:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowReadObjects",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::123456789012:user/some-user",
                    "arn:aws:iam::123456789012:role/some-role"
                ]
            },
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::flux-bucket",
                "arn:aws:s3:::flux-bucket/*"
            ]
        }
    ]
}
```

#### Via AWS Controllers for Kubernetes IAM custom resources

To use
[AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/docs/community/overview/)
for creating permission policies, you can use the following custom resource:

- [`Policy`](https://aws-controllers-k8s.github.io/community/reference/iam/v1alpha1/policy/)

Then to create IAM Roles and Users and attach the policies to them, you can use the following:

- [`Role`](https://aws-controllers-k8s.github.io/community/reference/iam/v1alpha1/role/)
- [`User`](https://aws-controllers-k8s.github.io/community/reference/iam/v1alpha1/user/)

For resource-based policies, see the [Authorization](#authorization) section below for each
individual resource type that Flux integrates with.

> **Note**: ACK is the most GitOps-friendly way of managing AWS
> resources. With it you can even use Flux itself to deploy and continuously reconcile
> your AWS custom resources (the Kubernetes ones), and ACK itself will
> [continuously reconcile](https://aws-controllers-k8s.github.io/community/docs/user-docs/drift-recovery/)
> the actual AWS resources.

#### Via Terraform/OpenTofu IAM resources

To use Terraform/OpenTofu for creating permission policies, you can use the following resource:

- [`aws_iam_policy`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)

Then to create IAM Roles and Users and attach the policies to them, you can use the following:

- [`aws_iam_role`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
- [`aws_iam_user`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user)

For resource-based policies, see the [Authorization](#authorization) section below for each
individual resource type that Flux integrates with.

> **Note**: Terraform/OpenTofu is a great declarative way of managing AWS resources,
> but it's not as GitOps-friendly as ACK, as these tools do not prescribe
> continuous reconciliation of the resources. There are alternatives to achieve that,
> but they are not a core part of the tools.

#### Via the `aws` CLI

To use the `aws` CLI for creating permission policies you can use the following command:

- [`aws iam create-policy`](https://docs.aws.amazon.com/cli/latest/reference/iam/create-policy.html)

Then to create IAM Roles and Users and attach the policies to them, you can use the following:

- [`aws iam create-role`](https://docs.aws.amazon.com/cli/latest/reference/iam/create-role.html)
- [`aws iam create-user`](https://docs.aws.amazon.com/cli/latest/reference/iam/create-user.html)

For resource-based policies, see the [Authorization](#authorization) section below for each
individual resource type that Flux integrates with.

> **Note**: The `aws` CLI is a great tool for experimenting with AWS resources and
> their integrations with Flux, but it's not a GitOps-friendly way of managing AWS
> resources. If you need continuous reconciliation of the resources, prefer using
> ACK or Terraform/OpenTofu.

### Allowing Kubernetes Service Accounts to assume IAM Roles (Trust Policies)

For [EKS Pod Identity](#with-eks-pod-identity) and [OIDC Federation](#with-oidc-federation),
the only supported identity type is IAM Roles. In both cases, an IAM Role must be configured
to allow a Kubernetes Service Account to assume it. This is done by adding a
[Trust Policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html#term_trust-policy)
to the IAM Role.

Trust policies are similar in syntax to permission policies, but for each
of these two features the trust policy JSON document has particular requirements.
For EKS Pod Identity, see [here](#for-eks-pod-identity). For OIDC Federation, see
[here](#supported-identity-types).

To create an IAM Role with a trust policy using ACK, you can use the following custom resource
(look for the `spec.assumeRolePolicyDocument` field):

- [`Role`](https://aws-controllers-k8s.github.io/community/reference/iam/v1alpha1/role/)

To create an IAM Role with a trust policy using Terraform/OpenTofu, you can use the following
resource (look for the `assume_role_policy` argument):

- [`aws_iam_role`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)

To configure a trust policy for an IAM Role using the `aws` CLI, you can use the following command:

- [`aws iam update-assume-role-policy`](https://docs.aws.amazon.com/cli/latest/reference/iam/update-assume-role-policy.html)

## Authorization

In this section we describe the recommended IAM policy bindings for
enabling the Flux integrations with AWS services.

### For Amazon Elastic Container Registry

The `OCIRepository`, `ImageRepository` and `ImagePolicy` Flux APIs are integrated with
ECR. The `OCIRepository` API can be used to pull OCI artifacts from ECR repositories
into the cluster, while the `ImageRepository` and `ImagePolicy` APIs
can be used to reflect tags and digests of such artifacts also inside the cluster.

For single-tenant setups, the recommended AWS-managed policy containing the required
permissions for the `OCIRepository`, `ImageRepository` and `ImagePolicy` APIs is:

- [AmazonEC2ContainerRegistryReadOnly (`arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly`)](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonEC2ContainerRegistryReadOnly.html)

It can be attached to IAM Roles or Users.

This policy grants read-only access to all resources (`"Resource": "*"`). Hence, for
multi-tenant setups, a better approach is attaching an inline policy to the ECR
repositories belonging to the tenant granting access to an IAM Role or User
with the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::123456789012:role/some-tenant-role"
            },
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:DescribeImages",
                "ecr:BatchGetImage",
                "ecr:GetLifecyclePolicy",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:ListTagsForResource",
                "ecr:DescribeImageScanFindings"
            ],
            "Resource": "*"
        }
    ]
}
```

The ACK resource kind for creating an ECR repository and attaching an inline permission policy is:

- [`Repository`](https://aws-controllers-k8s.github.io/community/reference/ecr/v1alpha1/repository/)

The Terraform/OpenTofu resource for attaching an inline permission policy to an ECR repository is:

- [`aws_ecr_repository_policy`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy)

The `aws` CLI command for attaching an inline permission policy to an ECR repository is:

- [`aws ecr set-repository-policy`](https://docs.aws.amazon.com/cli/latest/reference/ecr/set-repository-policy.html)

### For Amazon Public Elastic Container Registry

The `OCIRepository`, `ImageRepository` and `ImagePolicy` Flux APIs are integrated with
public ECR. The `OCIRepository` API can be used to pull OCI artifacts from public ECR
repositories into the cluster, while the `ImageRepository` and `ImagePolicy` APIs
can be used to reflect tags and digests of such artifacts also inside the cluster.

For public ECR, attaching the read-only AWS-managed policy suffices for any of the
Flux APIs:

- [AmazonElasticContainerRegistryPublicReadOnly (`arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly`)](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonElasticContainerRegistryPublicReadOnly.html)

It can be attached to IAM Roles or Users.

### For Amazon Simple Storage Service

The `Bucket` Flux API is integrated with S3. The `Bucket` API
can be used to pull manifests from S3 buckets and package them as artifacts inside the cluster.

For single-tenant setups, the recommended AWS-managed policy containing the required
permissions for the `Bucket` API is:

- [AmazonS3ReadOnlyAccess (`arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess`)](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonS3ReadOnlyAccess.html)

It can be attached to IAM Roles or Users.

This policy grants read-only access to all resources (`"Resource": "*"`). Hence, for
multi-tenant setups, a better approach is attaching an inline policy to the S3
buckets belonging to the tenant granting access to an IAM Role or User
with the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::123456789012:role/some-tenant-role"
            },
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:Describe*",
                "s3-object-lambda:Get*",
                "s3-object-lambda:List*"
            ],
            "Resource": "*"
        }
    ]
}
```

The ACK resource kind for creating an S3 bucket and attaching an inline permission policy is:

- [`Bucket`](https://aws-controllers-k8s.github.io/community/reference/s3/v1alpha1/bucket/)

The Terraform/OpenTofu resource for attaching an inline permission policy to an S3 bucket is:

- [`aws_s3_bucket_policy`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy)

The `aws` CLI command for attaching an inline permission policy to an S3 bucket is:

- [`aws s3api put-bucket-policy`](https://docs.aws.amazon.com/cli/latest/reference/s3api/put-bucket-policy.html)

### For Amazon Key Management Service

The `Kustomization` Flux API is integrated with KMS.
The `Kustomization` API is used to apply manifests in the cluster, and it can use KMS to
decrypt SOPS-encrypted secrets before applying them.

As mentioned in the [Access Management](#access-management) section, KMS does not support
identity-based policies by default, and it's also part of this security strategy not to
offer AWS-managed policies for KMS.

The recommended approach for granting an IAM Role or User access to a KMS key is to
attach an inline policy to the KMS key itself, granting access to the IAM Role or User
with the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::123456789012:role/some-tenant-role"
            },
            "Action": [
                "kms:Decrypt",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        }
    ]
}
```

A similar policy can be used to grant access to specific KMS keys to IAM Roles or Users
with a customer-managed policy.

The ACK resource kind for creating a KMS key and attaching an inline permission policy is:

- [`Key`](https://aws-controllers-k8s.github.io/community/reference/kms/v1alpha1/key/)

The Terraform/OpenTofu resource for attaching an inline permission policy to a KMS key is:

- [`aws_kms_key_policy`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy)

The `aws` CLI command for attaching an inline permission policy to a KMS key is:

- [`aws kms put-key-policy`](https://docs.aws.amazon.com/cli/latest/reference/kms/put-key-policy.html)

## Authentication

As mentioned in the [Identity](#identity) section, AWS supports two types of
identities for Flux: IAM Roles and IAM Users.
This section describes how to authenticate each type of identity.
IAM Roles are the recommended way of authenticating to AWS services, as they
support secret-less authentication. IAM Users are not recommended, as they
require secret-based authentication, which is less secure.

> **Recommendation**: Always prefer secret-less over secret-based authentication
> if the alternative is available. Secrets can be stolen to abuse the permissions
> granted to the identities they represent, and for public clouds like AWS this can
> be done by simply having Internet access. This requires secrets to be regularly
> rotated and more security controls to be put in place, like audit logs, secret
> management tools, etc. Secret-less authentication does not have this problem, as
> the identity is authenticated using a token that is not stored anywhere and is
> only valid for a short period of time, usually one hour. It's much harder to
> steal an identity this way.

### With EKS Pod Identity

*Only at the controller level for EKS clusters*,
[EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)
can be used to link the Kubernetes Service Account of a Flux controller to a single IAM
Role that will be used for all the AWS operations this Flux controller performs.

> **Note**: Pod Identity is an EKS-only feature specifically targeting pods.
> It's not possible to support it at the object level, as for a Kubernetes Service
> Account token to be accepted by Pod Identity it necessarily needs to be tied to a
> pod that is configured to use this Kubernetes Service Account. This is a guarantee
> that no Kubernetes controller can provide when issuing a token for a Service
> Account configured in a custom resource object.

First, enable Pod Identity in the EKS cluster.

In EKS Auto Mode, Pod Identity is always enabled, no cluster setup is required.
In standard EKS, follow these
[docs](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-agent-setup.html).

Next, to
[link an IAM Role with a Kubernetes Service Account of a Flux controller in Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-association.html),
the following steps are required:

1. **Allow EKS Pod Identity to assume the IAM Role.**
   This is done by adding a trust policy like this to the IAM Role:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowEksAuthToAssumeRoleForPodIdentity",
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
}
```

To create/attach trust policies to IAM Roles, see
[this](#allowing-kubernetes-service-accounts-to-assume-iam-roles-trust-policies) section.

2. **Link the IAM Role to the Kubernetes Service Account in Pod Identity.**

To perform this step using ACK, you can use the following custom resource:

- [`PodIdentityAssociation`](https://aws-controllers-k8s.github.io/community/reference/eks/v1alpha1/podidentityassociation/)

To perform this step using Terraform/OpenTofu, you can use the following resource:

- [`aws_eks_pod_identity_association`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association)

To perform this step using the `aws` CLI, you can use the following command:

- [`aws eks create-pod-identity-association`](https://docs.aws.amazon.com/cli/latest/reference/eks/create-pod-identity-association.html)

3. Restart (delete) the controller pod for the binding to take effect.

### With OIDC Federation

[OIDC Federation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc.html)
is an AWS feature that allows external identities to authenticate with AWS services
without the need for a per-identity static credential. This is done by exchanging
a short-lived token issued by the external identity provider (in this case,
Kubernetes) for short-lived AWS credentials. These credentials are then used
to authenticate with AWS services. OIDC Federation is supported only for IAM Roles.

#### Supported clusters

AWS supports OIDC Federation for EKS clusters through a feature called
[IAM Roles for Service Accounts (IRSA)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html),
and also for non-EKS clusters.

In EKS clusters you need to create an OIDC Provider with the
[Issuer URL](cross-cloud.md#source-cluster-setup) of the cluster following these
[docs](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html).

In non-EKS clusters you need to create an OIDC Provider with the Issuer URL of the cluster following these
[docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html).

To create an OIDC Provider using ACK, you can use the following custom resource:

- [`OpenIDConnectProvider`](https://aws-controllers-k8s.github.io/community/reference/iam/v1alpha1/openidconnectprovider/)

To create an OIDC Provider using Terraform/OpenTofu, you can use the following resource:

- [`aws_iam_openid_connect_provider`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider)

If using this Terraform/OpenTofu resource for EKS clusters, you can
fetch the Issuer URL of the cluster using this data source (look for
the `identity.oidc.issuer` attribute):

- [`aws_eks_cluster`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster)

To create an OIDC Provider using the `aws` CLI, you can use the following command:

- [`aws iam create-open-id-connect-provider`](https://docs.aws.amazon.com/cli/latest/reference/iam/create-open-id-connect-provider.html)

#### Supported identity types

As mentioned before, the only identity type supported by OIDC Federation is IAM Roles.

Flux acquires the permission policies granted to an IAM Role by using a Kubernetes
Service Account to *assume* this IAM Role. We call this process *impersonation*.
To configure a Kubernetes Service Account to assume an IAM Role, two steps
are required:

1. **Allow the Kubernetes Service Account to assume the IAM Role.**
   This is done by adding a
   [trust policy](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html#_create_and_associate_role_cli)
   to the IAM Role that allows the Kubernetes Service Account to assume it.

An IAM Role trust policy for OIDC federation with a Kubernetes cluster looks like this:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/ISSUER_URL_WITHOUT_SCHEME"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "ISSUER_URL_WITHOUT_SCHEME:aud": "sts.amazonaws.com",
                    "ISSUER_URL_WITHOUT_SCHEME:sub": "system:serviceaccount:KSA_NAMESPACE:KSA_NAME"
                }
            }
        }
    ]
}
```

See [here](#allowing-kubernetes-service-accounts-to-assume-iam-roles-trust-policies) how to
create/attach trust policies to IAM Roles.

2. **Annotate the Kubernetes Service Account with the IAM Role ARN.**
   This is done by adding the annotation
   `eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME`
   to the Kubernetes Service Account:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: KSA_NAME
  namespace: NAMESPACE
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME
```

Configuring Flux to use a Kubernetes Service Account to authenticate with
AWS can be done either [at the object level](#at-the-object-level) or
[at the controller level](#at-the-controller-level).

### With IAM User Access Keys

All AWS integrations except for ECR and public ECR support configuring
authentication through an IAM User Access Key.

IAM Users support static credentials that can be used to get access to AWS services called
[Access Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html).
An Access Key consists of an *Access Key ID* and a *Secret Access Key*. The Access Key ID is
a public identifier for the Access Key, while the Secret Access Key is a secret used to
sign requests to AWS services that have a short validity period.

ACK does not support creating Access Keys for IAM Users (see
[issue](https://github.com/aws-controllers-k8s/community/issues/1879)).

To create an Access Key for an IAM User using Terraform/OpenTofu, you can use the following resource:

- [`aws_iam_access_key`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key)

To create an Access Key for an IAM User using the `aws` CLI, you can use the following command:

- [`aws iam create-access-key`](https://docs.aws.amazon.com/cli/latest/reference/iam/create-access-key.html)

Configuring Flux to use an IAM User Access Key can be done either
[at the object level](#at-the-object-level) or
[at the controller level](#at-the-controller-level).

### At the object level

All the Flux APIs support configuring authentication at the object level.
This allows users to adhere to the
[Least Privilege Principle](https://en.wikipedia.org/wiki/Principle_of_least_privilege),
as each Flux resource can be configured with its own identity and therefore its own
permissions. This is useful for multi-tenancy scenarios, where different
teams can use the same cluster but need to be isolated from each other
inside their own namespaces.

#### For OIDC Federation

Before following the steps below, make sure to complete the cluster setup
described [here](#supported-clusters), and to configure the Kubernetes
Service Account as described [here](#supported-identity-types).

For configuring authentication through a Kubernetes Service Account
at the object level the following steps are required:

1. Enable the feature gate `ObjectLevelWorkloadIdentity` in the target Flux controller Deployment
   [during bootstrap](/flux/installation/configuration/boostrap-customization.md):

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - target:
      kind: Deployment
      name: (some-controller)
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: --feature-gates=ObjectLevelWorkloadIdentity=true
```

2. Set the `.spec.provider` field to `aws` in the Flux resource.
   For the `Kustomization` API, this field is not required/does not exist,
   SOPS detects the provider from the metadata in the SOPS-encrypted
   Secret.
3. Use the `.spec.serviceAccountName` field to specify the name of the
   Kubernetes Service Account in the same namespace as the Flux resource.
   For the `Kustomization` API, the field is `.spec.decryption.serviceAccountName`.

> **Note**: The `eks.amazonaws.com/role-arn` annotation is defined by EKS,
> but Flux also uses it to identify the IAM Role to assume in non-EKS clusters.
> This is for providing users with a seamless experience.

At the moment, the S3 integration with the `Bucket` API **does not support**
configuring authentication through OIDC Federation at the object level.
Support for this integration will be introduced in Flux v2.7.

#### For IAM User Access Keys

All AWS integrations except for ECR and public ECR support configuring
authentication through an IAM User Access Key.

For configuring authentication through an IAM User Access Key, the
`.spec.secretRef.name` field must be set to the name of the Kubernetes
Secret in the same namespace as the Flux resource containing the IAM
User Access Key. In the case of the `Kustomization` API, the field
is `.spec.decryption.secretRef.name`.

The provider field and the key inside the `.data` field of the Secret
depend on the specific Flux API:

- For the `Bucket` API the `.spec.provider` field must be set to `aws`,
  and the keys inside the `.data` field of the Secret must be
  `accesskey` and `secretkey`.
- For the `Kustomization` API, there's no provider field as SOPS detects
  the provider from the metadata in the SOPS-encrypted Secret.
  The key inside the `.data` field of the Secret must be `sops.aws-kms`
  and the value should look like this:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: SECRET_NAME
  namespace: NAMESPACE
type: Opaque
data:
  sops.aws-kms: |
    aws_access_key_id: some-access-key-id
    aws_secret_access_key: some-aws-secret-access-key
    aws_session_token: some-aws-session-token # this field is optional
```

### At the controller level

All the Flux APIs support configuring authentication at the controller level.
This is more appropriate for single-tenant scenarios, where all the Flux resources
inside the cluster belong to the same team and hence can share the same identity
and permissions.

#### For OIDC Federation

Before following the steps below, make sure to complete the cluster setup
described [here](#supported-clusters), and to configure the Kubernetes
Service Account as described [here](#supported-identity-types).

If the cluster is EKS, the Kubernetes Service Account of the controller must
be configured to assume an IAM Role. This is done by adding the
`eks.amazonaws.com/role-arn` annotation to the controller Service Account
[during bootstrap](/flux/installation/configuration/boostrap-customization.md):

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - target:
      kind: ServiceAccount
      name: "(some-controller)"
    patch: |
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: controller
        annotations:
          eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME
```

If the configuration above is done after bootstrap, restart (delete) the controller
for the binding to take effect.

If the cluster *is not* EKS, the controller Deployment must be patched
[during bootstrap](/flux/installation/configuration/boostrap-customization.md):

- A projected volume must be mounted in the controller Deployment with a Kubernetes
  Service Account token whose audience is set to `sts.amazonaws.com`.
- The environment variables required by the
  [AWS Go SDK v2](https://docs.aws.amazon.com/sdk-for-go/v2/developer-guide/configure-gosdk.html)
  to authenticate through OIDC Federation must be set in the controller Deployment.
  See an exhaustive list of the environment variables
  [here](https://github.com/aws/aws-sdk-go-v2/blob/main/config/env_config.go).

The controller patch should look like this:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - target:
      kind: Deployment
      name: "(some-controller)"
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: AWS_REGION
          value: AWS_REGION # This is the region of the AWS STS endpoint.
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: AWS_ROLE_ARN
          value: arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: AWS_ROLE_SESSION_NAME
          value: some-controller.flux-system.AWS_REGION.fluxcd.io
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: AWS_WEB_IDENTITY_TOKEN_FILE
          value: /var/run/service-account/aws-token
      - op: add
        path: /spec/template/spec/volumes/-
        value:
          name: aws-token
          projected:
            sources:
            - serviceAccountToken:
                audience: sts.amazonaws.com
                expirationSeconds: 3600
                path: aws-token
      - op: add
        path: /spec/template/spec/containers/0/volumeMounts/-
        value:
          name: aws-token
          mountPath: /var/run/service-account
          readOnly: true
```

#### For IAM User Access Keys

All AWS integrations except for ECR and public ECR support configuring
authentication through an IAM User Access Key.

Mount the Kubernetes Secret containing the IAM User Access Key and Secret
as the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
in the controller Deployment
[during bootstrap](/flux/installation/configuration/boostrap-customization.md):

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - target:
      kind: Deployment
      name: "(some-controller)"
    patch: |
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: some-controller-aws-access-key
              key: accesskey
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: some-controller-aws-access-key
              key: secretkey
```

The Secret should look like this:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: some-controller-aws-access-key
  namespace: flux-system
type: Opaque
stringData:
  accesskey: some-access-key-id
  secretkey: some-aws-secret-access-key
```

### At the node level

Only for the ECR integrations Flux supports authentication
at the node level for EKS. This is because users often already have to configure
authentication at the node level for EKS to be able to pull container images from
ECR in order to start pods. By supporting this authentication method Flux allows
users to configure ECR authentication in a single way. See how to
[create IAM Roles for EKS worker nodes](https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html#create-worker-node-role)
and how to
[allow them to pull images from ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/ECR_on_EKS.html).

> :warning: Node level authentication may work for other integrations as well,
> but Flux only has continuous integration tests for the ECR integration in
> order to support the specific use case described above.
