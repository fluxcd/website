---
title: Core Concepts
description: Core Concepts of Flux.
weight: 10
---

These are some core concepts in Flux.

## GitOps

GitOps is a way of managing your infrastructure and applications so that whole system
is described declaratively and version controlled (most likely in a Git repository),
and having an automated process that ensures that the deployed environment
matches the state specified in a repository.

For more information, take a look at the following resources:

* [What is GitOps?](https://www.gitops.tech/#what-is-gitops)
* [GitOps Principles](https://opengitops.dev/#principles)

## Gitless GitOps

Gitless GitOps was pioneered by the Flux team [back in 2022](https://github.com/fluxcd/flux2/pull/2601)
with the introduction of the [OCIRepository](flux/components/source/ocirepositories/) source type and
Flux OCI Artifact media type.

In the Gitless GitOps model, the Flux controllers are fully decoupled from Git, relying solely on container registries
as the source of truth for the desired state of Kubernetes clusters. From a user perspective, Git remains the primary
interface for managing the desired state, but the underlying implementation leverages OCI-compliant registries
to store and distribute the configuration artifacts.
This approach allows for greater flexibility and scalability, the Git server is no longer a production dependency,
while the OCI registry becomes the unified source of truth for all configuration artifacts, SBOMs,
cryptographic signatures, and app images.

For more information, take a look at the following resources:

* [Flux OCI Artifacts documentation](/flux/cheatsheets/oci-artifacts/)
* [OCI Bootstrap with Flux Operator](/flux/installation/#bootstrap-with-flux-operator)

## GitOps Toolkit (gotk)

In Flux, GitOps Toolkit refers to a collection of specialized tools, Flux Controllers, composable APIs,
and reusable Go packages available under the fluxcd GitHub organization. These components are designed
for the purpose of constructing Continuous Delivery workflows on Kubernetes using GitOps principles.
The GitOps Toolkit serves as the foundation for managing and automating the deployment and configuration
of applications and infrastructure within a Kubernetes cluster, promoting a declarative and version-controlled
approach to operations.

For more information, take a look at [GitOps Toolkit components](/flux/components/).

## Sources

A *Source* defines the origin of a repository containing the desired state of 
the system and the requirements to obtain it (e.g. credentials, version selectors). 
For example, the latest `1.x` tag available from a Git repository over SSH.

Sources produce an artifact that is consumed by other Flux components to perform
actions, like applying the contents of the artifact on the cluster. A source
may be shared by multiple consumers to deduplicate configuration and/or storage.

The origin of the source is checked for changes on a defined interval, if
there is a newer version available that matches the criteria, a new artifact
is produced.

All sources are specified as Custom Resources in a Kubernetes cluster, examples
of sources are `GitRepository`, `OCIRepository`, `HelmRepository` and `Bucket` resources. 

For more information, take a look at
[the source controller documentation](components/source/_index.md).

## Reconciliation

Reconciliation refers to ensuring that a given state (e.g. application running in the cluster, infrastructure)
matches a desired state declaratively defined somewhere (e.g. a Git repository).

There are various examples of these in Flux:

- `OCIRepository` reconciliation: downloads and stores the contents of the OCI Artifact on a given
  interval, and records the observed digest and tag in the status of resource.
- `HelmRelease` reconciliation: ensures the state of the Helm release matches what is defined in the resource,
  performs a release if this is not the case (including revision changes of a HelmChart resource).
- `Kustomization` reconciliation: ensures the state of the application
  deployed on a cluster matches the resources defined in a Git or OCI repository or S3 bucket.

## Kustomization

The `Kustomization` custom resource represents a local set of Kubernetes resources
(e.g. kustomize overlay) that Flux is supposed to reconcile in the cluster.
The reconciliation runs every five minutes by default, but this can be changed with `.spec.interval`.
If you make any changes to the cluster using `kubectl edit/patch/delete`,
they will be promptly reverted. You either suspend the reconciliation or push your changes to a Git repository.

For more information, take a look at the [Kustomize FAQ](faq.md#kustomize-questions)
and the [Kustomization CRD](/flux/components/kustomize/kustomizations/).

## Bootstrap

The process of installing the Flux components in a GitOps manner is called a bootstrap.
The manifests are applied to the cluster, a `GitRepository` and `Kustomization`
are created for the Flux components, then the manifests are pushed to an existing Git repository
(or a new one is created). Flux can manage itself just as it manages other resources.
The bootstrap is done using the `flux` CLI or
using our [Terraform Provider](https://github.com/fluxcd/terraform-provider-flux).

For more information, take a look at [the bootstrap documentation](/flux/installation/bootstrap/).

## Continuous Delivery

Continuous Delivery refers to the practice of delivering software updates frequently and reliably. 

For more information, take a look at continuous delivery as defined in the [CNCF](https://glossary.cncf.io/continuous-delivery/).

## Continuous Deployment

Continuous Deployment is the practice of automatically deploying code changes to production
once they have passed through automated testing. 

For more information, take a look at continuous delivery as defined in the [CNCF Glossary](https://glossary.cncf.io/continuous-delivery/).

## Progressive Delivery

Progressive Delivery builds on Continuous Delivery by gradually rolling out new features or
updates to a subset of users, allowing developers to test and monitor the new features in
a controlled environment and make necessary adjustments before releasing them to everyone.

Developers can use techniques like feature flags, [canary releases](https://glossary.cncf.io/canary-deployment/), and A/B testing
to minimize the chances of introducing bugs or errors that could harm users or interrupt
business operations. These strategies enable a controlled and gradual rollout of new features,
ensuring a smooth and successful release that enhances user trust and improves the overall user experience.

The Flux project offers a specialised controller called [Flagger](https://github.com/fluxcd/flagger) that implements
various progressive delivery techniques.
For more information, take a look at [Flagger deployment strategies](https://fluxcd.io/flagger/usage/deployment-strategies/).
