---
title: "Flux Workload Identity"
linkTitle: "Workload Identity"
description: "How to configure workload identity for Flux controllers"
weight: 13
---

When running Flux on AWS EKS, Azure AKS and GCP GKE you can leverage Kubernetes
Workload Identity to grant Flux controllers access to cloud resources such as container
registries, KMS, S3, etc.

## Workload Identity Types

Flux supports two types of workload identity:

- **Controller-level**: the Flux controller itself is granted access to cloud resources.
- **Object-level**: individual Flux objects are granted access to cloud resources.
  In this case, the Flux object API usually has a `.serviceAccountName` field
  that can be set to the name of a Kubernetes `ServiceAccount` with the required
  configuration. For the specifics of each API, see the documentation of the
  corresponding API.

Controller-level and object-level workload identity can be used together.
If object-level workload identity is not configured for a given object,
workload identity defaults to controller-level.

This documentation shows how a Kubernetes `ServiceAccount` should be configured to
use a cloud provider identity, regardless if the `ServiceAccount` belongs to a
Flux controller or if it is used in a Flux object. Because controller-level
requires a patch in the Flux installation, we show the `ServiceAccount`
configuration in the context of the Flux installation, but the same configuration
can be used for object-level workload identity (it's essentially about the
`ServiceAccount` annotations).

When configuring controller-level workload identity, make sure to delete the
affected controller pod after the configuration is in place to make a new pod
take its place with the workload identity configuration under effect.

## AWS

### IAM Roles for Service Accounts (IRSA)

To grant Flux access to AWS resources using IRSA [during bootstrap](boostrap-customization.md) add the following patches
to the flux-system `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: controller
        annotations:
          eks.amazonaws.com/role-arn: <ROLE ARN>
    target:
      kind: ServiceAccount
      name: "(source-controller|image-reflector-controller)"  # or any other target controllers
```

### Pod Identity

In AWS it's also possible to use Pod Identity for controller-level workload identity, see docs
[here](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html) and blog post
[here](https://aws.amazon.com/blogs/containers/amazon-eks-pod-identity-a-new-way-for-applications-on-eks-to-obtain-iam-credentials/).
In this case, an IAM Role is associated with the Kubernetes `ServiceAccount` of the Flux controller
entirely on the AWS side, and therefore no patch on the annotations is required, nor any in-cluster
configuration.

**Note**: Pod Identity is only supported for controller-level workload identity. Flux APIs supporting
object-level workload identity through `.serviceAccountName` fields cannot use Pod Identity due to
a technical limitation imposed by the implementaiton of this feature in AWS: a pod using the service
account is required to exist. Flux cannot ensure such requirement.

## Azure Workload Identity

To grant Flux access to Azure resources [during bootstrap](boostrap-customization.md) add the following patches
to the flux-system `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: controller
        annotations:
          azure.workload.identity/client-id: <AZURE CLIENT ID>
          azure.workload.identity/tenant-id: <AZURE TENANT ID>
    target:
      kind: ServiceAccount
      name: "(source-controller|image-reflector-controller)" # or any other target controllers
  # Azure workload identity requires also a label on the pod.
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: controller
      spec:
        template:
          metadata:
            labels:
              azure.workload.identity/use: "true"
    target:
      kind: Deployment
      name: "(source-controller|image-reflector-controller)" # or any other target controllers
```

The pod label is only required for controller-level workload identity.
For object-level workload identity only the `ServiceAccount` annotations
are required.

## GCP Workload Identity

To grant Flux access to Google Cloud resources [during bootstrap](boostrap-customization.md) add the following patches
to the flux-system `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: controller
        annotations:
          iam.gke.io/gcp-service-account: <GCP SERVICE ACCOUNT EMAIL>
    target:
      kind: ServiceAccount
      name: "(source-controller|image-reflector-controller)" # or any other target controllers
```

In GCP it's also possible to use workload identity without creating GCP service accounts, see docs
[here](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#verify) and blog post
[here](https://cloud.google.com/blog/products/identity-security/make-iam-for-gke-easier-to-use-with-workload-identity-federation).
In this case, IAM permissions are granted to a principal that directly encodes the Kubernetes
`ServiceAccount` of the Flux controller, and therefore no patch on the annotations is required,
nor any in-cluster configuration.
