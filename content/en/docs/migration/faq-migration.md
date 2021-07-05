---
title: FAQ
linkTitle: FAQ
description: "Flux and Helm Operator migration frequently asked questions."
weight: 100
---

## v1 and v2

### What does Flux v2 mean for Flux?

Flux v1 is a monolithic do-it-all operator; Flux v2 separates the
functionalities into specialized controllers, collectively called the GitOps Toolkit.

You can install and operate Flux v2 simply using the `flux` command.
You can easily pick and choose the functionality you need and extend it to serve your own purposes.

The timeline we are looking at right now is:

1. Put Flux v1 into maintenance mode (no new features being added; bugfixes and CVEs patched only).
1. Continue work on the [Flux v2 roadmap](/docs/roadmap/).
1. We will provide transition guides for specific user groups, e.g. users of Flux v1 in read-only mode, or of Helm Operator v1, etc. once the functionality is integrated into Flux v2 and it's deemed "ready".
1. Once the use-cases of Flux v1 are covered, we will continue supporting Flux v1 for 6 months. This will be the transition period before it's considered unsupported.

### Why did you rewrite Flux?

Flux v2 implements its functionality in individual controllers,
which allowed us to address long-standing feature requests much more easily.

By basing these controllers on modern Kubernetes tooling (`controller-runtime` libraries),
they can be dynamically configured with Kubernetes custom resources either by cluster admins
or by other automated tools -- and you get greatly increased observability.

This gave us the opportunity to build Flux v2 with the top Flux v1 feature requests in mind:

- Supporting multiple source Git repositories
- Operational insight through health checks, events and alerts
- Multi-tenancy capabilities, like applying each source repository with its own set of permissions

On top of that, testing the individual components and understanding the codebase becomes a lot easier.

### Are there any breaking changes?

- In Flux v1 Kustomize support was implemented through `.flux.yaml` files in the Git repository. As indicated in the comparison table above, while this approach worked, we found it to be error-prone and hard to debug. The new [Kustomization CR](https://github.com/fluxcd/kustomize-controller/blob/master/docs/spec/v1beta1/kustomization.md) should make troubleshooting much easier. Unfortunately we needed to drop the support for custom commands as running arbitrary shell scripts in-cluster poses serious security concerns.
- Helm users: we redesigned the `HelmRelease` API and the automation will work quite differently, so upgrading to `HelmRelease` v2 will require a little work from you, but you will gain more flexibility, better observability and performance.

### Is the GitOps Toolkit related to the GitOps Engine?

In an announcement in August 2019, the expectation was set that the Flux project would integrate the GitOps Engine, then being factored out of ArgoCD. Since the result would be backward-incompatible, it would require a major version bump: Flux v2.

After experimentation and considerable thought, we (the maintainers) have found a path to Flux v2 that we think better serves our vision of GitOps: the GitOps Toolkit. In consequence, we do not now plan to integrate GitOps Engine into Flux.

## Helm Operator and Helm Controller

### Are automated image updates supported?

Not yet, but the feature is under active development. See the [image update feature parity section on the roadmap](/docs/roadmap/#flux-image-update-feature-parity) for updates on this topic.

### How do I automatically apply my `HelmRelease` resources to the cluster?

If you are currently a Flux v1 user, you can commit the `HelmRelease` resources to Git, and Flux will automatically apply them to the cluster like any other resource. It does however not support automated image updates for Helm Controller resources.

If you are not a Flux v1 user or want to fully migrate to Flux v2, the [Kustomize Controller](/docs/components/kustomize/controller/) will serve your needs.

### I am still running Helm v2, what is the right upgrade path for me?

Migrate your Helm v2 releases to v3 using [the Helm Operator's migration feature](/legacy/helm-operator/helmrelease-guide/release-configuration/#migrating-from-helm-v2-to-v3), or make use of the [`helm-2to3`](https://github.com/helm/helm-2to3) plugin directly, before continuing following the [migration steps](#steps).

### Is the Helm Controller ready for production?

Probably, but with some side notes:

1. It is still under active development, and while our focus has been to stabilize the API as much as we can during the first development phase, we do not guarantee there will not be any breaking changes before we reach General Availability. We are however committed to provide [conversion webhooks](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/#webhook-conversion) for upcoming API versions.
1. There may be (internal) behavioral changes in upcoming releases, but they should be aimed at further stabilizing the Helm Controller itself, solving edge case issues, providing better logging, observability, and/or other improvements.

### Can I use Helm Controller standalone?

Helm Controller depends on [Source Controller](../components/source/_index.md), you can install both controllers
and manager Helm releases in a declarative way without GitOps.
For more details please see this [answer]({{< relref "/faq.md#can-i-use-flux-helmreleases-without-gitops" >}}).

### I have another question

Given the amount of changes, it is quite possible that this document did not provide you with a clear answer for you specific setup. If this applies to you, do not hesitate to ask for help in the [GitHub Discussions](https://github.com/fluxcd/flux2/discussions/new?category_id=31999889) or on the [`#flux` CNCF Slack channel](https://slack.cncf.io)!

### How can I get involved?

There are a variety of ways and we look forward to having you on board building the future of GitOps together:

- [Discuss the direction](https://github.com/fluxcd/flux2/discussions) of Flux v2 with us
- Join us in #flux-dev on the [CNCF Slack](https://slack.cncf.io)
- Check out our [contributor docs](/contributing/)
- Take a look at the [roadmap for Flux v2](/docs/roadmap/)
