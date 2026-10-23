---
title: "Flux Workload Identity"
linkTitle: "Workload Identity"
description: "How to configure workload identity for Flux controllers"
weight: 13
---

When running Flux on AWS EKS, Azure AKS and Google Cloud GKE you can leverage Kubernetes
Workload Identity to grant Flux controllers access to cloud resources such as container
registries, KMS, S3, etc.

{{% alert color="info" title="Consider also object identity" %}}
This page covers the traditional workload identity approach, where the identity
comes from the Flux controller pod. This is best for single-tenant setups where
isolation between tenants is not a requirement.

The alternative to this approach is called object identity, where the identity
comes from the Flux object. Object identity is best for multi-tenant setups
that require strict isolation between tenants. This feature is covered here:

- [Object identity installation](/flux/installation/configuration/object-identity/)
- [Object identity API](/flux/integrations/object-identity/)
{{% /alert %}}

## Configuring Flux resources

With workload identity, Flux resources must use the provider of the controller
identity and leave the ServiceAccount fields unset:

- For all Flux resource kinds except `Kustomization` and `HelmRelease`, set the
  `.spec.provider` field to the provider, for example `aws`, `azure`, or `gcp`,
  and leave `.spec.serviceAccountName` unset.
- For remote cluster access with the `Kustomization` and `HelmRelease` APIs, set
  the `.data.provider` field of the `ConfigMap` referenced by
  `.spec.kubeConfig.configMapRef`, and leave `.data.serviceAccountName` unset.
- For SOPS decryption with the `Kustomization` API, leave the
  `.spec.decryption.serviceAccountName` field unset. There is no provider field
  for SOPS decryption, as the provider is described in the SOPS metadata embedded
  in the encrypted Secret.

## EKS IAM Roles for Service Accounts

To grant Flux access to AWS resources using IRSA during bootstrap add the following patches:

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
          eks.amazonaws.com/role-arn: <ECR ROLE ARN>
    target:
      kind: ServiceAccount
      name: "(source-controller|image-reflector-controller)"
  - patch: |
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: controller
        annotations:
          eks.amazonaws.com/role-arn: <KMS ROLE ARN>
    target:
      kind: ServiceAccount
      name: "kustomize-controller"
```

{{% alert color="info" title="Amazon Web Services Integrations" %}}
For a complete guide on configuring authentication for the Flux
integrations with AWS IAM for accessing ECR, S3, KMS and CodeCommit
please see the [AWS integration documentation](/flux/integrations/aws/).
The same documentation also covers configuring EKS Pod Identity.
{{% /alert %}}

## AKS Workload Identity

To grant Flux access to Azure resources during bootstrap add the following patches:

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
      name: "(source-controller|image-reflector-controller)"
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
      name: "(source-controller|image-reflector-controller)"
```

{{% alert color="info" title="Microsoft Azure Integrations" %}}
For a complete guide on configuring authentication for the Flux
integrations with Microsoft Entra ID for accessing ACR, Azure
DevOps, Blob Storage, Key Vault and Event Hubs please see the [Azure integration documentation](/flux/integrations/azure/).
{{% /alert %}}

## GKE Workload Identity

To grant Flux access to Google Cloud resources during bootstrap add the following patches:

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
          iam.gke.io/gcp-service-account: <GAR ID NAME>
    target:
      kind: ServiceAccount
      name: "(source-controller|image-reflector-controller)"
  - patch: |
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: controller
        annotations:
          iam.gke.io/gcp-service-account: <KMS ID NAME>
    target:
      kind: ServiceAccount
      name: "kustomize-controller"
```

{{% alert color="info" title="Google Cloud Platform Integrations" %}}
For a complete guide on configuring authentication for the Flux
integrations with GCP IAM for accessing GAR, GCS, KMS and Pub/Sub
please see the [GCP integration documentation](/flux/integrations/gcp/).
{{% /alert %}}
