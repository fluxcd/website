---
author: dholbach
date: 2023-05-02 06:30:00+00:00
title: April 2023 Update
description: "Flux v2 release candidate is out - we want feedback! We went to KubeCon and met many old and new friends - check out our talk videos. cdCon, GitOpsCon and OSS Summit are coming up with more chances to meet us. That plus lots of news from our contributors and ecosystem."
url: /blog/2023/05/april-2023-update/
tags: [monthly-update]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

As the Flux family of projects and its communities are growing, we
strive to inform you each month about what has already landed, new
possibilities which are available for integration, and where you can get
involved. Read [our last update here](/blog/2023/04/march-2023-update/).

It's the beginning of May 2023 - let's recap together what
happened in April - it has been a lot!

## News in the Flux family

### Flux v2.0.0 release candidate

This is the first release candidate of Flux v2.0 GA :tada:.

Users are encouraged to upgrade for the best experience. We also very much
welcome feedback!

Flux v2.0.0-rc.1 comes with the promotion of the GitOps related APIs to
v1 and adds [horizontal scaling & sharding
capabilities](/flux/cheatsheets/sharding/) to Flux controllers.

In addition, RC.1 comes with support for auth with Azure Workload
Identity when pulling OCI artifacts from ACR and when decrypting secret
with Azure Vault. Also, Bootstrap for GitLab was extended with support
for generating [GitLab Deploy
Tokens](/flux/installation/#gitlab-and-gitlab-enterprise).

Big thanks to all the Flux contributors that helped us with this release!

And a special shoutout to the GitLab team for their first contribution to Flux!

This release brings API changes we want to highlight here:

- `GitRepository` v1
- `Kustomization` v1
- `Receiver`v1

The [GitRepository](/flux/components/source/gitrepositories/) kind was
promoted from v1beta2 to v1 (GA) and deprecated fields were removed.
The v1 API is backwards compatible with v1beta2, except for the following:

- the deprecated field `.spec.gitImplementation` was removed
- the unused field `.spec.accessFrom` was removed
- the deprecated field `.status.contentConfigChecksum` was removed
- the deprecated field `.status.artifact.checksum` was removed
- the `.status.url` was removed in favor of the absolute `.status.artifact.url`

The [Kustomization](/flux/components/kustomize/kustomization/) kind was
promoted from v1beta2 to v1 (GA) and deprecated fields were removed. A new
optional field `.spec.commonMetadata` was added to the API for setting
labels and/or annotations to all resources part of a Kustomization. The v1
API is backwards compatible with v1beta2, except for the following:

- the deprecated field `.spec.validation` was removed
- the deprecated field `.spec.patchesStrategicMerge` was removed (replaced by `.spec.patches`)
- the deprecated field .spec.patchesJson6902` was removed (replaced by `.spec.patches`)

The [Receiver](/flux/components/notification/receiver/) kind was promoted
from v1beta2 to v1 (GA). The v1 API now supports triggering the
reconciliation of multiple resources using `.spec.resources.matchLabels`.
The v1 API is backwards compatible with v1beta2, no fields were removed.

To upgrade Flux from `v0.x` to `v2.0.0-rc-1` you can either rerun
[flux bootstrap](/flux/installation/#bootstrap-upgrade)
or use the [Flux GitHub Action](https://github.com/fluxcd/flux2/tree/main/action).

To upgrade the APIs from v1beta2, after deploying the new CRDs and controllers,
change the manifests in Git:

- set `apiVersion: source.toolkit.fluxcd.io/v1` in the YAML files that
  contain `GitRepository` definitions and remove the deprecated fields if any
- set `apiVersion: kustomize.toolkit.fluxcd.io/v1` in the YAML files that
  contain `Kustomization` definitions and remove the deprecated fields if any
- set `apiVersion: notification.toolkit.fluxcd.io/v1` in the YAML files that
  contain Receiver definitions

Bumping the APIs version in manifests can be done gradually. It is advised to not
delay this procedure as the beta versions will be removed after 6 months.

:warning: Note that this release updates the major version of the Flux Go
Module to v2. Please update your `go.mod` to require `github.com/fluxcd/flux2/v2`,
see [pkg.go.dev](https://pkg.go.dev/github.com/fluxcd/flux2/v2) for the
documentation of the module.

New Documentation

- API: [GitRepository v1](/flux/components/source/gitrepositories/)
- API: [Kustomization v1](/flux/components/kustomize/kustomization/)
- API: [Receiver v1](/flux/components/notification/receiver/)

### Flagger: Bug fix release 1.30.0 hits the streets

This release fixes a bug related to the lack of updates to the generated
object's metadata according to the metadata specified in
`spec.service.apex`. Furthermore, a bug where labels were wrongfully
copied over from the canary deployment to primary deployment when no
value was provided for `--include-label-prefix` has been fixed. This
release also makes Flagger compatible with Flux's helm-controller drift
detection.

### Flux Ecosystem

#### Weave GitOps

Weave GitOps has recently released two new versions, v0.21.2 and v0.22.0,
bringing various enhancements and bug fixes to the community.

In [v0.21.2](https://github.com/weaveworks/weave-gitops/releases/tag/v0.21.2),
the release includes client-side apply for better interactivity, removal of
runs in non-session mode, custom SVGs for navigation icons, health checks in
the UI, and more. Alongside these enhancements, bug fixes include resolving
dashboard reconciliation issues and URL checking regex.

In [v0.22.0](https://github.com/weaveworks/weave-gitops/releases/tag/v0.22.0),
enhancements include group claim support for strings, OIDC prefix support for
impersonation, additional health checks, and support for `.sourceignore` for
GitOps Run. Bug fixes address concurrent ID token refreshing, clean-up process
issues, and vulnerabilities in the YAML NPM package.

Weave GitOps Enterprise has introduced v0.21.2 and v0.22.0, offering new
features and improvements. In v0.21.2, users can view GitOpsSets on leaf
clusters in the UI, experience a fixed bug related to GitOpsSets not updating
`ConfigMaps`, and utilize the "View Open Pull Requests” button to select
any `GitRepository`. Enhancements include updating the GoToOpenPullRequest
button and extending unwatch cluster logic for better resource management.
The UI now has a sync external secret button on the secret details page.

In v0.22.0, the new Explorer backend has been introduced, providing better
scalability for Weave GitOps Enterprise. The Explorer now supports Flux
sources, and the Applications UI and Sources UI can be configured to use
the Explorer backend for an improved user experience.

GitOpsSets offer enhanced templating for numbers and object chunks, and
cluster bootstraps now sync secrets without waiting for ControlPlane
readiness. The Explorer collector utilizes impersonation, and a feature flag
has been added for replacing Applications and Sources with the query service
backend. Bug fixes include addressing Git authentication checks,
non-deterministic GitRepository template application, and improved
support for "View Open PRs” in different URL formats.

Documentation updates include instructions for configuring Weave GitOps
Enterprise to create PRs in Azure DevOps and user guides for raw templates
and chart paths.  In addition, updates cover secrets management,
using private Helm repositories, and frontend development process
improvements.

You might be interested in our recent [blog
post](/blog/2023/04/how-to-use-weave-gitops-as-your-flux-ui/) about how to
use Weave GitOps as your Flux UI as well.

#### Terraform-controller

The team has recently released [Terraform
Controller](https://github.com/weaveworks/tf-controller) v0.15.0-rc.1 which
supports Flux v2.0.0-rc.1. This update brings significant improvements and
moves us closer to the Flux GA.

⚠️Important Note:⚠️ With this release, there are breaking changes to be
aware of:

- Terraform Controller now uses API version `v1alpha2`, deprecating
  `v1alpha1`.
- This version is not compatible with Flux v2 v0.41.x and earlier versions.

#### Flux Subsystem for Argo

The team has recently shared a sneak preview of the new version of
[Flamingo](https://github.com/flux-subsystem-argo/flamingo),
a powerful drop-in extension for Argo CD that seamlessly integrates Flux as
a GitOps engine in any Argo CD environments.

Now with the ability to switch between Argo CD UI and Weave GitOps (the UI
for Flux), Flamingo aims to take DevOps and GitOps user experiences to the
next level with this integration.

<video width=650 controls>
   <source
      src="https://github.com/flux-subsystem-argo/website/raw/main/docs/flamingo-wego.mp4"
      type="video/mp4">
   If the video is not displayed, view the video
   <a href="https://github.com/flux-subsystem-argo/website/raw/main/docs/flamingo-wego.mp4">here</a>.
</video>

You might be interested in [this blog
post](https://www.weave.works/blog/flamingo-expand-argo-cd-with-flux) on
the Weaveworks blog about Flamingo.

#### New additions to the Flux Ecosystem

AWS Labs introduced their new project
[`awslabs/aws-cloudformation-controller-for-flux`](https://github.com/awslabs/aws-cloudformation-controller-for-flux).
It is a Flux controller for managing AWS CloudFormation stacks and
helps you to store CloudFormation templates in a git repository and
automatically sync template changes to CloudFormation stacks in your
AWS account with Flux.

Check out the [demo and
example](https://github.com/awslabs/aws-cloudformation-controller-for-flux#demo).

## Recent & Upcoming Events

It's important to keep you up to date with new features and developments
in Flux and provide simple ways to see our work in action and chat with
our engineers.

### cdCon + GitOpsCon North America 2023

[cdCon + GitOpsCon NA 2023](https://events.linuxfoundation.org/cdcon-gitopscon/)
is only a few days away. It will happen May 8-9 in Vancouver, Canada.
Of course Team Flux will be there to talk about all things GitOps!

Here's what we put in our calendar:

- [Niki Manoledaki, Al-Hussein Hameed Jasim: Evaluating the Energy Footprint of
   GitOps Architecture: A Benchmark Analysis](https://sched.co/1Jp7y)
- [Liz Fong & Tamao Nakahara: GitOps Sustainability with Flux &
   ARM64](https://sched.co/1Jp8G)
- [Peter Tran & Nader Ziada: Deliver a Multicloud Application with Flux &
   Carvel](https://sched.co/1Jp8h)
- [Juozas Gaigalas: Platform Engineering Done Right: Safe, Secure & Scalable
   Multi-Tenant GitOps](https://sched.co/1K9a3)
- [Josh & Neeta: Multitenancy - Build Vs. "Buy": Zcaler's
   Journey](https://sched.co/1JpAp)
- [Mohamed Ahmed, Dan Small: High-Security, Zero-Connectivity &
   Air-Gapped Clouds: Delivering Complex Software with the Open Component
   Model & Flux](https://sched.co/1Jp9Q)
- [Peter Wörndle: Managing Software Upgrades with a kpt, GitLab and Flux Workflow
   in a Telecom Context](https://sched.co/1Jp9N)
- [Paulo Frazão: GitOps and Pi](https://sched.co/1JpBJ)
- [Bryan Oliver: Flux at the Point of Change - Using the K8s Golang SDK and
   the Flux API to Automatically Fix and Deploy CVEs in Your Base
   Images](https://sched.co/1JpAF)
- [Kingdon Barrett: Exotic Runtime Targets: Ruby and Wasm on Kubernetes
   and GitOps Delivery Pipelines](https://sched.co/1JpBS)
- [Priyanka Ravi: Automate with Terraform + Flux + EKS: Level Up Your
   Deployments](https://sched.co/1JpAd)
- [Leigh Capili: People > Process > GitOps](https://sched.co/1JpBh)
- [Ivan & Tamao: Kubernetes capabilities for non-Kubernetes
   users](https://sched.co/1JpAy)
- [Priyanka Ravi, Viktor Nagy: GitLab + Flux!](https://sched.co/1JpBk)
- [Dan Garfield, Priyanka Ravi, Mark Waite, Andrea Frittoli & Lori Lorusso:
   Keynote Session:The Graduated Projects Panel](https://sched.co/1Js9F)

### OSS Summit North America 2023

[Open Source Summit NA
2023](https://events.linuxfoundation.org/open-source-summit-north-america/)
is coming up May 10-12 in Vancouver, Canada. It plays host great number of
sub-conferences in many of which you will see Flux goodness happening.

Here are a few that we are looking forward to:

- [Liz Fong & Tamao Nakahara: GitOps Sustainability with Flux and
   arm64](https://sched.co/1K63h)
- [Kingdon Barrett: Exotic Runtime Targets: Ruby and Wasm on Kubernetes and
   GitOps Delivery Pipelines](https://sched.co/1K55z)
- [Tamao: Community Diversity & Inclusion as Business Metric (and not just
   a feel-good tactic)](https://sched.co/1K57j)
- [Kingdon + Will Christensen: Microservices & WASM, Are We There
   Yet?](https://sched.co/1K57U)
- [Mathieu Benoit: Securing Kubernetes Manifests with Sigstore Cosign, What
   Are Your Options?](https://sched.co/1K5Ek)
- [Juozas Gaigalas: Dev-Driven Automated Deployments Like a Cloud Native
   Pro (Even if You're a Beginner)](https://ossna2023.sched.com/event/1K5Eb)
- [Gergely Brautigam, Gerald Morrison: Delivering Secure & Compliant Software
   Components with the Open Component Model & GitOps](https://sched.co/1K5Fx)
- [Mathieu Benoit: Bundling and Deploying Kubernetes Manifests as Container
   Images](https://sched.co/1K5Fx)
- [Priyanka "Pinky" Ravi: Automate with Terraform + Flux](https://sched.co/1Lf96)

### Recent Events (ICYMI) 📺

We feel blessed to have such a big community of users, contributors and
integrators and so many are happy to talk about their experiences. In
April here are a couple of talks we would like to highlight.

#### CloudNativeCon / KubeCon EU 2023

CloudNativeCon / KubeCon is the most important event for us, as it's such
a great venue to meet contributors, friends, end-users and folks who are
generally interested. It was a very busy event and luckily Team Flux was
there as a big group, so we were able to respond to all requests.

{{< gallery match="our-pics/*" sortOrder="desc" rowHeight="150" margins="5"
            thumbnailResizeOptions="600x600 q90 Lanczos"
            previewType="blur" embedPreview=true lastRow="nojustify" >}}

We kicked off the event with the Flux Project Meeting, which saw 4 hours
of updates from the maintainers, lots of time for Q&A, story telling and
a good opportunity to get to know each other.

Next up was the CNCF Graduated Projects Update, here is [the
link](https://www.youtube.com/watch?v=yit0zu8g_O4&t=76s) to the timestamp
where we provided the Flux update.

{{< youtube id="yit0zu8g_O4" >}}

Many folks were looking forward to hear how we envision Flux is used in
an OCI world. Luckily Hidde and Stefan gave a talk about it:

{{< tweet user="stefanprodan" id=1653382756431175681 >}}

{{< youtube id="gKR95Kmc5ac" >}}

We thank the Cloud Native Computing Foundation for setting up a
Graduation Celebration for Argo and Flux, the two GitOps solutions which
graduated around the same time! Cupcake time for everyone!

Last up was a great panel which featured Priyanka Ravi, Weaveworks;
Christian Hernandez, Red Hat; Filip Jansson, Strålfors; Roberth Strand,
Amesto Fortytwo; Leigh Capili, VMware.

They all talked about "How GitOps Changed Our Lives & Can Change Yours Too!".
Priyanka "Pinky", Leigh and Roberth are long-time friends of Flux.

{{< youtube id=hd7VkCLnTWk >}}

And thanks a lot to the Cloud Native Photo Crew, who took [these
pictures](https://www.flickr.com/photos/143247548@N03/):

{{< gallery match="flickr/*" sortOrder="desc" rowHeight="150" margins="5"
            thumbnailResizeOptions="600x600 q90 Lanczos"
            previewType="blur" embedPreview=true >}}

### Upcoming Events 📆

We are happy to announce that we have a number of events coming up in
May - tune in to learn more about Flux and GitOps best practices,
get to know the team and join our community.

#### Flux Bug Scrub

Our Flux Bug Scrubs still are happening on a weekly basis and remain one
of the best ways to get involved in Flux. They are a friendly and
welcoming way to learn more about contributing and how Flux is organised
as a project.

The next dates are going to be:

- [2023-05-03 12:00 UTC, 14:00 CEST](/#calendar)
- [2023-05-11 17:00 UTC, 19:00 CEST](/#calendar)
- [2023-05-16 22:00 UTC,  0:00 CEST (+1)](/#calendar)
- [2023-05-17 12:00 UTC, 14:00 CEST](/#calendar)
- [2023-05-25 17:00 UTC, 19:00 CEST](/#calendar)
- [2023-05-30 22:00 UTC,  0:00 CEST (+1)](/#calendar)
- [2023-05-31 12:00 UTC, 14:00 CEST](/#calendar)

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

### Michael Fornaro joins Flux as a Project Member

We are pleased to announce that [Michael Fornaro](https://github.com/xUnholy/)
has joined Flux as a [project
member](https://github.com/fluxcd/community/blob/main/community-roles.md#project-member).
Michael has been heavily involved in the Flux community, offering valuable
assistance and support through the Slack #flux channels and participating in
Flux Bug Scrub sessions.

In collaboration with Kingdon, Michael is working to expand the Bug Scrub
initiative, recently launching the first AEST session to accommodate members
in Eastern Europe, India, Southeast Asia, and other regions including Australia.

Michael is the founder of [Raspbernetes](https://github.com/raspbernetes) and
co-founder in [K8s@Home](https://github.com/k8s-at-home/), both of which are
organizations that focus on learning and supporting Kubernetes at home. The
community has a strong presence on GitHub and
[Discord](https://discord.gg/sTMX7Vh), where Michael has been a valuable contributor.

### People writing/talking about Flux

We love it when you all write about Flux and share your experience,
write how-tos on integrating Flux with other pieces of software or other
things. Give us a shout-out and we will link it from this section! ✍

**Grafana Operator Blog: [Install Grafana-operator using Flux and Kustomize](https://grafana-operator.github.io/grafana-operator/blog/2023/03/29/install-grafana-operator-using-flux-and-kustomize/)**

The grafana-operator team have recently started to ship their Kustomize
manifests using OCI with the help of Flux artifact. As a part of this,
they have written [a small blog on how to install grafana-operator using
Flux](https://grafana-operator.github.io/grafana-operator/blog/2023/03/29/install-grafana-operator-using-flux-and-kustomize)
and how to manage grafana dashboards as code.

### News from the Website and our Docs

#### Flux Adopters shout-out

We are very pleased to announce that the following adopters of Flux have
come forward and added themselves to our website:
[Alluvial](https://alluvial.finance), [Orange](https://orange.com),
[Kiln](https://kiln.fi), [Tchibo](https://tchibo.de).

If you have not already done so, [use the instructions
here](/adopters/) or give us a ping and we will help to add you. Not only
is it great for us to get to know and welcome you to our community. It
also gives the team a big boost in morale to know where in the world
Flux is used everywhere.

#### More docs and website news

We are constantly improving our documentation and website - here are a
couple of small things we landed recently:

- [Internal documentation](https://github.com/fluxcd/website/tree/main/internal_docs)
  which explains how to use certain parts of the website.
- Updated our announcements for KubeCon EU 2023 and Google
  Season of Docs 2023 to support the events better!
- Updates to the docs to move graduated APIs to `v1`.
- New documentation: [Sharding Cheatsheet](/flux/cheatsheets/sharding/).
- New additions to our [resources page](/resources/).
- Lots of fixes and improvements all over the place.

Thanks a lot to these folks who contributed to docs and website: Stefan
Prodan, Max Jonas Werner, Daniel Favour, Hidde Beydals, Claire Liguori,
David Blaisonneau, Eddie Zaneski, Jan Christoph Ebersbach, Mehdi Bechiri,
Romain Guichard, Sanskar Jaiswal, Stacey Potter, Tim Rohwedder,
harshitasao, lehnerj.

## Flux Project Facts

We are very proud of what we have put together. We want to reiterate
some Flux facts - they are sort of our mission statement with Flux.

1. 🤝 Flux provides GitOps for both apps or
  infrastructure. Flux and [Flagger](https://github.com/fluxcd/flagger)
  deploy apps with canaries, feature flags, and A/B rollouts. Flux
  can also manage any Kubernetes resource. Infrastructure and workload
  dependency management is built-in.
1. 🤖 Just push to Git and Flux does the rest. Flux
  enables application deployment (CD) and (with the help of
  [Flagger](https://github.com/fluxcd/flagger))
  progressive delivery (PD) through automatic reconciliation. Flux
  can even push back to Git for you with automated container image
  updates to Git (image scanning and patching).
1. 🔩 Flux works with your existing tools: Flux works with your Git
   providers (GitHub, GitLab, Bitbucket, can even use s3-compatible
   buckets as a source), all major container registries, fully
   integrates [with OCI](/flux/cheatsheets/oci-artifacts) and all CI
   workflow providers.
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
1. ✨ Dashboards love Flux: No matter if you use one of
   [the Flux UIs](/ecosystem/#flux-uis--guis) or a hosted cloud
   offering from your cloud vendor, Flux has a thriving ecosystem
   of integrations and products built on top of it and all have
   great dashboards for you.
1. 📞 Flux alerts and notifies: Flux provides health
  assessments, alerting to external systems and external events
  handling. Just "git push", and get notified on Slack and [other
  chat systems](/flux/components/notification/provider/).
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
  2023-05-04 or 2023-05-10.
- Talk to us in the #flux channel on [CNCF Slack](https://slack.cncf.io/)
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux, take a look at our [Get
  Started guide](/docs/get-started/) and give us feedback
- Social media: Follow [Flux on Twitter](https://twitter.com/fluxcd),
  join the discussion in the [Flux LinkedIn
  group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.
