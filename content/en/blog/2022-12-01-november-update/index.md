---
author: dholbach
date: 2022-12-05 12:30:00+00:00
title: November 2022 Update
description: "Flux graduates within the CNCF. Flux consolidates Git implementation. Flux GA Roadmap updates. New Flagger releases. Ecosystem updates. KubeCon Review and lots more community news."
url: /blog/2022/12/november-2022-update/
aliases: [/blog/2022/12/october-2022-update/]
tags: [monthly-update]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

As the Flux family of projects and its communities are growing, we
strive to inform you each month about what has already landed, new
possibilities which are available for integration, and where you can get
involved. Read [our last update here](/blog/2022/11/october-2022-update/).

It's the beginning of December 2022 - let's recap together what
happened in November - it has been a lot!

## News in the Flux family

### Flux has graduated

![Flux is CNCF Graduated project](flux-graduation-featured.png)

It's been quite the journey, and it wouldn't have been possible without
everybody's help in our community. We made it! Flux is now officially a
CNCF Graduated project. Here are some news pieces you might want to check
out:

- [CNCF Press Release](https://www.cncf.io/announcements/2022/11/30/flux-graduates-from-cncf-incubator/)
- [Our very own announcement in the Flux blog](/blog/2022/11/flux-is-a-cncf-graduated-project/)
- [Flux Reaches Graduation at the CNCF (weave.works blog)](https://www.weave.works/blog/flux-reaches-graduation-at-the-cncf)
- [Cloud-nativ: Flux reitet auf der GitOps-Welle zum Graduate-Status der CNCF (heise.de - german)](https://www.heise.de/news/Cloud-nativ-Flux-reitet-auf-der-GitOps-Welle-zum-Graduate-Status-der-CNCF-7363399.html)
- [Cloud Native Podcast announces Flux Graduation episode](https://twitter.com/cloudnativefm/status/1598032539033165825)
- [Business Wire: Flux Graduates in the CNCF](https://www.businesswire.com/news/home/20221130006111/en/Weaveworks%E2%80%99-GitOps-Project-%E2%80%93-Flux-%E2%80%93-Graduates-in-the-Cloud-Native-Computing-Foundation)
- [IT Ops Times: Flux Graduates from the CNCF Incubator](https://www.itopstimes.com/kubernetes/flux-graduates-from-the-cncf-incubator/)

Please help us share the good news - it's the moment of recognition and
endorsement many have still been waiting for!

Also please join us for our celebratory Flux Graduation AMA sessions:

- [December 7, 12:00 UTC](/#calendar) with Flux maintainers: Daniel, Max,
  Philip, Sanskar, Stefan, Somtochi
- [December 8, 18:00 UTC](/#calendar) with Flux maintainers: Kingdon,
  Paulo, Somtochi, Soulé

### Next Flux release brings consolidated Git implementation

The Flux development team keeps on innovating. The latest release is
[Flux v0.37](https://github.com/fluxcd/flux2/releases/tag/v0.37.0) and as
always we encourage you all to upgrade for the best experience.

The biggest change is that the `gitImplementation` field of `GitRepository`
by source-controller and image-automation-controller is now deprecated.
Flux will effectively always use `go-git`. This now supports all Git
servers, including Azure DevOps and AWS CodeCommit, which previously were
only supported by `libgit2`. This is a big improvement and will help us focus
on making Flux work great with just one git implementation.

Here is our shortlist of features and improvements in the release:

- Support for bootstrapping Azure DevOps and AWS CodeCommit repositories
  using `flux bootstrap git`.
- Support cloning of Git v2 protocol (Azure DevOps and AWS CodeCommit) for
  `go-git` Git provider.
- Support force-pushing `ImageUpdateAutomation` repositories.
- Allow a dry-run of `flux build kustomization` with `--dry-run` and
  `--kustomization-file ./path/to/local/my-app.yaml`. Using these flags,
  variable substitutions from Secrets and ConfigMaps are skipped, and no
  connection to the cluster is made.
- Use signed OCI Helm chart for
  [kube-prometheus-stack](/flux/guides/monitoring/).

Check out these new pieces of documentation:

- Guide: [AWS CodeCommit bootstrap](/flux/use-cases/aws-codecommit/)
- Guide: [Azure DevOps
  bootstrap](/flux/installation/bootstrap/azure-devops/)

💖 Big thanks to all the Flux contributors that helped us with this
release!

### Flux Roadmap Updates

Here's an update from the [Flux roadmap](/roadmap) - we are rushing
forward towards GA!

Starting with release v0.37, we started solidifying all required changes
for the Bootstrap GA milestone targeted to Q1 2023. That release should
include all major changes from a Git perspective that we want to ship
for GA. Please make sure you upgrade as soon as possible and provide us
with feedback, so we can work on it before the GA release.

Upcoming in the next release is a new feature for Image Automation
Controller: `GitShallowClones`. You can already check it out in the
recently published release candidate. If you are interested, you can
reach out via the PR or on Slack:
<https://github.com/fluxcd/image-automation-controller/pull/463>

### Security news

To benefit from our strong OCI integration, you might want to take a
look at our latest blog post about [how to verify the integrity of
Helm charts stored as OCI
artifacts](/blog/2022/11/verify-the-integrity-of-the-helm-charts-stored-as-oci-artifacts-before-reconciling-them-with-flux/).

To help you tighten security, the Kubernetes community has released
the [security-profiles-operator
project](https://github.com/kubernetes-sigs/security-profiles-operator).
We are very pleased that it now comes with an [AppArmor profile for
Flux](https://github.com/kubernetes-sigs/security-profiles-operator/blob/main/examples/apparmorprofile-flux-controllers.yaml).

### Flagger 1.25 and 1.26 update to newest Gateway API

[Flagger 1.26.0](https://github.com/fluxcd/flagger/releases/tag/v1.26.0)
comes with support Kubernetes [Gateway API](https://gateway-api.sigs.k8s.io/)
`v1beta1`. For more details see the [Gateway API Progressive Delivery
tutorial](https://fluxcd.io/flagger/tutorials/gatewayapi-progressive-delivery/).
Please note that starting with this version, the Gateway API v1alpha2 is
considered deprecated and will be removed from Flagger after 6 months.

[Flagger 1.25.0](https://github.com/fluxcd/flagger/releases/tag/v1.25.0)
introduces a new deployment strategy combining Canary releases with
session affinity for Istio. Check out the tutorial [here](https://fluxcd.io/flagger/tutorials/istio-progressive-delivery/#session-affinity). Furthermore, it contains a regression fix
regarding metadata in alerts introduced in
[#1275](https://github.com/fluxcd/flagger/pull/1275).

### Flux Ecosystem

#### Flux Subsystem for Argo

The team upgraded [Flux Subsystem for
Argo](https://github.com/flux-subsystem-argo/flamingo) aka Flamingo to
support Flux v0.37 and Argo CD v2.5.3, v2.4.17, v2.3.11 and v2.2.16.

#### Terraform-controller

The team has released [Weave
TF-controller](https://github.com/weaveworks/tf-controller) v0.13.1 and
recently updated its Helm chart to v0.9.3. In this version, the team
started shipping the AWS Package for TF-controller. The AWS Package is
an OCI Image which contains a set of Terraform primitive modules that you
can use out-of-the-box to provision your Terraform resources by describing
them as YAML.Please visit the package repository for more information:
<https://github.com/tf-controller/aws-primitive-modules>.

#### Weave GitOps

[GitOps Run](https://docs.gitops.weave.works/docs/gitops-run/overview/)
continues to be enhanced as an easy way to get started with Flux and GitOps,
and now includes yaml validation for both Flux and core Kubernetes resources.
The Weave GitOps UI for Flux is now able to support multiple instances of Flux
on the same cluster, for when resource isolation strategies are in place, so
you can see the health of all controllers in the Flux Runtime view.

Then in the Enterprise edition of Weave GitOps, [the Pipelines
feature](https://docs.gitops.weave.works/docs/pipelines/getting-started/) is
now enabled by default to help you automatically promote applications through a
series of environments, and GitOpsTemplates continue to be enhanced as a generic
self-service capability for building out an Internal Developer Platform.

#### VS Code GitOps Extension

In its latest pre-release of [the
extension](https://github.com/weaveworks/vscode-gitops-tools) a
"Configure GitOps" workflow was introduced. It features a new unified
user interface for creating Source and Workload and for attaching Workloads
to Sources. It supports both Generic Flux and Azure Flux (Arc/AKS)
cluster modes. In Azure mode, `FluxConfig` resources are created
automatically (this can be disabled if the user wants Generic mode
compatibility). Currently this feature is in the Extension Marketplace
pre-release channel and supports `GitRepository` and `Kustomization`
resources.

If you want a user-friendly UI for working with every type of Source
and Workflow please check out this pre-release and give the team feedback!

## Recent & Upcoming Events

It's important to keep you up to date with new features and developments
in Flux and provide simple ways to see our work in action and chat with
our engineers.

### Recent Events (ICYMI) 📺

We feel blessed to have such a big community of users, contributors and
integrators and so many are happy to talk about their experiences. In
November here are a couple of talks we would like to highlight.

- [Nov 16: Flux Security & Scalability using VS Code GitOps
Extension](https://youtu.be/Bmh7kKYLIhY)
- [Nov 29: WOUG: OCI - Flux ease with helm charts and Flux (Part
2)](https://youtu.be/uRiCRTSkPOQ)
- [Nov 30: HashiCorp User Group (Luxembourg): GitOps Your Terraform
Configurations with
Flux](https://youtu.be/JHmQlSvL0II)

[Playlist: Flux at Prometheus Day, GitOpsCon, & KubeCon North America 2022](https://youtube.com/playlist?list=PLwjBY07V76p4qczDNgH08GQVdzgcwXpdY)

[This
playlist](https://youtube.com/playlist?list=PLwjBY07V76p4qczDNgH08GQVdzgcwXpdY)
is a curated compilation of all Flux related talks from KubeCon /
CloudNativeCon NA 2022 (Detroit) as well as the respective co-located
events, Prometheus Day and GitOpsCon. We've also included a list of the
individual videos below.

#### Prometheus Day North America 2022

- [Automate Your SLO Validation with Prometheus & Flagger - Sanskar
   Jaiswal & Kingdon Patrick Barrett](https://youtu.be/Wgp04xTNqq4)

#### GitOpsCon North America 2022

- [How to Achieve (Actual) GitOps with Terraform and Flux - Priyanka
  Ravi, Weaveworks](https://youtu.be/EXp2xAbII_k)
- [Toward Full Adoption of GitOps and Best Practices at RingCentral -
  Ivan Anisimov & Tamao
  Nakahara](https://youtu.be/h8G3LM9uIHk)
- [Simplifying Edge Deployments Using EMCO and GitOps - Igor DC &
  Adarsh Vincent Chittilappilly,
  Intel](https://youtu.be/cYcmXCJ2tLU)
- [Complete DR of Stateful Workloads, PVs and CSI Snapshots via Flux
  and Vault OSS - Kingdon
  Barrett](https://youtu.be/jRil9H1NhZI)
- [GitOps with Flux and OCI Registries - Soulé Ba & Scott Rigby,
  Weaveworks](https://youtu.be/Ums3Q9kMPd8)
- [Flux + Observability: Featuring Prometheus Operator and Pixie -
  Somtochi Onyekwere,
  Weaveworks](https://youtu.be/G1Mt4KE4Dao)

#### KubeCon North America 2022

- [Flagger, Linkerd, And Gateway API: Oh My! - Jason Morgan, Buoyant
  & Sanskar Jaiswal,
  Weaveworks](https://youtu.be/9Ag45POgnKw)
- [Tutorial: How To Write a Reconciler Using K8s
  Controller-Runtime! - Scott Rigby, Somtochi Onyekwere, Niki
  Manoledaki & Soulé Ba, Weaveworks; Amine Hilaly, Amazon Web
  Services](https://youtu.be/Npvz84HpO3o)
- [Flux Maturity, Feature, and Contrib Update - Kingdon Barrett &
  Somtochi Onyekwere,
  Weaveworks](https://youtu.be/PhV5dJtTaDw)

Here is a list of additional videos and topics we really enjoyed -
please let us know if we missed anything of interest and we will make
sure to mention it in the next post!

### Upcoming Events 📆

We are happy to announce that we have a number of events coming up in
December- tune in to learn more about Flux and GitOps best practices,
get to know the team and join our community.

- [Dec 13: Implementing Flux for Scale with Soft
Multi-tenancy](https://www.meetup.com/weave-user-group/events/289768509)

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

- [2022-12-08 18:00
   UTC](https://www.meetup.com/weave-user-group/events/290045754/)
- [2022-12-14 13:00 UTC](/#calendar)
- [2022-12-22 18:00 UTC](/#calendar)

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

The [Flux Community
Team](https://github.com/fluxcd/community/blob/main/COMMUNITY.md) has been
busy this month. We wrapped-up everything related to KubeCon, prepared the
announcement of Flux Graduation and wrote this summary.

We would love your help, so if you are interested in joining a small team
which handles Community and Communications of Flux, please join our meetings
and introduce yourself!

### People writing/talking about Flux

We love it when you all write about Flux and share your experience,
write how-tos on integrating Flux with other pieces of software or other
things. Give us a shout-out and we will link it from this section! ✍

Josh Carlisle wrote [this blog
post](https://www.joshcarlisle.io/2022/11/20/cloud-native-platform-recipe-success/)
as a decision making help for people who are new to Cloud Native. He says

> I came away with Flux offering some easier onboarding and boostrapping

and

> I found Flux to better align with things that were important to me

Thanks for the shout-out!

### News from the Website and our Docs

#### Flux Adopters shout-out

We are very pleased to announce that the following adopters of Flux have
come forward and added themselves to our website: [Amesto
Fortytwo](https://amestofortytwo.com),
[DataGalaxy](https://www.datagalaxy.com/),
[Divistant](https://divistant.com/), [DKB Deutsche
Kreditbank AG](https://dkb.de), [Housing
Anywhere](https://housinganywhere.com),
[synyx](https://synyx.de/).

If you have not already done so, [use the instructions
here](/adopters/) or give us a ping and we
will help to add you. Not only is it great for us to get to know and
welcome you to our community. It also gives the team a big boost in
morale to know where in the world Flux is used everywhere.

#### More docs and website news

We are constantly improving our documentation and website - here are a
couple of small things we landed recently:

- Following the deprecation of Flux Legacy, we have removed the Flux
  Legacy docs and [highlighted migration videos and other
  helpful content](/flux/migration/)
- To make it easier to participate, we now show the upcoming event on
  the landing page
- Show adopters logos in horizontal scroll band
- Updated [Flagger docs](/flagger/) to 1.25.0
- Updated [AWS CodeCommit docs](/flux/use-cases/aws-codecommit/)
- Updated [Azure docs](/flux/use-cases/azure/)
- Added [GitOpsCon talk videos](/resources/)
- Many other improvements and fixes

Thanks a lot to these folks who contributed to docs and website: Stefan
Prodan, Arhell, Vanessa Abankwah, David Harris, Sanskar Jaiswal, Batuhan
Apaydın, Max Jonas Werner, André Kesser, Marko Petrovic, Matthieu
Dufourneaud, Paul Lockaby, Paulo Gomes, Piotr Sobieszczański, Roberth
Strand, Tarun Rajpurohit, husni6, surya.

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
  2022-12-07 or 2022-12-15.
- Talk to us in the #flux channel on [CNCF Slack](https://slack.cncf.io/)
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux, take a look at our [Get
  Started guide](/flux/get-started/) and give us feedback
- Social media: Follow [Flux on Twitter](https://twitter.com/fluxcd),
  join the discussion in the [Flux LinkedIn
  group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.
