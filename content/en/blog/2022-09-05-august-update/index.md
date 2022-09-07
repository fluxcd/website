---
author: dholbach
date: 2022-09-05 11:30:00+00:00
title: August 2022 Update
description: "Flux added OCI support and better integration with cloud services. Lots of updates from our ecosystem. Resources and upcoming events on how to benefit from OCI support. We welcome Leigh Capili as Flux Project member and lots more news from our community!"
url: /blog/2022/09/august-2022-update/
tags: [monthly-update]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

As the Flux family of projects and its communities are growing, we
strive to inform you each month about what has already landed, new
possibilities which are available for integration, and where you can get
involved. Read our [last update here](/blog/2022/08/july-2022-update/).

It's the beginning of September 2022 - let's recap together what
happened in August - it has been a lot!

## News in the Flux family

### New Flux releases add OCI support and better integration with cloud services

August saw two big releases of Flux:
[v0.33](https://github.com/fluxcd/flux2/releases/tag/v0.33.0)
and
[v0.32](https://github.com/fluxcd/flux2/releases/tag/v0.32.0).
Let's go through the major changes one by one.

- Enable contextual login to container registries when pulling Helm
  charts from Amazon Elastic Container Registry, Azure Container
  Registry and Google Artifact Registry using
  [`HelmRepository.spec.provider`](/docs/components/source/helmrepositories/#provider).
- Select which layer contains the Kubernetes configs by specifying a
  matching OCI media type using
  [`OCIRepository.spec.layerSelector`](/flux/components/source/ocirepositories/#layer-selector).
- Authenticate to Azure Blob storage with SAS tokens using
  [`Bucket.spec.secretRef`](/flux/components/source/buckets/#azure-blob-sas-token-example).
- Allow filtering OCI artifacts by semver and regex when listing
  artifact with `flux list artifacts`.
- Allow excluding local files and directories when building and
  publishing artifacts with `flux push artifact`.
- New Flux CLI commands `flux push|pull|tag` artifact for publishing
  OCI Artifacts to container registries.
- New source type
  [`OCIRepository`](/flux/components/source/ocirepositories/)
  for fetching OCI artifacts from container registries.
- Resolve Helm dependencies from OCI for charts defined in Git.

The big news was of course that we added support for distributing
Kubernetes manifests, Kustomize overlays and Terraform code as OCI
artifacts. For more information on OCI support please see the [Flux
documentation](/docs/cheatsheets/oci-artifacts/).

Big thanks to the Flux contributors that helped us along the way. It
took us almost 4 months, from the first RFC version to shipping OCI
support today. And a special thanks to Rashed and the whole VMware Tanzu
team for the excellent collaboration!

{{< tweet user=stefanprodan id=1564999901657894912 >}}

{{< tweet user=stefanprodan id=1557754198648913921 >}}

### Security news

We are continuously putting effort into the security story of Flux. One
cornerstone of this is fuzzing of all code. As
[promised](/blog/2022/02/security-more-confidence-through-fuzzing/#whats-next),
we started [transitioning our fuzz
tests](https://github.com/fluxcd/flux2/issues/2417) to the
native Go implementation.

We are happy to say that we managed to contribute back to Google's
`oss-fuzz` improving Go Native Fuzz implementation as well during this
effort ([patch
1](https://github.com/google/oss-fuzz/pull/8238), [patch
2](https://github.com/google/oss-fuzz/pull/8285)).

### Flagger 1.22.2

[Flagger 1.22.2](https://github.com/fluxcd/flagger/releases/tag/v1.22.2)
received a patch release as well during August. It fixes a bug related
to scaling up the canary deployment when a reference to an auto-scaler
is specified.

Furthermore, it contains updates to packages used by the project,
including updates to Helm and grpc-health-probe used in the load-tester.

A number of CVEs originating from its dependencies were fixed as well.

### Flux Ecosystem

#### Flux Subsystem for Argo

Flux added `OCIRepository` as a new kind of Source in its recent release.
The new version of [Flux Subsystem for Argo
(FSA)](https://github.com/flux-subsystem-argo/flamingo) brings these good bits
of Flux to Argo CD. The team has also recently upgraded FSA to Argo CD
v2.2.12 to contain recent security bug fixes again. This version of Flux
Subsystem for Argo requires Flux v0.32.0 to install.

{{< imgproc fsa Resize 600x >}}
{{< /imgproc >}}

#### Terraform-controller

The team has released [TF-controller
v0.11](https://github.com/weaveworks/tf-controller/blob/main/CHANGELOG.md#v0110)
which now supports Flux OCIRepository. To use Flux `OCIRepository` with
TF-controller, you're required to upgrade Flux to v0.32+.

{{< imgproc tf-controller1 Resize 600x >}}
{{< /imgproc >}}

In addition to the new `OCIRepository` support, the TF-controller team is
glad to announce that the performance of TF-controller has been improved
significantly. Now the controller is greatly scalable to reconcile and
provision high volumes of Terraform modules concurrently. The team has
recently tested the controller with 1,500 Terraform modules.

{{< imgproc tf-controller2 Resize 600x >}}
{{< /imgproc >}}

#### Weave GitOps

The team at Weaveworks is continuing to invest in Applications first! They’ve
focused this quarter on building and improving the primitives that make up
Weave GitOps. Their aim is to make it easy for platform operators to simplify
adoption of Kubernetes and Cloud Native in general across their engineering
organization. An easy to use platform that is extensible and safe for
organizations to meet their needs.

The OSS team released
[v0.9.4](https://github.com/weaveworks/weave-gitops/releases/tag/v0.9.4).
There are a lot of iterative improvements in the app such as the ability to
pause and resume multiple sources or automation objects from the UI. In
addition, there are a bunch of tiny UI and visual improvements. Getting
started is now simpler due to a new `gitops create dashboard` command for
producing the `HelmRelease` and `HelmRepository` objects. Plus, some
foundational improvements for `gitops run`.

On the enterprise side they are wrapping up workspaces including the GUI, that
gives you a single pane of glass what applications and policies belong to which
tenant! That makes governance for Platform teams easy and enables Application
teams to operate efficiently in safe boundaries. In addition, they have a new
add application experience that makes it easy to use Kustomizations and Helm
Charts via their UI. Now you have a single simple flow to add your
workloads/applications independently if it’s k8s manifest in a Git Repository
or Helm Charts. Look for an upcoming release (v0.9.4) in the next week for
these two items.

#### VS Code GitOps Extension

Anyone who loves the GitOps Extension for VS Code should update to the
latest version. Among other things it just received a number of security
fixes. Find the relevant details on its [advisories
page](https://github.com/weaveworks/vscode-gitops-tools/security/advisories).

## Recent & Upcoming Events

It's important to keep you up to date with new features and developments
in Flux and provide simple ways to see our work in action and chat with
our engineers.

### Recent Events (ICYMI) 📺

We feel blessed to have such a big community of users, contributors and
integrators and so many are happy to talk about their experiences. In
August here are a couple of talks we would like to highlight.

**CNCF Livestream with Kingdon Barrett: VSCode and Flux: Testing the new
OCI Repository feature**

> The Flux project continues in active development with the addition of
> OCI configuration planned in the GA roadmap. Another Flux advancement
> has been the creation of the new VSCode Extension which provides a
> convenient interface to Flux that can help reduce friction moving between
> editor and terminal, alleviating the headache of context switching
> overloading developer focus. Flux maintainer Kingdon Barrett demonstrates
> Flux's new OCI features and a convenient way to access them.

{{< youtube Hz8IP_eprec>}}

### Upcoming Events 📆

We are happy to announce that we have a number of events coming up in
September - tune in to learn more about Flux and GitOps best practices,
get to know the team and join our community.

- [Sep 15 CNCF on-demand webinar: Flux Increased Security &
  Scalability with
  OCI](https://community.cncf.io/events/details/cncf-cncf-online-programs-presents-cncf-on-demand-webinar-flux-increased-security-scalability-with-oci/)
  > Flux is trusted for its high levels of security, and new OCI support brings even greater GitOps security and scalability. Max will cover the benefits like more streamlined repo structure options and better ways to manage breaking changes in your app.
- [Sep 29 CNCF on-demand webinar: How to GitOps Your
  Terraform](https://community.cncf.io/events/details/cncf-cncf-online-programs-presents-cncf-on-demand-webinar-how-to-gitops-your-terraform/)
  > Pinky will walk you through step-by-step how to manage Terraform resources the GitOps way, from provisioning to enforcement. Bring GitOps to infrastructure and application resources for hybrid automation, state enforcement, drift detection and more.

### Flux Bug Scrub

Our Flux Bug Scrubs still are happening on a weekly basis and remain one
of the best ways to get involved in Flux. They are a friendly and
welcoming way to learn more about contributing and how Flux is organised
as a project.

The next dates are going to be:

- [2022-09-01 17:00 UTC, 19:00
  CEST](https://www.meetup.com/gitops-community/events/qphvvsydcmbcb/)
- [2022-09-07 12:00 UTC, 14:00
  CEST](https://www.meetup.com/gitops-community/events/gxhvvsydcmbkb/)

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
come forward and added themselves to our website: [Embark
Studios](https://embark-studios.com) and
[NexHealth](https://nexhealth.com/).

If you have not already done so, [use the instructions
here](/adopters/) or give us a ping and we
will help to add you. Not only is it great for us to get to know and
welcome you to our community. It also gives the team a big boost in
morale to know where in the world Flux is used everywhere.

#### More docs and website news

We are constantly improving our documentation and website - here are a
couple of small things we landed recently:

- New security docs on [Secrets
  Management](/docs/security/secrets-management/)
  and [Contextual
  Authorization](/docs/security/contextual-authorization/).
- New blog post: [Managing Kyverno Policies as OCI Artifacts with
  OCIRepository
  Sources](/blog/2022/08/manage-kyverno-policies-as-ocirepositories)
- Cheatsheet news
  - [OCI
    Artifacts](/docs/cheatsheets/oci-artifacts/)
  - Bootstrap: [Git repository access via SOCKS5 ssh
    proxy](/docs/cheatsheets/bootstrap/#git-repository-access-via-socks5-ssh-proxy)
  - Bootstrap: [Enable notifications for third party
    controllers](/docs/cheatsheets/bootstrap/#enable-notifications-for-third-party-controllers)
- [Flux's Work Well With section](/docs/#flux-works-well-with): find out
  how to make Flux work with your favourite other OSS software
- Lots of new videos from GitOpsCon / KubeCon on [our resources
  page](/resources/)
- Various updates to the [Flux Roadmap](/roadmap/) to indicate what
  needs to be done for the Flux GA release
- Move to a `fluxcd.io/<project>` kind of structure. Add a project
  picker in the main navbar. Updates of Flux Legacy docs to 1.4.4,
  Flagger docs to 1.22.2.
- Updates of Docsy theme and dependencies. Prevent click-jacking of the
  site.

Thanks a lot to these folks who contributed to docs and website: Stefan
Prodan, Paulo Gomes, Arhell, Kingdon Barrett, Max Jonas Werner, Santosh
Kaluskar, David Harris, Sunny, Aurel Canciu, Benny and annaken.

### New Flux Project Member: Leigh Capili

{{< imgproc leigh-capili Resize 600x >}}
{{< /imgproc >}}

We are proud to announce a new project member in the Flux project. Leigh
Capili, Staff Developer Advocate at VMware, has been contributing to
Flux for a long time already. If you check out [his
application](https://github.com/fluxcd/community/issues/234),
he has left a trail of fixes and improvements across almost all of our
projects.

What we would like to specifically call out as well, is the countless
talks he has done about Flux and GitOps. Take a look at [the Flux
Resources page](/resources/) to learn
more. Three of our current favourites are:

- [Securing GitOps Debug Access with Flux, Pinniped, Dex &
  GitHub](https://youtu.be/OPI-SEOXW34)
- [GitOps with VMware Tanzu Application Platform VMware - Ben Hale &
  Leigh
  Capili](https://www.youtube.com/watch?v=qm1ZKsTcxa4)
- [Building Flux\'s Multi-Tenant API with K8s User
  Impersonation](https://www.youtube.com/watch?v=9_hoXNZKfOk)

Be like Leigh: If you have contributed to Flux and are interested in
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
  2022-09-08 or 2022-09-14.
- Talk to us in the \#flux channel on [CNCF
  Slack](https://slack.cncf.io/)
- Join the [planning
  discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux, take a look at our [Get
  Started guide](/docs/get-started/)
  and give us feedback
- Social media: Follow [Flux on
  Twitter](https://twitter.com/fluxcd), join the
  discussion in the [Flux LinkedIn
  group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.
