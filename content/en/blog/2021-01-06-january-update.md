---
author: dholbach
date: 2021-01-06 12:30:00+00:00
title: January 2021 Update
description: This month's edition of updates on Flux v2 developments - 0.5.0 release, Flagger as a Flux project, first Alpha of Image Update functionality, new guides and more.
tags: [monthly-update]
---

**Before we get started, what is GitOps?**
------------------------------------------

If you are new to the community and GitOps, you might want to check out
the [GitOps manifesto](https://web.archive.org/web/20231124194854/https://www.weave.works/blog/what-is-gitops-really)
or the [official GitOps FAQ](https://web.archive.org/web/20231206152723/https://www.weave.works/blog/the-official-gitops-faq).

**The Road to Flux v2**
-----------------------

The Flux community has set itself very ambitious goals for version 2 and
as it's a multi-month project, we strive to inform you each month about
what has already landed, new possibilities which are available for
integration and where you can get involved. Read last month's update
[here](/blog/2020/12/december-update/).

Let's recap what happened in December - there have been many changes.

Flagger moves under the `fluxcd` organization
---------------------------------------------

![Flagger](../../../../img/flagger-gitops.png)

Flagger extends Flux functionality with progressive delivery strategies
like Canary Releases, A/B Testing and Blue/Green and it was specifically
designed for GitOps style delivery.

Since the inception of the GitOps Toolkit, it's clear that `fluxcd/` will
become more of a family of GitOps related projects. The Flagger
maintainers are looking forward to making use of the toolkit components
and simplifying Flagger this way. Consolidating the code-bases and
thinking in terms of a "Flux Family of Projects" and writing up the
roadmap accordingly should benefit both communities as a whole.

The two Flagger maintainers (Stefan Prodan and Takeshi Yoneda) are very
happy to see this happening. Thanks also to Weaveworks for agreeing to transfer
Flagger and its copyright to fluxcd org (and thus, CNCF).

Review the upcoming roadmap for Flagger - it now includes [GitOps
Toolkit integration](https://github.com/fluxcd/flagger#roadmap).

Please help us steer this project forward!

Thanks also to everyone who contributed to the latest two releases:

- Flagger 1.6.0:
  - Add support for A/B testing using Gloo Edge HTTP headers based routing
- Flagger 1.5.0:
  - Flagger can be installed on multi-arch Kubernetes clusters (Linux AMD64/ARM64/ARM).
  - The multi-arch image is available on GitHub Container Registry at
    [ghcr.io/fluxcd/flagger](https://github.com/orgs/fluxcd/packages/container/package/flagger).

**Newest Flux v2 release: 0.5**
-------------------------------

:rocket: :gift: **We\'ve released Flux2 v0.5, this is the
last release for 2020.**

Besides bug fixes and performance
improvements, it comes with many new features. The highlights are:

- Alpha support for automated image updates to Git (thanks to Michael Bridgen - read more in the next paragraph)
- Support for Azure DevOps and the Git v2 protocol (thanks to Philip Laine - more below)
- Support for overriding container images in kustomize-controller (thanks to Somtochi Onyekwere)
- "flux bootstrap" and install commands can now be used on Windows OS without WSL (thanks to Hidde Beydals)
- flux can now be installed on Arch Linux using AUR packages (`flux-bin` or `flux-git` for the latest release) (thanks to Aurel Canciu)

Automated Image Updates
-----------------------

[Automated Image Updates Guide](/flux/guides/image-update/) (alpha release)

Flux v2 now includes two controllers for automating image updates \--
one of the controllers is for scanning container image repositories, and
the other updates and commits changes to YAML config, when there are new
images to deploy.

These are the Flux v2 version of Flux's automation, but work a little
differently. The guide linked above explains how to set it up. Be aware
that this is an alpha release for the image update automation
controllers.

Azure DevOps repository support
-------------------------------

Flux has not been able to support Azure DevOps repositories up until the
0.5 release. This was due to the git library go-git used by
source-controller not supporting specific git capabilities required by
Azure Devops. The same requirements do not exist in the other major git
providers, which is why this was not caught during the initial
development of source-controller.

This resulted in Flux v1 users who used Azure DevOps that were now not
able to migrate to Flux v2. The initial attempt at a solution was to
implement the missing capabilities in the existing library, which turned
into its own epic. Instead the solution was to introduce a
secondary git library libgit2 as it implements the required git
capabilities. It turned out that libgit2 has its own limitations as it
does not currently support shallow cloning, a feature that speeds up the
git polling especially in very large git repositories. The compromise is
to allow the user to choose which git library to use. The majority of
users will be fine with the default original git library, while the
Azure DevOps users will have to specify to use libgit2 in their
GitRepository resources.

Follow [the generic git server
guide](/flux/installation/bootstrap/generic-git-server/)
for further instructions in how to use Flux with Azure DevOps.

Upcoming events
---------------

- 11 Jan 2021 - [Helm + GitOps :zap: :zap: :zap: with Scott Rigby](https://www.meetup.com/GitOps-Community/events/275348736/)

> In this session, Scott will go through the business value as well as
> the technical value for users + demo these benefits especially if you
> use Helm 3 with Flux 2.

**In other news**
-----------------

The Flux community is growing and we are in the middle of a quite a few
big discussions:

- We have [a new guide which explains core concepts](/flux/concepts/) in the Flux world - please give feedback - and thanks Somtochi!
- Flux applies to upgrade to CNCF Incubation status: [https://github.com/cncf/toc/pull/567](https://github.com/cncf/toc/pull/567)

If you like what you read and would like to get involved, here are a few
good ways to do that:

- Join our [upcoming dev meeting](/community/#meetings) on Jan 14
- Talk to us in the \#flux channel on [CNCF Slack](https://slack.cncf.io/)
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux v2, take a look at our [Get Started guide](/flux/get-started/) and give us feedback
- Social media: Follow [Flux on Twitter](https://twitter.com/fluxcd), join the discussion in the [Flux LinkedIn group](https://www.linkedin.com/groups/8985374/)

We are looking forward to working with you.
