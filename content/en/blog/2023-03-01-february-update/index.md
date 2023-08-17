---
author: dholbach
date: 2023-03-01 07:30:00+00:00
title: February 2023 Update
description: "February brings two Flux releases, making steady progress on our road to GA. GitLab adopts Flux for their GitOps capabilities. Truelayer moves to Flux 2 and realises 40x performance improvements. Buzzing Flux Ecosystem and loads of upcoming events to look forward to!"
url: /blog/2023/03/february-2023-update/
tags: [monthly-update]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

As the Flux family of projects and its communities are growing, we
strive to inform you each month about what has already landed, new
possibilities which are available for integration, and where you can get
involved. Read our last update [here](/blog/2023/02/january-2023-update/).

It's the beginning of March 2023 - let's recap together what
happened in February - it has been a lot!

## News in the Flux family

### Two Flux minor releases hit the streets

Last month gave us two minor releases of Flux. Here's what you
can look forward to on your next upgrade. As always: Users are
encouraged to upgrade for the best experience.

#### v0.40: ImageRepository and ImagePolicy promote to v1beta2

[Flux v0.40](https://github.com/fluxcd/flux2/releases/tag/v0.40.0)
brings a number of features and improvements:

- The `GitRepository` API has a new optional field `.spec.ref.name`
  for specifying a Git Reference. This allows Flux to reconcile
  resources from GitHub Pull Requests (`refs/pull/<id>/head`) and
  GitLab Merge Requests (`refs/merge-requests/<id>/head`).  
  [RFC-0005](https://github.com/fluxcd/flux2/tree/main/rfcs/0005-artifact-revision-and-digest)
  (source revision format) and
  [RFC-0003](https://github.com/fluxcd/flux2/tree/main/rfcs/0003-kubernetes-oci)
  (custom OCI media types) have been fully rolled out.
- The `ImageRepository` and `ImagePolicy` APIs have been promoted
  to `v1beta2`.
- The `image-reflector-controller` autologin flags have been
  deprecated, please see the [migration instructions to
  v1beta2](https://github.com/fluxcd/image-reflector-controller/blob/main/CHANGELOG.md#0250).
- Allow specifying the cloud provider contextual login for container
  registries with `ImageRepository.spec.provider`.
- Improve observability of ImageRepository by showing the latest
  scanned tags under `.status.lastScanResult.latestTags`.
- Improve observability of `ImagePolicy` by reporting the current
  and previous image tag in status and events.
- The Kubernetes builtin cluster roles: `view`, `edit` and `admin`
  have been extended to allow access to Flux custom resources.
- Print a report of Flux custom resources and the amount of cumulative
  storage used for each source type with `flux stats -A`.

To read up on the details of the above, you might want to check out
these pieces of documentation:

- API: [ImageRepository v1beta2](/flux/components/image/imagerepositories/)
- API: [ImagePolicy v1beta2](/flux/components/image/imagepolicies/)
- Security: [Aggregated cluster roles](/flux/security/#controller-permissions)

#### v0.39: better security support, improved performance and observability

[Flux v0.39](https://github.com/fluxcd/flux2/releases/tag/v0.39.0) includes
these highlights:

- Starting with this version, the Flux controllers come with [SBOMs and
  SLSA Provenance Attestations](/flux/security/)
  embedded in their container images.
- The [Flux Terraform Provider](https://github.com/fluxcd/terraform-provider-flux)
  has a new resource for bootstrapping Flux, without depending on
  third-party Terraform providers, that allows customising the
  controllers at install time. Users are encouraged to migrate to
  this new resource and provide feedback.
- The Flux CLI is now included in [Wolfi OS](https://github.com/wolfi-dev/os),
  the Linux (Un)distro designed for securing the software supply chain. The
  Chainguard team and Wolfi maintainers are shipping updates for the Flux
  package on a regular basis.

Features and improvements include:

- Recreate immutable resources (e.g. Kubernetes Jobs) by annotating
  or labeling them with `kustomize.toolkit.fluxcd.io/force: enabled`.
- Support for HTTPS bearer token authentication for Git repositories.
- Improve memory usage by disabling the caching of `Secret` and
  `ConfigMap` resources in all controllers.
- Better observability with progressive status updates for Sources
  (Git, OCI, Helm, S3 Buckets).
- Allow extracting the OCI artifact SHA256 digest for Cosign with
  `flux push artifact -o json`.
- Track CRDs managed by Flux, `flux trace` and `flux tree` will show
  which HelmRelease deployed which CRDs.
- Allow the Flux GitHub Action to use a GitHub token when checking
  for updates to avoid rate limiting.

Documentation

- Security: [Software Bill of Materials](/flux/security/#software-bill-of-materials)
- Security: [SLSA Provenance Attestations](/flux/security/#slsa-provenance)
- Security: [Scanning Flux images for CVEs](/flux/security/#scanning-for-cves)

Big thanks to all the Flux contributors that helped us with this release!

### Security news

We extended our [Security Docs](/flux/security/) to show more examples for
verifying SBOMs. Now the newly introduced SLSA Provenance Attestation
feature is documented as well.

### Flagger 1.29.0 brings support for template variables for analysis metrics

A canary analysis metric can reference a set of custom variables with
`.spec.analysis.metrics[].templateVariables`. For more info see the
[docs](/flagger/usage/metrics/#custom-metrics). Furthermore, a bug related
to Canary releases with session affinity has been fixed.

Improvements & Fixes

- Allow custom affinities for flagger deployment in helm chart
- Add namespace to namespaced resources in helm chart
- modify release workflow to publish rc images
- build: Enable SBOM and SLSA Provenance
- Add support for custom variables in metric templates
- docs(readme.md): add additional tutorial
- use regex to match against headers in istio

### Flux Ecosystem

#### Weave GitOps

[The latest release](https://github.com/weaveworks/weave-gitops/releases/tag/v0.17.0)
includes enhancements, improvements, bug fixes, and documentation updates
to enhance Weave GitOps' overall functionality and user experience.

Enhancements in this version include improved detection of the OSS
dashboard and the addition of imagePolicy details. The get-session
logs feature has also been enhanced to support pod logs, filters, and
return logging sources. A new optional tooltip has been added to the
Timestamp component, and the formatting of log message timestamps in
the log UI has been improved.

UI enhancements in this version aim to improve the overall user
experience of Weave GitOps. Access properties on undefined
`ImageAutomation` objects can now be handled, and an issue where
graph nodes hopped around has been fixed. A text search has been
added to table URLs, and undefined icon types can now be handled.

The Helm reloading strategy has been fixed, and the chart spec has
been updated with `values.yaml` to address reloading issues.

#### Terraform-controller

The latest release of TF-Controller, version v0.14.0, introduces
several new features and many bug fixes. Notably, the release offers
first-class support for Terraform Cloud with the `spec.cloud` field. This
enhancement allows Weave GitOps Enterprise users to leverage GitOps
Templates with Terraform Cloud as a backend for their Terraform resources,
opening up a world of possibilities for GitOps workflows.

In addition to Terraform Cloud support, the update upgrades Flux to
v0.40.0 and Terraform to v1.3.9, with bug fixes including improved AWS
package documentation, and missing inventory entries.

The new release also offers multi-arch image support, customizable
controller log encoding, and the option to configure Kube API QPS and
Burst. The Terraform apply stage now features a parallelism option for
even more customization.

Users are highly recommended to upgrade to TF-Controller v0.14.0 to
take advantage of these improvements. For any feedback or questions,
please reach out to the team on [the GitHub
repository](https://github.com/weaveworks/tf-controller).

#### Flux Subsystem for Argo

The team has recently updated
[Flamingo](https://github.com/flux-subsystem-argo/flamingo) by rebasing
it onto the upstream ArgoCD versions v2.3.17, v2.4.23, and 2.5.11. This
update has been made in response to the recent vulnerability
CVE-2023-23947, and the team strongly recommends that all users update
their systems as soon as possible.

Updated Flamingo images are:

- v2.3.17-fl.3-main-bc5b4abb
- v2.4.23-fl.3-main-bc5b4abb
- v2.5.11-fl.3-main-bc5b4abb

#### VS Code GitOps Extension

Version 0.23.0 of the [vscode-gitops-tools
extension](https://github.com/weaveworks/vscode-gitops-tools) was released.
This version introduces a new webview for configuring `GitRepository`,
`HelmRepository`, `OCIRepository`, `Bucket` and `Kustomization` resources.
Extension context (right-click) file and folder actions now work with multiple
open repositories in the expected way.

#### Pulumi Kubernetes Operator

Michel Bridgen wrote a blog post about [how to combine Pulumi with
Flux](/blog/2023/02/flux-pulumi-superpowers/) using the Pulumi Kubernetes
Operator, which extends the reach of both Flux and Pulumi.

What you can look forward to in the next release of the operator is that -
based on Paolo's work on git-go - the operator (and Pulumi itself) [will be able
work with Azure DevOps](https://github.com/pulumi/pulumi/pull/12001).

## Recent & Upcoming Events

It's important to keep you up to date with new features and developments
in Flux and provide simple ways to see our work in action and chat with
our engineers.

### Recent Events (ICYMI) 📺

We feel blessed to have such a big community of users, contributors and
integrators and so many are happy to talk about their experiences. In
February here are a couple of talks we would like to highlight.

Here is a list of additional videos and topics we really enjoyed -
please let us know if we missed anything of interest and we will make
sure to mention it in the next post!

### Upcoming Events 📆

We are happy to announce that we have a number of events coming up in
March - tune in to learn more about Flux and GitOps best practices,
get to know the team and join our community.

- 2nd March: [GitOps Testing in Kubernetes with Flux &
  Testkube](https://www.meetup.com/gitops-community/events/291670250)
- 7th March: [GitOps: Automatic Deployments and Updates with Flux w/
  Julian Hennig](https://www.mirantis.com/labs/gitops-automatic-deployments-and-updates-with-flux/)
- 9th March: [CNCF On Demand- Microservices and
  Kubernetes](https://community.cncf.io/events/details/cncf-cncf-online-programs-presents-cncf-on-demand-webinar-the-path-to-cloud-adoption-and-app-modernization/)
- 15th March: [CNCF Live Stream - Automating Kubernetes
  Deployments](https://community.cncf.io/e/mbmpq8/)
- 16th March: [CNCF On Demand- Kubernetes in 2023 w/ Stefan Prodan &
  Brendan Burns](https://community.cncf.io/events/details/cncf-cncf-online-programs-presents-cncf-on-demand-webinar-kubernetes-in-2023/)
- 23rd March: Microsoft Live Stream: Automating Kubernetes Deployments

### Flux Bug Scrub

Our Flux Bug Scrubs still are happening on a weekly basis and remain one
of the best ways to get involved in Flux. They are a friendly and
welcoming way to learn more about contributing and how Flux is organised
as a project.

The next dates are going to be:

- [2023-03-02 18:00 UTC, 19:00 CEST](/#calendar)
- [2023-03-08 12:00 UTC, 14:00 CEST](/#calendar)
- [2023-03-16 18:00 UTC, 19:00 CEST](/#calendar)
- [2023-03-22 12:00 UTC, 14:00 CEST](/#calendar)

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

### Gitlab adopts Flux for GitOps

{{< tweet user="stefanprodan" id="1618655919449206785" >}}

We are incredibly pleased that GitLab chose to move forward with Flux
for the GitOps capabilities in their project. In the past weeks,
members of the GitLab team joined our Dev meetings where it became
clearer what needs to happen next. This is another great recognition
of the versatility and great feature set of Flux and we very much
look forward to the collaboration.

Please check out [the
announcement](https://about.gitlab.com/blog/2023/02/08/why-did-we-choose-to-integrate-fluxcd-with-gitlab)
on the GitLab blog, which links to all the individual discussions and
development epics where you can track the progress of the integration.

### People writing/talking about Flux

We love it when you all write about Flux and share your experience,
write how-tos on integrating Flux with other pieces of software or other
things. Give us a shout-out and we will link it from this section! ✍

[TrueLayer: Flux2 migration: how we dropped our CPU usage by nearly
40x](https://truelayer.com/blog/flux2-migration-how-we-dropped-cpu-usage-by-nearly-40x)

{{< imgproc truelayer-post Resize 500x >}}
{{< /imgproc >}}

We love hearing end-user success stories, particularly to learn how a
[migration](/flux/migration/) went well. Surya Pandian wrote up the
entire experience in the blog post and comes to this conclusion:

> With our original Flux setup, we were running one pod per GitOps,
> and with 40 teams, that required a lot of cash and CPU. But with
> this setup, we run just one flux GitOps agent for an entire cluster.
> In total, one flux GitOps agent manages over 40 GitRepoCRDResources
> and 240 FluxKustomizeCRDResources.
>
> Our migration to Flux2 has paved the way for a config-managed setup.
> Not only did this drastically reduce costs, but it also made Flux
> reconciliations faster and reduced CPU usage by almost 40x.
>
> As the sun sets on Flux1, migrating to Flux2 may sound like a daunting
> task. But with the right migration plan, engineering teams can reap
> the benefits.

[Flux + Testkube: GitOps Testing is
here](https://testkube.io/blog/flux-testkube-gitops-testing-is-here)

Abdallah Abedraba describes how to set up Flux with Testkube in the
blog post in an easy to follow step-by-step fashion. The takeaway is:

> Once fully realized - using GitOps for testing of Kubernetes applications
> as described above provides a powerful alternative to a more traditional
> approach where orchestration is tied to your current CI/CD tooling and
> not closely aligned with the lifecycle of Kubernetes applications.
>
> This tutorial uses Postman collections for testing an API, but you can
> bring your a whole suite of tests with you to Testkube.

### News from the Website and our Docs

#### Flux Adopters shout-out

We are very pleased to announce that the following adopters of Flux have
come forward and added themselves to our website: [B1 Systems
GmbH](https://www.b1-systems.de/) and [Wildlife
Studios](https://wildlifestudios.com/).

If you have not already done so, [use the instructions
here](/adopters/) or give us a ping and we will help to add you. Not only
is it great for us to get to know and welcome you to our community. It
also gives the team a big boost in morale to know where in the world
Flux is used everywhere.

#### More docs and website news

We are constantly improving our documentation and website - here are a
couple of small things we landed recently:

- Bootstrapping: here's how to [disable Kubernetes cluster role
  aggregations](/flux/installation/configuration/multitenancy/#flux-cluster-role-aggregations)
- Update [image-updates guide](/flux/guides/image-update/) to reflect the new
  API version and recent use of flags, extend examples.

- We updated the docs to reflect current Flux version and fixed typos
  and readability pieces in many many places.
- We updated our [Security Docs](/flux/security).

Thanks a lot to these folks who contributed to docs and website: Ben
Bodenmiller, Stefan Prodan, Stefan Bodenmiller, Michael Bridgen,
Hidde Beydals, Sunny, Kingdon Barrett, Mac Chaffee, Ronan, Sanskar
Jaiswal, zipizapclouds.

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
  2023-03-09 or 2023-03-15.
- Talk to us in the #flux channel on [CNCF Slack](https://slack.cncf.io/)
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux, take a look at our [Get
  Started guide](/flux/get-started/) and give us feedback
- Social media: Follow [Flux on Twitter](https://twitter.com/fluxcd),
  join the discussion in the [Flux LinkedIn
  group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.
