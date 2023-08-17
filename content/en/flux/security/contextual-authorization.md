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

| Status    | Component                  | Feature                           | Provider | Ref                               |
|-----------|----------------------------|-----------------------------------|----------|-----------------------------------|
| Supported | Source Controller          | Bucket Repository Authentication  | AWS      | [Guide][AWS Buckets]              |
| Supported | Source Controller          | Bucket Repository Authentication  | Azure    | [Guide][Azure Buckets]            |
| Supported | Source Controller          | Bucket Repository Authentication  | GCP      | [Guide][GCP Buckets]              |
| Supported | Source Controller          | OCI Repository Authentication     | AWS      | [Guide][AWS OCI Repository]       |
| Supported | Source Controller          | OCI Repository Authentication     | Azure    | [Guide][Azure OCI Repository]     |
| Supported | Source Controller          | OCI Repository Authentication     | GCP      | [Guide][GCP OCI Repository]       |
| Supported | Source Controller          | Helm Repository Authentication    | AWS      | [Guide][AWS Helm Repository]      |
| Supported | Source Controller          | Helm Repository Authentication    | Azure    | [Guide][Azure Helm Repository]    |
| Supported | Source Controller          | Helm Repository Authentication    | GCP      | [Guide][GCP Helm Repository]      |
| Supported | Image Reflector Controller | Container Registry Authentication | AWS      | [Guide][AWS Container Registry]   |
| Supported | Image Reflector Controller | Container Registry Authentication | Azure    | [Guide][Azure Container Registry] |
| Supported | Image Reflector Controller | Container Registry Authentication | GCP      | [Guide][GCP Container Registry]   |
| Supported | Kustomize Controller       | SOPS Integration with Cloud KMS   | AWS      | [Guide][AWS KMS]                  |
| Supported | Kustomize Controller       | SOPS Integration with Cloud KMS   | Azure    | [Guide][Azure KMS]                |
| Supported | Kustomize Controller       | SOPS Integration with Cloud KMS   | GCP      | [Guide][GCP KMS]                  |

## Roadmap

Support for context-based authorization should only increase over time.

For more information, please visit the tracking issue: https://github.com/fluxcd/flux2/issues/3003.


[AWS Buckets]: /flux/components/source/buckets/#aws
[Azure Buckets]: /flux/components/source/buckets/#azure
[GCP Buckets]: /flux/components/source/buckets/#gcp
[AWS OCI Repository]: /flux/components/source/ocirepositories/#aws
[Azure OCI Repository]: /flux/components/source/ocirepositories/#azure
[GCP OCI Repository]: /flux/components/source/ocirepositories/#gcp
[AWS Helm Repository]: /flux/components/source/helmrepositories/#aws
[Azure Helm Repository]: /flux/components/source/helmrepositories/#azure
[GCP Helm Repository]: /flux/components/source/helmrepositories/#gcp
[AWS Container Registry]: /flux/components/image/imagerepositories/#aws
[Azure Container Registry]: /flux/components/image/imagerepositories/#azure
[GCP Container Registry]: /flux/components/image/imagerepositories/#gcp
[AWS KMS]: /flux/guides/mozilla-sops/#aws
[Azure KMS]: /flux/guides/mozilla-sops/#azure
[GCP KMS]: /flux/guides/mozilla-sops/#google-cloud
