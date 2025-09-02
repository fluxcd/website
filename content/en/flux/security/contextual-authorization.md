---
title: "Contextual Authorization"
linkTitle: "Contextual Authorization"
description: "Contextual Authorization for securing Flux deployments."
weight: 140
---

## Introduction

Most cloud providers support context-based authorization, enabling applications
to benefit from strong access controls applied to a given context (e.g. Virtual
Machine), without the need of managing authentication tokens and credentials.

For example, by granting a given Virtual Machine (or principal that such machine
operates under) access to AWS S3, applications running inside that machine can
request a token on-demand, which would grant them access to the AWS S3 buckets
without having to store long lived credentials anywhere.

By leveraging such capability, Flux users can focus on the big picture, which is
access controls enforcement with a least-privileged approach, whilst not having to
do deal with security hygiene topics such as encrypting authentication secrets, and
ensure they are being rotated regularly.
All that is taken care of automatically by the cloud providers, as the tokens provided
are context- and time-bound.

## Current Support

Below is a list of Flux features that support this functionality and their documentation:

| Status    | Component                   | Feature                             | Provider | Ref            |
|-----------|-----------------------------|-------------------------------------|----------|----------------|
| Supported | Source Controller           | GitRepository Authentication        | Azure    | [Guide][Azure] |
| Supported | Source Controller           | Bucket Authentication               | AWS      | [Guide][AWS]   |
| Supported | Source Controller           | Bucket Authentication               | Azure    | [Guide][Azure] |
| Supported | Source Controller           | Bucket Authentication               | GCP      | [Guide][GCP]   |
| Supported | Source Controller           | OCIRepository Authentication        | AWS      | [Guide][AWS]   |
| Supported | Source Controller           | OCIRepository Authentication        | Azure    | [Guide][Azure] |
| Supported | Source Controller           | OCIRepository Authentication        | GCP      | [Guide][GCP]   |
| Supported | Source Controller           | `oci` HelmRepository Authentication | AWS      | [Guide][AWS]   |
| Supported | Source Controller           | `oci` HelmRepository Authentication | Azure    | [Guide][Azure] |
| Supported | Source Controller           | `oci` HelmRepository Authentication | GCP      | [Guide][GCP]   |
| Supported | Kustomize Controller        | SOPS Integration with KMS           | AWS      | [Guide][AWS]   |
| Supported | Kustomize Controller        | SOPS Integration with Key Vault     | Azure    | [Guide][Azure] |
| Supported | Kustomize Controller        | SOPS Integration with KMS           | GCP      | [Guide][GCP]   |
| Supported | Kustomize Controller        | Remote EKS Cluster Authentication   | AWS      | [Guide][AWS]   |
| Supported | Kustomize Controller        | Remote AKS Cluster Authentication   | Azure    | [Guide][Azure] |
| Supported | Kustomize Controller        | Remote GKE Cluster Authentication   | GCP      | [Guide][GCP]   |
| Supported | Helm Controller             | Remote EKS Cluster Authentication   | AWS      | [Guide][AWS]   |
| Supported | Helm Controller             | Remote AKS Cluster Authentication   | Azure    | [Guide][Azure] |
| Supported | Helm Controller             | Remote GKE Cluster Authentication   | GCP      | [Guide][GCP]   |
| Supported | Notification Controller     | Azure DevOps Commit Status Updates  | Azure    | [Guide][Azure] |
| Supported | Notification Controller     | Azure Event Hubs                    | Azure    | [Guide][Azure] |
| Supported | Notification Controller     | Google Cloud Pub/Sub                | GCP      | [Guide][GCP]   |
| Supported | Image Reflector Controller  | ImageRepository Authentication      | AWS      | [Guide][AWS]   |
| Supported | Image Reflector Controller  | ImageRepository Authentication      | Azure    | [Guide][Azure] |
| Supported | Image Reflector Controller  | ImageRepository Authentication      | GCP      | [Guide][GCP]   |
| Supported | Image Automation Controller | GitRepository Authentication        | Azure    | [Guide][Azure] |

[AWS]: /flux/integrations/aws.md
[Azure]: /flux/integrations/azure.md
[GCP]: /flux/integrations/gcp.md
