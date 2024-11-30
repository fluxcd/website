---
author: dholbach
date: 2021-04-29 06:30:00+00:00
title: May 2021 update
description: Flux v2 has its first anniversary and reaches the 0.13 milestone, Alison joins maintainers, new guides and use-cases docs, upcoming events (yes we'll be at KubeCon!) and general community news!
url: /blog/2021/04/may-2021-update/
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
tags: [monthly-update]
---

## Before we get started, what is GitOps?

If you are new to the community and GitOps, you might want to check out
some general resources. We like ["What is GitOps?"](https://web.archive.org/web/20231124194854/https://www.weave.works/blog/what-is-gitops-really)
or ["The Official GitOps FAQ"](https://web.archive.org/web/20231206152723/https://www.weave.works/blog/the-official-gitops-faq)
written by folks at Weaveworks.

## The Road to Flux v2

The Flux community has set itself very ambitious goals for version 2 and
as it's a multi-month project, we strive to inform you each month about
what has already landed, new possibilities which are available for
integration and where you can get involved. Read last month's update
[here](/blog/2021/03/april-2021-update/).

Let's recap what happened in April - there has been so much happening!

### It's the one-year anniversary of Flux v2

Incredible, but true. The first experimentation around Flux v2 started
about a year ago. It was only meant to be a proof of concept to
illustrate that a set of small and targeted controllers could replace
all of Flux eventually. We celebrate how far we have come: Flux v2 is
closer to GA, and already solves more problems than v1. It's far
more flexible, ships more features and is easier to navigate and debug.
What's even more important is that our community has grown considerably
since then. We have more maintainers from more organisations on board,
more documentation and are looking forward to having you on the team as
well!

Thanks a lot to everyone who contributed so Flux v2 so far!

### We added many long-requested features

0.12 had the following highlights:

- New bootstrap git command for pairing Flux with any Git
  platform (CLI)
- Improvements to GitHub and GitLab bootstrap including self-signed
  certs (CLI)
- Support for Git submodules (source-controller)
- GPG signing of image update commits (image-automation-controller)
- Fixes to commit templates and new branch push
  (image-automation-controller)
- Extend SOPS with support for age encryption format
  (kustomize-controller)
- Support for sending alerts to Sentry and Webex
  (notification-controller)
- Alerts deduplication and events rate limiting
  (notification-controller)
- A container image with `kubectl` and `flux` is available on
  DockerHub and GitHub

The Flux v2 CLI and the GitOps Toolkit controllers are now CII Best
Practices certified.

Checkout the [new bootstrap
procedure](/flux/installation/bootstrap/generic-git-server/).

0.13 comes with **breaking changes to image automation** and has the
following highlights:

- The image automation APIs have been promoted to `v1alpha2`.
  Users are encouraged to test this image automation beta candidate,
  and give feedback before we move these APIs to beta (after which
  there will be no further breaking API changes)
- Allow pre-bootstrap customisation of Flux components (CLI)
- Improved efficiency of Bucket downloads by including
  `.sourceignore` rules during bucket item downloads
  (source-controller)
- New command to list all Flux resources `flux get all
  --all-namespaces` (CLI)
- Support for CRDs upgrade policies (helm-controller)
- Support for SSH keys with a passphrase (source-controller)
- Send alerts to HTTPS servers with self-signed certs
  (notification-controller)
- The HelmChart `ValueFile` field has been deprecated in favour of
  `ValuesFiles` (source-controller)
- Support for decrypting Kubernetes Secrets generated with SOPS
  and Kustomize `secretGenerator` (kustomize-controller)

Please follow the [upgrade procedure for image
automation](https://github.com/fluxcd/flux2/discussions/1333).

Checkout the [new bootstrap customisation
feature](/flux/installation/configuration/boostrap-customization/).

The [Image automation guide](/flux/guides/image-update/) has been updated
to the new APIs, and also includes a reference to a
new [GitHub Actions use case guide](/flux/use-cases/gh-actions-auto-pr/),
for automatic pull request creation with Flux and GitHub Actions. This
guide is for you, if you want Flux updates to go to a staging branch,
where they can be reviewed and approved before going to production.

## Flagger v1.8.0

Until now [Flagger](/flagger) was compatible with Linkerd
which implements the [Service Mesh Interface](https://smi-spec.io) (SMI) `v1alpha1`.
Starting with v1.8.0, Flagger extends the SMI support for the
`v1alpha2` and `v1alpha3` APIs.
This means Flagger can be used to automate canary releases with
progressive traffic shifting for **Open Service Mesh**,
**NGINX Service Mesh**, **Consul Connect**,
and any other service mesh conforming to SMI.

More features have been included in v1.8.0 release,
please see the [changelog](https://github.com/fluxcd/flagger/blob/main/CHANGELOG.md#180).

If you want to get hands-on experience with GitOps (Flux v2) and Progressive Delivery (Flagger),
check out Stefan's blog post:
[A GitOps recipe for Progressive Delivery with Istio](https://dev.to/stefanprodan/a-gitops-recipe-for-progressive-delivery-2pa3).

## Upcoming events

It's important to us to keep you up to date with new features and
developments in Flux and provide simple ways to see our work in action
and chat with our engineers. In the next days we have these events
coming up for you:

It's **[KubeCon EU
2021](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/)**
and because we are now an incubating project Flux will have a booth at
the project pavilion for the first time! Stop by the booth to chat with
us and [check out our booth schedule](https://bit.ly/Flux_KubeConEU2021) of talks with various users, contributors, and maintainers.

The Flux maintainers will be speaking during the conference as well:

- **03 May 2021** - [GitOpsCon EU 2021](https://hopin.com/events/gitops-con) -
  KubeCon Day 0 co-located event organized by the GitOps Working Group.
  Co-hosted by Scott Rigby, Weaveworks and Chris Short, Red Hat.
  You must be [registered](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/program/colocated-events/#gitops-con) to attend

  > GitOps Con Europe (#GitOpsCon) is designed to foster collaboration, discussion and knowledge sharing on GitOps.
  > This event is aimed at audiences that are new to GitOps as well as those currently using GitOps within their organization.
  > Get connected with others that are passionate about GitOps.
  > Learn from practitioners about pitfalls to avoid, hurdles to jump, and how to adopt GitOps in your cloud native environment.

- **04 May 2021** - [Meet the Maintainer - Stefan Prodan](https://sched.co/is3b) -
  you must be [registered here](https://community.cncf.io/e/m8rfv8/) to attend this
  session.

- **05 May 2021** - [Keynote: CNCF Project Update: Flux - Stefan
  Prodan](https://sched.co/j7Dr) at KubeCon 2021 Europe.

- **05 May 2021** - [Helm Users! What Flux 2 Can Do For
  You](https://sched.co/iE1e) - Scott Rigby & Kingdon Barrett, Weaveworks

  > Helm, the Package manager for Kubernetes. Flux, the GitOps continuous
  > delivery solution for Kubernetes. Both can be used independently, but
  > are more powerful together. Scott Rigby, Helm and Flux maintainer ---
  > and Kingdon Barrett, OSS engineer --- will share the benefits of Helm
  > and GitOps for developers, with live demos showcasing the extra
  > awesomeness of Flux v2 and Helm together. This talk is for Helm users
  > who have either never used Flux, or Flux v1 users looking forward to
  > new features in Flux v2.

- **06 May 2021** - [Flux: Multi-tenancy Deep Dive - Philip
  Laine](https://kccnceu2021.sched.com/event/iona) at KubeCon 2021 Europe

  > Flux is a tool for keeping Kubernetes clusters in sync with sources of
  > configuration (like Git repositories) and automating updates to the
  > configuration when there is new code to deploy. In this presentation,
  > we will look at how Flux can be used in multi-tenant environments to
  > simplify the day to day work of developers and Kubernetes cluster
  > operators.

- **07 May 2021** - [Meet the Maintainer - Aurel
  Canciu](https://sched.co/irBD) - you must be [registered
  here](https://community.cncf.io/e/m4zbxu/) to attend this session

Still a bit further down the line, but this will definitely be worth
your time: an entire two-day conference about the newest developments in
the GitOps world with Keynotes from Justin Cormack (CTO, Docker), Katie
Gamanji (Ecosystem Advocate, CNCF), and Lei "Harry" Zhang (Staff
Engineer at Alibaba Cloud).

- **09-10 Jun 2021** - [GitOps Days 2021](https://www.gitopsdays.com)

Check out [our calendar section](/#calendar) for more upcoming
and [links to recordings](/resources) of past talks.

## In other news

### Our website has grown

Since the start of Flux v2 we wanted to make good documentation front
and center of what we do. For a while now we published all the guides
and API docs at toolkit.fluxcd.io. For a time now we knew that this was
confusing, so we started the work on moving everything to
<https://fluxcd.io>.

We are very pleased to announce that we succeeded in moving the docs and
now offer community information, our blog and many other useful bits on
the website, everything is searchable and we look forward to adding
more.

The team who has been working on this is looking for help, so if you
have a knack for fixing typos, improve grammar, add short guides or work
on graphics or make the layout more user-friendly, please talk to us in
the `#flux` Slack channel and/or send a pull request to
[fluxcd/website](https://github.com/fluxcd/website).

Looking forward to growing the team! 💖

### Alison Dowdney joins the maintainer team

Alison has been part of the Flux project for quite a while now. Not only
did she [present Flux at meetups](https://youtu.be/cakxixc-yQk), fix bugs
and add documentation in the last months. She also helped out with the
website and has a long background in working with communities in the
Kubernetes space. Recently she took on the role of chair in k8s SIG
Contributor Experience as well!

![Alison](alison-featured.jpg)

We feel very fortunate to have Alison on board!

### Over and out

If you like what you read and would like to get involved, here are a few
good ways to do that:

- Join our [upcoming dev meetings](/community/#meetings) on
  2021-05-12 12:00 UTC, or 2021-05-20 15:00 UTC
- Talk to us in the \#flux channel on [CNCF Slack](https://slack.cncf.io/)
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux v2, take a look at our [Get
  Started guide](/flux/get-started/) and give us feedback
- Social media: Follow [Flux on Twitter](https://twitter.com/fluxcd), join the
  discussion in the [Flux LinkedIn group](https://www.linkedin.com/groups/8985374/)

We are looking forward to working with you.
