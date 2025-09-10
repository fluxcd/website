---
title: "Flux Workload Identity"
linkTitle: "Workload Identity"
description: "How to configure workload identity for Flux controllers"
weight: 13
---

When running Flux on AWS EKS, Azure AKS and Google Cloud GKE you can leverage Kubernetes
Workload Identity to grant Flux controllers access to cloud resources such as container
registries, KMS, S3, etc.

## AWS IAM roles for service accounts

To grant Flux access to AWS resources using IRSA [during bootstrap](bootstrap-customization.md) add the following patches
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
integrations with AWS IAM for accessing ECR, S3 and KMS please
see the [AWS integration documentation](/flux/integrations/aws/).
{{% /alert %}}

## Azure Workload Identity

To grant Flux access to Azure resources [during bootstrap](bootstrap-customization.md) add the following patches
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
      name: "(source-controller|image-reflector-controller)"
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: controller
        labels:
          azure.workload.identity/use: "true"
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

## GCP Workload Identity

To grant Flux access to Google Cloud resources [during bootstrap](bootstrap-customization.md) add the following patches
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
