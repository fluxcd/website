---
author: dholbach
date: YEAR-XX-01 15:30:00+00:00
title: LAST_MONTH YEAR Update
description: "XX"
url: /blog/YEAR/XX/october-YEAR-update/
tags: [monthly-update]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

As the Flux family of projects and its communities are growing, we
strive to inform you each month about what has already landed, new
possibilities which are available for integration, and where you can get
involved. Read our last update here (xxx).

It's the beginning of MONTH YEAR - let's recap together what
happened in LAST_MONTH - it has been a lot!

## News in the Flux family

### Next Flux release: more stability and performance improvements

### Security news

### Flagger x.y.z

### Flux Ecosystem

<!--

If you add entries to this subsection, please don't use "we" as it gets
confusing from which perspective the whole blog post is written and who
"we" is. The whole post is meant to be from the perspective of the Flux
community. Better to write:]

- "Since the new release of X, it supports Y." or
- "Team lead X says: 'we have put a lot of effort into Y and are
   really proud of the performance results' ..." or
- "The team has been working on ..."

-->

#### Flux Subsystem for Argo

#### Terraform-controller

#### Weave GitOps

#### Azure GitOps

#### VS Code GitOps Extension

#### New additions to the Flux Ecosystem

## Recent & Upcoming Events

It's important to keep you up to date with new features and developments
in Flux and provide simple ways to see our work in action and chat with
our engineers.

### Recent Events (ICYMI) 📺

We feel blessed to have such a big community of users, contributors and
integrators and so many are happy to talk about their experiences. In
LAST_MONTH here are a couple of talks we would like to highlight.

Here is a list of additional videos and topics we really enjoyed -
please let us know if we missed anything of interest and we will make
sure to mention it in the next post!

### Upcoming Events 📆

We are happy to announce that we have a number of events coming up in
MONTH- tune in to learn more about Flux and GitOps best practices,
get to know the team and join our community.

[CNCF Livestream (Aug 17) with Kingdon
Barrett](https://community.cncf.io/events/details/cncf-cncf-online-programs-presents-cloud-native-live-vscode-and-flux-testing-the-new-unreleased-oci-repository-feature/)

The Flux project continues in active development with the addition of
OCI configuration planned in the GA roadmap.

Another Flux advancement has been the creation of the new VSCode
Extension which provides a convenient interface to Flux that can help
reduce friction moving between editor and terminal, alleviating the
headache of context switching overloading developer focus.

Flux maintainer Kingdon Barrett will demonstrate the pre-release of
Flux's new OCI features and a convenient way to access them while they
remain in pre-release so you can provide the feedback that is needed by
Flux maintainers to make this feature a success!

### Flux Bug Scrub

Our Flux Bug Scrubs still are happening on a weekly basis and remain one
of the best ways to get involved in Flux. They are a friendly and
welcoming way to learn more about contributing and how Flux is organised
as a project.

The next dates are going to be:

- [YEAR-xx-yy 12:00 UTC, 14:00 CEST](https://www.meetup.com/weave-user-group/events/wvhvvsydclbnb/)
- [YEAR-xx-yy 12:00 UTC, 14:00 CEST](https://www.meetup.com/weave-user-group/events/wvhvvsydclbgc/)

We are flexible with subjects and often go with the interests of the
group or of the presenter. If you want to come and join us in either
capacity, just show up or if you have questions, reach out to Kingdon on
Slack.

We really enjoyed this [demo of the k3d git
server](https://www.youtube.com/watch?v=hNt3v0kk6ec)
recently. It's a local Git server that runs outside of Kubernetes, to
support offline dev in a realistic but also simple way that does not
depend on GitHub or other hosted services.

## In other news

### Your Community Team

### People writing/talking about Flux

We love it when you all write about Flux and share your experience,
write how-tos on integrating Flux with other pieces of software or other
things. Give us a shout-out and we will link it from this section! ✍

### News from the Website and our Docs

#### Flux Adopters shout-out

We are very pleased to announce that the following adopters of Flux have
come forward and added themselves to our website: xxx

If you have not already done so, [use the instructions
here](/adopters/) or give us a ping and we will help to add you. Not only
is it great for us to get to know and welcome you to our community. It
also gives the team a big boost in morale to know where in the world
Flux is used everywhere.

#### More docs and website news

We are constantly improving our documentation and website - here are a
couple of small things we landed recently:

- ..

Thanks a lot to these folks who contributed to docs and website:

## Flux Project Facts

We are very proud of what we have put together. We want to reiterate
some Flux facts - they are sort of our mission statement with Flux.

1. 🤝 Flux provides GitOps for both apps or
  infrastructure. Flux and Flagger deploy apps with
  canaries, feature flags, and A/B rollouts. Flux can also manage
  any Kubernetes resource. Infrastructure and workload dependency
  management is built-in.
1. 🤖 Just push to Git and Flux does the rest. Flux
  enables application deployment (CD) and (with the help of Flagger)
  progressive delivery (PD) through automatic reconciliation. Flux
  can even push back to Git for you with automated container image
  updates to Git (image scanning and patching).
1. 🔩 Flux works with your existing tools: Flux works with
  your Git providers (GitHub, GitLab, Bitbucket, can even use
  s3-compatible buckets as a source), all major container
  registries, and all CI workflow providers.
1. 🔒 Flux is designed with security in mind: Pull vs. Push,
  least amount of privileges, adherence to Kubernetes security
  policies and tight integration with security tools and
  best-practices. Read more about our security considerations.
1. ☸️ Flux works with any Kubernetes and all common Kubernetes
  tooling: Kustomize, Helm, RBAC, and policy-driven
  validation (OPA, Kyverno, admission controllers) so it simply
  falls into place.
1. 🤹 Flux does Multi-Tenancy (and "Multi-everything"):
  Flux uses true Kubernetes RBAC via impersonation and supports
  multiple Git repositories. Multi-cluster infrastructure and apps
  work out of the box with Cluster API: Flux can use one Kubernetes
  cluster to manage apps in either the same or other clusters, spin
  up additional clusters themselves, and manage clusters including
  lifecycle and fleets.
1. 📞 Flux alerts and notifies: Flux provides health
  assessments, alerting to external systems and external events
  handling. Just "git push", and get notified on Slack and [other
  chat
  systems](https://github.com/fluxcd/notification-controller/blob/main/docs/spec/v1beta1/provider.md).
1. 👍 Users trust Flux: Flux is a CNCF Graduated project
  and was categorised as "Adopt" on the [CNCF CI/CD Tech
  Radar](https://radar.cncf.io/2020-06-continuous-delivery)
  (alongside Helm).
1. 💖 Flux has a lovely community that is very easy to work
  with! We welcome contributors of any kind. The
  components of Flux are on Kubernetes core controller-runtime, so
  anyone can contribute and its functionality can be extended very
  easily.

## Over and out

If you like what you read and would like to get involved, here are a few
good ways to do that:

- Join our [upcoming dev meetings](/community/#meetings) on
  YEAR-XX-XX or YEAR-XX-XX.
- Talk to us in the #flux channel on [CNCF Slack](https://slack.cncf.io/)
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux, take a look at our [Get
  Started guide](/docs/get-started/) and give us feedback
- Social media: Follow [Flux on Twitter](https://twitter.com/fluxcd),
  join the discussion in the [Flux LinkedIn
  group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.
