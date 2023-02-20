---
author: dholbach
date: 2022-08-02 11:30:00+00:00
title: July 2022 Update
description: "Flux's upcoming release will bring improved OCI support and more stability. Flagger adds KEDA support. We celebrated out ever increasing ecosystem. On top of that: security best-practices, more docs, videos and contributor news!"
url: /blog/2022/08/july-2022-update/
tags: [monthly-update]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

As the Flux family of projects and its communities are growing, we
strive to inform you each month about what has already landed, new
possibilities which are available for integration, and where you can get
involved. Read our [last update here](/blog/2022/07/june-2022-update/).

It's the beginning of August 2022 - let's recap together what happened
in July - it has been a lot!

## News in the Flux family

### Next Flux release: OCI Helm improvements and consolidated Git implementations

The whole Flux team is busy working on the v0.32.x Flux release that's
planned for early August. A lot of our planned changes have already
landed and what you can look forward to is: OCI for Kubernetes manifests
and further enhancements to the OCI for Helm support that shipped
already are also included. Support for Cosign will not be included in
this release just yet, but will come later.

It's not too late to provide early feedback for the [OCI
support](https://github.com/fluxcd/flux2/issues?q=rfc-0003),
we still need more user engagement/feedback to guarantee this feature is
ready for release.

We have planned on this release finally decommissioning our `libgit2`
Unmanaged Transport and replacing it with the new Managed Transport (it
will no longer be experimental, now default!)

The upgrade to managed transport should be opaque and seamless for the
end user. Hopefully Flux users will notice things are more stable, but
no changes are needed in order to take advantage of this upgrade, other
than simply upgrading.

### Security news

When we started writing about [Security in Flux](/tags/security/), folks
started asking us more questions about how to ensure their Flux
deployments were secure. We are happy to announce that we documented
[Flux's Security Best Practices](/flux/security/best-practices/)
on our website. It comes with a simple checklist that you can follow to
ensure you implemented it. You can also go deeper and expand the text
blocks to understand the rationale and backgrounds better.

Please let us know if you have any questions or feedback - we are happy
to add to this section.

### Flagger 1.22 brings KEDA Support

{{< imgproc keda Resize 400x >}}
{{< /imgproc >}}

This Flagger release is a big one. It comes with support for KEDA
ScaledObjects as an alternative to HPAs.
[KEDA](https://keda.sh/) is a CNCF Incubation project and
is supported in e.g. Azure. Check out our
[tutorial](https://docs.flagger.app/tutorials/keda-scaledobject)
to understand how to use it with Flagger.

Other improvements in the release are:

- The `.spec.service.appProtocol` field can now be used to specify the
  [appProtocol](https://kubernetes.io/docs/concepts/services-networking/service/#application-protocol)
  of the services that Flagger generates.
- A bug related to the Contour prometheus query for when service name
  is overwritten along with a bug related to Contour `HTTPProxy`
  annotations have been fixed.
- The installation guide for Alibaba ServiceMesh has been updated.

Read the full list of improvements and fixes in [the
1.22.0](https://github.com/fluxcd/flagger/blob/main/CHANGELOG.md#1220)
and
[1.22.1](https://github.com/fluxcd/flagger/blob/main/CHANGELOG.md#1221)
changelog entries.

### Flux Ecosystem

#### Flux Subsystem for Argo

The team released Flux Subsystem for Argo by rebasing it to Argo CD v2.2.11,
which contains many serious security fixes. They verified that this
version of FSA worked with recent versions of Flux, including Flux v2
0.31.4.

#### Terraform-controller

The authors had been identifying performance bottlenecks in the TF controller.
Now with the bottlenecks identified, they have been able to start
rewriting the certification rotation component to improve the
performance of the controller. The performance improvement is expected
to land by the mid of August.

Their [most recent release
0.10.0](https://github.com/weaveworks/tf-controller/releases/tag/v0.10.0)
contains the following improvements:

- Add support for Terraform Enterprise
- Implement resource inventory
- Improve security to make the images work with Weave GitOps
  Enterprise
- Re-implement certificate rotator
- Correct IRSA docs
- Update Kubernetes libraries to v0.24.3, `go-restful` to fix
  CVE-2022-1996
- Add pprof to the /debug/pprof endpoint
- Fix race condition to make sure that gRPC client and the runner use
  the same TLS

#### VS Code GitOps Extension

In our last monthly updates we talked about the GitOps Extension for VS
Code that is based on top of Flux. If you always wanted to see it in
action to be able to understand what it can do for you, check out our
recent blog post which contains the [VSCode Extension Demo from GitOps
Days](/blog/2022/07/gitopsdays-vscode-extension-demo/).

#### Weave GitOps

The team is working towards a new release of Weave GitOps OSS. They've made
some quality of life improvements in our latest release
[v0.9.1](https://github.com/weaveworks/weave-gitops/releases/tag/v0.9.1).
I\'m so glad you asked. This is a CLI command in Weave GitOps OSS that
will make it simpler to get started with Flux and GitOps. In addition,
it enables live feedback while configuring your cluster. They are aiming
for simplicity for those that are new to Kubernetes and GitOps. They are
looking for beta testers so if you know anyone that might be interested
then please have them sign up
[here](https://forms.gle/dkHhoZfwaLv52RM17).

On the Enterprise side they are getting close to enhance and extend the
flux tenant model, providing the user with capabilities to create
tenants from a declarative yaml that can be versioned. Enabling platform
teams to create isolated tenants with boundaries. Define allowed
sources, targets. RBAC and policy with a single tool.

#### Azure GitOps

Azure GitOps now supports Flux v2 in Azure Kubernetes Service (AKS) and
Azure Arc-enabled Kubernetes (Arc K8s) clusters ([blog
post](https://techcommunity.microsoft.com/t5/azure-arc-blog/announcing-general-availability-for-gitops-with-flux-v2-in-azure/ba-p/3408051)).
Azure lets customers use the same managed Flux service for their cluster
configuration and application deployment across all their clusters --
Azure, on-premises, multi-cloud. The Azure team works closely with
Weaveworks to improve upstream Flux (e.g., multi-tenancy) and continues
the partnership.

{{< imgproc azure-gitops Resize 800x >}}
{{< /imgproc >}}

#### New additions to the Flux Ecosystem

We redesigned [our Ecosystem page](/ecosystem)! Up until recently we simply listed
tools, extensions and integrations that either simplified using Flux in
various contexts or extended its functionality.

What was missing was the great work a lot of companies have done to
bring GitOps to their users in the form of products and services. We now
show a list of these and logos for those who approved the use of logos.
If you are in the market for a complete GitOps solution, go check it
out!

{{< imgproc ecosystem1 Resize 600x >}}
{{< /imgproc >}}

Another big topic in our user community is the one of UIs. We now added
a section with screenshots to give you a good idea of what your options
are and how they can simplify your workflow.

{{< imgproc ecosystem2 Resize 600x >}}
{{< /imgproc >}}

We realise that some ecosystem entries might be missing - if you find
one, please send a PR, we want this page to grow!

## Recent & Upcoming Events

It's important to keep you up to date with new features and developments
in Flux and provide simple ways to see our work in action and chat with
our engineers.

### Recent Events (ICYMI) 📺

We feel blessed to have such a big community of users, contributors and
integrators and so many are happy to talk about their experiences. In
July here are a couple of talks we would like to highlight.

Check out the recent CNCF livestream with Kingdon Barrett and Priyanka
Ravi, [Enhance your GitOps Experience with Flux Tools &
Extensions](https://community.cncf.io/events/details/cncf-cncf-online-programs-presents-cloud-native-live-enhance-your-gitops-experience-with-flux-tools-extensions/).

In addition to that we recently started discussing a number of great
talks from last month's GitOps Days in blog posts. Check out these
posts - they contain a summary of the talks and show the videos as well:

- Weaveworks Blog: [GitOps Days 2022 recap: major clouds & vendors offering GitOps
  with
  Flux](https://www.weave.works/blog/gitops-days-2022-recap-major-clouds-vendors-offering-gitops-with-flux)
- CNCF Blog: [How to apply GitOps to everything with Crossplane and Flux](https://www.cncf.io/blog/2022/07/26/how-to-apply-gitops-to-everything-with-crossplane-and-flux/)
- CNCF Blog: [Keep calm and trust A/B testing with Flux, Flagger, and Linkerd](https://www.cncf.io/blog/2022/07/21/keep-calm-and-trust-a-b-testing-with-flux-flagger-and-linkerd/)
- CNCF Blog: [GitOps with Flux at Safaricom](https://www.cncf.io/blog/2022/07/28/gitops-with-flux-at-safaricom/)

Please let us know if we missed anything of interest and we will make
sure to mention it in the next post!

### Upcoming Events 📆

We are happy to announce that we have a number of events coming up in
August - tune in to learn more about Flux and GitOps best practices, get
to know the team and join our community.

[CNCF Livestream (Aug 17) with Kingdon
Barrett](https://community.cncf.io/events/details/cncf-cncf-online-programs-presents-cloud-native-live-vscode-and-flux-testing-the-new-unreleased-oci-repository-feature/)

> The Flux project continues in active development with the addition of
> OCI configuration planned in the GA roadmap.
> Another Flux advancement has been the creation of the new VSCode
> Extension which provides a convenient interface to Flux that can help
> reduce friction moving between editor and terminal, alleviating the
> headache of context switching overloading developer focus.
>
> Flux maintainer Kingdon Barrett will demonstrate the pre-release of
> Flux\'s new OCI features and a convenient way to access them while they
> remain in pre-release so you can provide the feedback that is needed by
> Flux maintainers to make this feature a success!

### Flux Bug Scrub

Our Flux Bug Scrubs still are happening on a weekly basis and remain one
of the best ways to get involved in Flux. They are a friendly and
welcoming way to learn more about contributing and how Flux is organised
as a project.

The next dates are going to be:

- [2022-08-10 12:00 UTC, 14:00
  CEST](https://www.meetup.com/de-DE/weave-user-group/events/wvhvvsydclbnb/)
- [2022-08-24 12:00 UTC, 14:00
  CEST](https://www.meetup.com/de-DE/weave-user-group/events/wvhvvsydclbgc/)

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

### News from the Website and our Docs

#### Flux Adopters shout-out

We are very pleased to announce that the following adopters of Flux have
come forward and added themselves to our website:
[Mintmesh](https://www.mintmesh.ai/) and
[SenseLabs](https://senselabs.de/).

If you have not already done so, [use the instructions
here](/adopters/) or give us a ping and we
will help to add you. Not only is it great for us to get to know and
welcome you to our community. It also gives the team a big boost in
morale to know where in the world Flux is used everywhere.

#### More docs and website news

We added a [Troubleshooting
cheatsheet](/flux/cheatsheets/troubleshooting/)!
This has been a request from our community for a long time and we would
love to hear your feedback! What do you and your team use for incidents?
Is it playbooks? What would you expect in Flux docs for managing
incidents and troubleshooting?

We are constantly improving our documentation and website - here are a
couple of small things we landed recently:

- New use-case: [GitHub Actions Basic App
  Builder](/flux/use-cases/gh-actions-app-builder/):\
  This guide shows how to configure GitHub Actions to build an image
  for each new commit pushed on a branch, for PRs, or for tags in
  the most basic way that Flux's automation can work with and making
  some considerations for both dev and production.\
  A single GitHub Actions workflow is presented with a few
  variations but one simple theme: Flux's only firm requirement for
  integrating with CI is for the CI to build and push an image. So
  this document shows how to do just that.
- We expanded our documentation on Azure to include [Using Helm OCI
  with Azure Container
  Registry](/flux/use-cases/azure/#using-helm-oci-with-azure-container-registry).
- Flagger news! We updated the docs on our website to match the newest
  version of Flagger (1.22). This adds a tutorial for how to do
  [Canary analysis with KEDA
  SealedObjects](/flagger/tutorials/keda-scaledobject/).
  In addition to that the install guides were updated, in particular
  the instructions for [setting up Flagger on Alibaba
  ServiceMesh](/flagger/install/flagger-install-on-alibaba-servicemesh/)
  was simplified quite a bit.
- We updated the resources section on the fluxcd.io landing page to
  show updated content with more breadth across the Flux space.
- We updated to a more recent version of the Docsy theme, which
  allowed us to drop some of our own customisations. With this we
  also updated to the new version of the Algolia API - this should
  give you better search results as well.
- And lots of other small improvements.

Thanks a lot to these folks who contributed to docs and website: Paulo
Gomes, Kingdon Barrett, Ihor Sychevskyi, Max Jonas Werner, Santosh
Kaluskar, Stefan Prodan, Hidde Beydals, Jonathan Innis, Soulé Ba, Stacey
Potter, \@chengleqi and \@kirankldevops.

### Archival of Flux Web UI

The [fluxcd/webui project was
archived](https://github.com/fluxcd/webui/pull/65). It was
in active development from November 2020 to June 2021, but unfortunately
it could not be kept alive. This is why we felt the need to point users
to the following alternatives for UIs for Flux instead.

1. [Weaveworks](https://www.weave.works) offers a free
   and open source GUI for Flux under the
   [weave-gitops](https://github.com/weaveworks/weave-gitops)
   project.
   \
   ![weave-gitops-flux-ui](/ecosystem/img/weave-gitops3.png)
   \
   You can install the Weave GitOps UI
   using a Flux HelmRelease, please see the [Weave GitOps
   documentation](https://docs.gitops.weave.works/docs/getting-started/intro/)
   for more details.
1. The Flux community maintains a series of Grafana dashboards for
   monitoring Flux.\
   \
   ![flux-grafana](/img/cluster-dashboard.png)
   \
   See [the monitoring section of the Flux
   documentation](/flux/guides/monitoring/)
   for how to install Flux\'s Grafana dashboards.

### New Flux Project Member: Ihor Sychevskyi

{{< imgproc arhell Resize 400x >}}
{{< /imgproc >}}

We are very pleased to welcome Ihor Sychevskyi as a project member into
the Flux family. Over the past months Ihor has been busy improving our
website in many many places. A lot of small UI glitches all over the
place fell into this category and if you view fluxcd.io on mobile the
site is getting better all the time!

Be like Ihor: If you have contributed to Flux and are interested in
joining the Flux project as a member, please take a look at [our
governance documentation for
this](https://github.com/fluxcd/community/blob/main/community-roles.md#project-member).

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
1. 👍 Users trust Flux: Flux is a CNCF Incubating project
  and was categorised as \"Adopt\" on the [CNCF CI/CD Tech
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
  2022-08-03 or 2022-08-11.
- Talk to us in the \#flux channel on [CNCF Slack](https://slack.cncf.io/)
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux, take a look at our [Get
  Started guide](/flux/get-started/) and give us feedback
- Social media: Follow [Flux on Twitter](https://twitter.com/fluxcd), join the
  discussion in the [Flux LinkedIn
  group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.
