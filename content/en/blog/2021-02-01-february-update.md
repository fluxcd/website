---
author: dholbach
date: 2021-02-01 08:30:00+00:00
title: February 2021 Update
description: This month's edition of updates on Flux v2 developments - 0.7 release, Flagger 1.6 release, project and website changes, new events and more.
tags: [monthly-update]
---

## Before we get started, what is GitOps?

If you are new to the community and GitOps, you might want to check out
some general resources. We like the [GitOps
manifesto](https://www.weave.works/blog/what-is-gitops-really) or the
[official GitOps FAQ](https://www.weave.works/blog/the-official-gitops-faq)
written by folks at Weaveworks.

## The Road to Flux v2

The Flux community has set itself very ambitious goals for version 2 and
as it's a multi-month project, we strive to inform you each month about
what has already landed, new possibilities which are available for
integration and where you can get involved. Read last month's update
[here](/blog/2021/01/january-2021-update/).

Let's recap what happened in January - there have been many changes.

## Flux2 v0.7 is here

The Flux2 team is very pleased to bring you the 0.7 release series. Most
importantly these new features have been added:

- The GitOps Toolkit controllers come with dedicated service accounts
  and RBAC (this is a breaking change for those of you who used the
  default SA to bind to IAM Roles).
- All the controller images are now multi-arch (AMD64, ARM64, ARM
  32bit), the `--arch` flag is no longer used when installing Flux.
- You can now set a retry interval for Kustomization reconciliation
  failures.
- In a multi-tenancy setup, health checking and garbage collection are
  now run using the tenant\'s service account.
- The Helm storage namespace can be configured inside the `HelmRelease`
  spec, this is particularly useful when targeting remote clusters.
- The image update automation can be triggered using DockerHub, Quay,
  Nexus, GCR, GHCR, Harbor and generic CI webhooks.
- The image update policy now supports alphabetical sorting (Build
  IDs, CalVer, RFC3339 timestamps) and regex filters.
- The image automation controllers can now be run on ARM devices with
  1GiB RAM including RaspberryPI 32bit.
- Flux bootstrap comes with support for GitLab sub-groups and project
  tokens.

If you have been watching [our roadmap document](/roadmap/), you might
have noticed that we hit the 80% mark of automated image updates
milestone. This means we are getting closer and closer to feature parity
with Flux v1 overall.

Some bits are still on our to-do list, but soon we are going to start
working on a migration guide for this particular feature and
subsequently make a big push in terms of testing and asking for feedback
before we ask everyone to cut over to Flux2. This will be a longer
process for sure - we are just detailing our next steps here, so you're
aware of what's coming next.

## fluxcd.io website updates

In the last months' summaries we talked about our plans of revamping our
[fluxcd.io website](/). Originally it was mostly just
spiffy placeholder page which pointed to more Flux resources. Since then
we landed a new design, made its focus Flux2, now we have added two pages
which should hopefully help new users and aspiring contributors learn
about their options getting help and joining the team

- [Community \| Flux](/community/) and
- [SUPPORT \| Flux](/support/)

Please let us know if there's anything missing or you'd like to help
with the site or docs.

Speaking of support, long-time Flux contributor Kingdon Barrett joined
Weaveworks as OSS Support Engineer and will take on a more active role
in the Flux community. Here's what he has to say

> *\"I have been in the Flux community for some time, though it seems
> like only a short while since I first heard about Flux and started
> getting to know the helpful folks at Weaveworks. Happy to now be
> taking a more active part in the Flux community through my new role as
> the Open Source Support Engineer, I am glad to meet everyone and
> thanks for the welcoming atmosphere! I am here to support the
> community during the transition from Flux v1 into the new supported
> series, for all GitOps practitioners.\"*

Needless to say: we're very excited to have Kingdon with us!

## The Flagger move is happening

Avid readers of our blog might be wondering why we're reporting this
again. It's because the move of Flagger is still happening. Moving the
Github repository and Docker images was just the first, and very
obvious, step.

There are other resources though which are important for its community.
Slack for instance. If you haven't, please join the \#flagger channel on
the [CNCF Slack](https://slack.cncf.io) - this is the new home for Flagger
discussions.

Its website and documentation will be integrated into fluxcd.io at some
point. We also want to update the [scope and description of the Flux
family of projects](https://github.com/fluxcd/flux2/discussions/620) to
encompass Flagger's Progressive Delivery capabilities. Another important
piece is the Flagger logo.

Bianca Cheng Costanzo has been working with the Flux community on a
[proposal for a new flagger
logo](https://github.com/fluxcd/flux2/discussions/653) - it would be
great if you could leave your feedback and let us know how you feel
about it.

## Flagger v1.6 is here

We are very happy to announce the v1.6 release of Flagger. This release
includes:

- Support for A/B testing using [Gloo
  Edge](/flagger/tutorials/gloo-progressive-delivery)
  HTTP headers based routing.
- Extended support for Istio\'s `HTTPMatchRequest` and `VirtualService`
  delegation.
- Support for Kubernetes anti-affinity rules.

Note that starting with Flagger v1.6, the minimum supported version of
Kubernetes is v1.16.0.

## Repository cleanup

Just a heads-up: we have been cleaning up some of our example
repositories. As there are v1 and v2 versions of these under the Flux
organisation, we decided to [archive the v1
versions](https://github.com/fluxcd/community/issues/50) and point to
the corresponding new versions. These are in particular:

- [fluxcd/flux2-kustomize-helm-example: A GitOps workflow example for
   multi-env deployments with Flux, Kustomize and
   Helm.](https://github.com/fluxcd/flux2-kustomize-helm-example)
- [fluxcd/flux2-multi-tenancy: Manage multi-tenant clusters with
   Flux](https://github.com/fluxcd/flux2-multi-tenancy)

Both come with better documentation, diagrams and more features. So a
triple-win for everyone. Be sure to check them out!

## Upcoming events

It's important to us to keep you up to date with new features and
developments in Flux and provide simple ways to see our work in action
and chat with our engineers. In the next days we have these events
coming up for you:

**8 Feb 2021** - [Fluxv2 Image Update Automation Sneak Peak with Leigh
Capili](https://www.meetup.com/GitOps-Community/events/275745174/)

> On the road to feature parity with Flux v1, Image Update Automation is
> a big milestone for Flux v2. The hard at work Flux team has recently
> released this feature as alpha. During this session, Leigh Capili, DX
> Engineer at Weaveworks, will walk us through & demo configuring
> container image scanning and deployment rollouts with Flux v2.
>
> For a container image you can configure Flux to:
>
> - scan the container registry and fetch the image tags
> - select the latest tag based on a semver range
> - replace the tag in Kubernetes manifests (YAML format)
> - checkout a branch, commit and push the changes to the remote Git
>   repository
> - apply the changes in-cluster and rollout the container image
>
> For production environments, this feature allows you to automatically
> deploy application patches (CVEs and bug fixes), and keep a record of
> all deployments in Git history. For staging environments, this feature
> allows you to deploy the latest pre-release of an application, without
> having to manually edit its deployment manifests in Git.

**18 Feb 2021** - [Who wants Cookies? ... and GitOps and Runtime
Security](https://kubesec.aquasec.com/enterprise_online_na_2021)
(*at KubeSec Enterprise Online*)

> There is so much to think about with regard to cluster runtime
> security and your configuration pipeline. A good recipe helps you
> reduce the things you need to think about.
>
> You will learn how to use quality OSS ingredients like Flux and Falco
> to serve a secure platform of gitops goodness the whole team will
> enjoy! You can rest easy in your gitops kitchen knowing no horrible
> geese (exploits, vulnerabilities etc) will burn your cookies.
>
> This talk will be given by
>
> - Dan "POP" Papandrea, Director of Open Source Community and Ecosystem
>   at Sysdig and
> - Leigh Capili, Developer Experience Engineer at Weaveworks

Check out [our calendar section](/#calendar) for more upcoming
and [links to recordings](/resources) of past talks.

## Get involved and join us

If you like what you read and would like to get involved, here are a few
good ways to do that:

- Join our [upcoming dev meetings](/community/#meetings) on
  Feb, 3rd 10:00 UTC, or Feb 11th, 15:00 UT
- Talk to us in the \#flux channel on [CNCF Slack](https://slack.cncf.io/)
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux v2, take a look at our [Get
  Started guide](/flux/get-started/) and give us feedback
- Social media: Follow [Flux on Twitter](https://twitter.com/fluxcd), join the
  discussion in the [Flux LinkedIn group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.
