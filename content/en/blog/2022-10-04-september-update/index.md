---
author: dholbach
date: 2022-10-04 11:30:00+00:00
title: September 2022 Update
description: "Flux is moving closer to GA, adds tons of new improvements, most notably in the area of OCI. Flux Legacy Retirement plans. Flux at KubeCon and lots of Ecosystem updates!"
url: /blog/2022/10/september-2022-update/
tags: [monthly-update]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

As the Flux family of projects and its communities are growing, we
strive to inform you each month about what has already landed, new
possibilities which are available for integration, and where you can get
involved. Read our [last update here](/blog/2022/09/august-2022-update/).

It's the beginning of October 2022 - let's recap together what happened
in September - it has been a lot!

## News in the Flux family

### Flux v0.34.0 and 0.35.0 bring OCI improvements

{{< imgproc flux Resize 500x >}}
{{< /imgproc >}}

[Flux v0.35](https://github.com/fluxcd/flux2/releases/tag/v0.35.0)
and [Flux v0.34](https://github.com/fluxcd/flux2/releases/tag/v0.34.0)
landed in September. They bring tons of improvements, especially in the
area of OCI. We encourage everyone to upgrade for the best experience.

Please note: there are breaking changes: The Flux controller logs have
been aligned with the Kubernetes structured logging. For more details on
the new logging structure please see:
[fluxcd/flux2\#3051](https://github.com/fluxcd/flux2/issues/3051).

Here is a quick summary of what you can look forward to in terms of
features and improvements:

- Verify OCI artifacts signed by Cosign (including `keyless` - currently
  still experimental and only supporting GCP and GHCR) with
  [OCIRepository.spec.verify](/flux/components/source/ocirepositories/#verification).
  Note this supports contextual login, but not insecure registries.
- Allow pulling Helm charts dependencies from HTTPS repositories with
  mixed self-signed TLS and public CAs.
- Allow pulling Helm charts from OCI artifacts stored at the root of
  AWS ECR.
- Allow running bootstrap for insecure HTTP Git servers with `flux
  bootstrap git --allow-insecure-http --token-auth`.
- Improve health checking for global objects such as `ClusterClass`,
  `GatewayClass`, `StorageClass`, etc.
- The controllers and the Flux CLI are now built with Go 1.19.
- Allow pulling artifacts from an in-cluster Docker Registry over
  plain HTTP with
  [`OCIRepository.spec.insecure`](/flux/components/source/ocirepositories/#insecure).
- Allow defining OCI sources for non-TLS container registries with
  `flux create source oci --insecure`.
- Enable contextual login when publishing OCI artifacts from a Cloud
  VM using `flux push artifact --provider=aws|azure|gcp`.
- Prioritise static credentials over OIDC providers when pulling OCI
  artifacts from container registries on multi-tenant cluster.
- Reconcile Kubernetes Class types (`ClusterClass`, `GatewayClass`,
  `StorageClass`, etc) in a dedicated stage before any other custom
  resources like `Clusters`, `Gateways`, `Volumes`, etc.
- When multiple SOPS providers are available, run the offline
  decryption methods first to avoid failures due to KMS
  unavailability.
- Add finalizers to the notification API to properly record the
  reconciliation metrics for deleted resources.
- Publish the Flux install manifests as OCI artifacts on GitHub and
  DockerHub container registries under `fluxcd/flux-manifests`.

For more information on OCI and Cosign support please see the [Flux
documentation](/flux/cheatsheets/oci-artifacts/#signing-and-verification).

It took us six months to debate, design and implement OCI support in
Flux. Big thanks to all the Flux contributors that helped us reach this
milestone!

### Flux Legacy (v1) Retirement Plan

Thanks to so many of you who have been migrating to the latest Flux
version, often in conversation with us. We appreciate your enthusiasm
for the increased capabilities of Flux. In October 2020 we put Flux
Legacy and Helm operator into maintenance mode (cf
[flux\#3320](https://github.com/fluxcd/flux/issues/3320)
and
[helm-operator\#546](https://github.com/fluxcd/helm-operator/issues/546)).
Back then we promised to continue to support them for 6 months once we
reached feature-parity across all former feature sets, and instead we
have offered extended support for over a year.

We [reached parity in March
2021](/blog/2021/03/march-2021-update/#feature-parity---what-is-this)
and announced [stable APIs in July
2021](/blog/2021/07/july-2021-update/#from-now-on-flux-apis-will-be-stable).
Since then we added OCI support and many other modern features to Flux
v2. Thanks to you not only for migrating, but also for adding yourselves
to the latest Flux [adopters page](/adopters/)! We really appreciate
it. Your work has brought down the number of support requests for legacy
Flux to 5% of all volume in the past year.

We will archive Flux Legacy in November this year. If you still need
migration help, there are still [free migration
workshops](https://bit.ly/FluxMigrationSurvey), or reach out for paid
support to one of the companies [listed
here](/support/#commercial-support).

Some recent prompts for this include:

- Some of the Flux v1 dependencies are pinned to EOL versions, which
  cannot be upgraded without causing regressions or a cascading
  amount of changes to the codebase.
- All Kubernetes dependencies are pinned within version v1.21. That
  version already reached end-of-life support upstream.

Thanks for joining us on this journey of building Flux. [Please give
Flux a star](https://github.com/fluxcd/flux2)!

### Flux Ecosystem

#### Flux Subsystem for Argo

The team is happy to announce that [Flux Subsystem for Argo
(FSA)](https://github.com/flux-subsystem-argo/flamingo) is
now on-par with ArgoCD regarding supported versions. FSA now provides
all versions supported by ArgoCD. The project will provide security
updates based on ArgoCD v2.2 and v2.3, and for the active ArgoCD version
(currently v2.4), FSA will support them, starting from v2.4.12.

For Flux compatibility, FSA will be tested against every release of
future Flux versions.

{{< imgproc fsa Resize 900x >}}
{{< /imgproc >}}

#### Weave GitOps

Weaveworks just released version
[v0.9.6](https://github.com/weaveworks/weave-gitops/releases/tag/v0.9.6)
for Weave GitOps. There are a lot of great new features that have been
released in the last month. First, it is continuing the trend of being a
feature rich Flux UI by adding support for Flux Providers and Alerts.
When you click on the user icon you are then taken to a screen that
contains those objects. As a platform operator, you can easily
understand where events are being sent.

On the kustomization and helm release detail pages there is now a tab to
check your dependencies for those objects. The `dependsOn` is a
powerful feature in Flux and now you can easily see these visualised
within the application. We're also making it easy to navigate from these
graphs to relevant objects in a near future release.

{{< imgproc wg-dependson Resize 900x >}}
{{< /imgproc >}}

In addition, the team added numerous improvements to `gitops run` our live
coding environment. Now you can run the command against an empty folder
and it will generate a `kustomization.yaml` file and give you a live
connection between that working directory and the cluster you are
connected to. The team is full steam ahead on the next set of features
for the run experience.

##### Terraform Controller

The Weave GitOps team is continuing to improve our ecosystem of
controllers with the latest release of the tf-controller
[v0.12.0](https://github.com/weaveworks/tf-controller/releases/tag/v0.12.0).

The notable features in this release are: custom backend support,
interop with Notification controller, and support human readable plan
output in `ConfigMap`. This is all new:

- Enable custom backends for Terraform
- Support `backendConfigsFrom` for specifying backend configuration
  from Secrets
- Add a parameter for specifying max gRPC message size, default to 4MB
- Implement `force-unlock` for `tfstate` management
- Fix the initialization status
- Recording events to support Flux notification controller
- Support specifying targets for plan and apply
- Add node selector, affinity and tolerations for the runner pod
- Add volume and volumeMounts for the runner pod
- Add file mapping to map files from Secrets to home or workspace
  directory
- Fix Plan prompt being overridden by the progressing message
- Support storing human-readable plan output in a ConfigMap

Learn more at the [following blog post "How to GitOps Your
Terraform"](/blog/2022/09/how-to-gitops-your-terraform/),
by Priyanka Ravi & Daniel Holbach.

##### Weave GitOps Enterprise

The Weave GitOps Enterprise continues to build on top of the OSS feature
set with its latest [v0.9.5
release](https://docs.gitops.weave.works/docs/releases/).
First, the team has added a new add application button with support for
both Kustomizations and Helm Releases. This makes it super easy to add
the relevant Flux primitives to get your applications loaded onto the
cluster(s) of your choice.

Workspaces were added as well. This makes it super easy to manage
multi-tenancy on Weave GitOps Enterprise. It is built on top of Flux's
tenancy model with a lot of extra flexibility and power. For example,
all of your workspaces can be defined in one or more files. We then have
a simple CLI command that will generate all of the necessary YAML for
you. This includes advanced features such as policies to ensure full
compliance within the tenant. You can define which repositories your
users can use as well as which clusters applications can be deployed to.
To learn more about this feature check out the
[documentation](https://docs.gitops.weave.works/docs/workspaces/multi-tenancy/).

You can also now define pipelines and environments for Helm Charts. This
will allow your application teams to see how things are rolled out
across dev, staging, and production environments; or however you choose
to define your environments. There will be a lot of continued efforts in
this area so stay tuned.

Your engineering teams are able to see policy violations for
applications across clusters. Policy sets can be used by platform
operators to define in one place whether policies are for auditing
purposes or should be blocked by the admission controller. The team
built out a profile for making it easy to set up policy dashboards using
the ELK stack. Platform operators now have greater flexibility when
configuring the same policy with different values for different
clusters.

#### VS Code GitOps Extension

A lot of great features have been added to the extension, most notably
support for OCI and Azure. Please see the recent [blog post in our
ecosystem category](/blog/2022/09/gitops-without-leaving-your-ide/) for
more details.

## Recent & Upcoming Events

It's important to keep you up to date with new features and developments
in Flux and provide simple ways to see our work in action and chat with
our engineers.

### Recent Events (ICYMI) 📺

We feel blessed to have such a big community of users, contributors and
integrators and so many are happy to talk about their experiences. In
September here are a couple of talks we would like to highlight.

- [CNCF On-Demand Webinar (Sep 15): Flux increased security &
  scalability with OCI\
  ](https://www.cncf.io/online-programs/cncf-on-demand-webinar-flux-increased-security-scalability-with-oci/)*Flux
  is trusted for its high levels of security, and new OCI support
  brings even greater GitOps security and scalability. Max Jonas
  Werner covers the benefits like more streamlined repo structure
  options and better ways to manage breaking changes in your app.*
- [CNCF On-Demand Webinar (Sep 29) How to GitOps Your
  Terraform](https://community.cncf.io/events/details/cncf-cncf-online-programs-presents-cncf-on-demand-webinar-how-to-gitops-your-terraform/)*\
  Priyanka "Pinky" Ravi walks you through step-by-step how to manage
  Terraform resources the GitOps way, from provisioning to
  enforcement. Bring GitOps to infrastructure and application
  resources for hybrid automation, state enforcement, drift
  detection and more.*

Here is a list of additional videos and topics we really enjoyed -
please let us know if we missed anything of interest and we will make
sure to mention it in the next post!

### Upcoming Events 📆

#### KubeCon

We are happy to announce that we will be at GitOpsCon and KubeCon in
October! Visit our booth in-person at the Project Pavilion during
KubeCon and the full schedule is below (and on our [Flux @ KubeCon mini
site](https://bit.ly/flux-kubecon-2022). See you soon!

##### Monday, October 24 (Flux Project Meeting at KubeCon)

13:00 - 17:00 [Flux Project Meeting](https://sched.co/1BaSl) Room 335, Level 300

> We'll have talks/demos from beginner to advanced, including but not limited to:
> Flux basics, what's new with Flux including OCI support, VS Code, Terraform Controller,
> Cosign, Helm, & Flagger, and of course you can ask Maintainers all your
> questions.

##### Tuesday, October 25 (GitOpsCon)

9:45 - 10:15 GitOpsCon: [How to Achieve (Actual) GitOps with Terraform
and Flux](https://sched.co/1AR8M)

> Priyanka \"Pinky\" Ravi (Weaveworks) and Roberth Stand (Crayon Group)

9:45 - 10:15 GitOpsCon: [Toward Full Adoption of GitOps and Best
Practices at RingCentral](https://sched.co/1AR8J)

> Tamao Nakahara (Weaveworks) and Ivan Anisimov (RingCentral)

11:10 - 11:40 GitOpsCon: [Simplifying Edge Deployments Using EMCO and
GitOps](https://sched.co/1AR8V)

> Igor DC & Adarsh Vincent Chittilappilly (Intel)

11:40 - 12:10 Prometheus Days: [Automate your SLO validation with Prometheus & Flagger](https://sched.co/1AsMU)

> Sanskar Jaiswal & Kingdon Barrett (Weaveworks)

12:00 - 12:10 GitOpsCon: [Why Do We Do This? The Heart of
GitOps](https://sched.co/1AR8b)

> Leigh Capili (VMware)

13:10 - 13:20 GitOpsCon: [Green(ing) CI/CD: A Sustainability Journey
with GitOps](https://sched.co/1AR8Y)

> Niki Manoledaki (Weaveworks)

13:40 - 14:10 GitOpsCon: [Complete DR of Workloads, PVs and CSI
Snapshots via Flux and Vault OSS](https://sched.co/1AR9B)

> Kingdon Barrett (Weaveworks)

14:15 - 14:45 GitOpsCon: [GitOps with Flux and OCI
Registries](https://sched.co/1AR8z)

> Soulé Ba & Scott Rigby (Weaveworks)

14:15 - 14:45 GitOpsCon: [Pixie + Flux, VSCode, GitOps Observability
from Top to Bottom](https://sched.co/1AR8z)

> Somtochi Onyekwere (Weaveworks)

##### Wednesday, October 26 (KubeCon)

14:30 - 16:00 KubeCon: [Tutorial: So You Want To Develop a Cluster API
Provider](https://sched.co/182Ha)

> Anusha Hegde & Winnie Kwon & Sedef Savas (VMware), Richard Case
> (Weaveworks),
>
> Avishay Traeger (Red Hat)

15:25 - 16:00 KubeCon: [Flagger, Linkerd, And Gateway API: Oh
My!](https://sched.co/182Go)

> Jason Morgan (Linkerd) & Sanskar Jaiswal (Weaveworks)

15:25 - 16:00 KubeCon: [Tutorial: How To Write a Reconciler Using K8s
Controller-Runtime!](https://sched.co/182Hg)

> Scott Rigby, Somtochi Onyekwere, Niki Manoledaki & Soulé Ba
> (Weaveworks),
>
> Amine Hilaly (Amazon Web Services)

##### Thursday, October 27 (KubeCon)

11:00 - 11:35 KubeCon: [Learn About Helm And Its
Ecosystem](https://sched.co/182Ns)

> Andrew Block & Karena Angell (Red Hat), Matt Farina (SUSE) Scott Rigby
> (Weaveworks)

##### Friday, October 28 (KubeCon)

11:00 - 12:30 KubeCon: [Flux
ContribFest](https://sched.co/182QL)

> Room 410 B

16:55 - 17:30 KubeCon: [Flux Maturity, Feature, and Contrib
Update](https://sched.co/182QX)

> Somtochi Onyekwere & Kingdon Barrett (Weaveworks)

#### Flux Bug Scrub

Our Flux Bug Scrubs still are happening on a weekly basis and remain one
of the best ways to get involved in Flux. They are a friendly and
welcoming way to learn more about contributing and how Flux is organised
as a project.

The next dates are going to be:

- [2022-10-05 12:00 UTC, 14:00
  CEST](https://www.meetup.com/weave-user-group/events/wvhvvsydcnbhb/)
- [2022-10-19 12:00 UTC, 14:00
  CEST](https://www.meetup.com/weave-user-group/events/wvhvvsydcnbzb/)
- [2022-10-28 20:55 UTC, 16:55 EDT (The Flux Bug Scrub, Live at
  ContribFest)](https://sched.co/182QL)

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

### New Flux Project Members: Batuhan Apaydın and Rashed Kamal

We are very excited to be able to announce two new Flux project members
this month.

Batuhan Apaydın, Senior Software Engineer at Trendyol, has been
[helping out quite a bit](https://github.com/fluxcd/community/issues/242)
in the OCI discussions and wrote a blog post explaining [how to manage
Kyverno policies as OCI artifacts](/blog/2022/08/manage-kyverno-policies-as-ocirepositories/)
recently. We are very glad to have him in our community and there's more
OCI awesomeness and blog posts planned.

Rashed Kamal, Staff Engineer at VMware, [joined us in September as
well](https://github.com/fluxcd/community/issues/239). His
interests include OCI, where he contributed to the RFC too. On top of
that he fixed a number of issues in Flux. Thanks for all of that and for
being part of the team!

{{< imgproc rashedkvm Resize 400x >}}
{{< /imgproc >}}

### News from the Website and our Docs

#### Flux Adopters shout-out

We are very pleased to announce that the following adopters of Flux have
come forward and added themselves to our website:
[NovaID](https://novaid.vn/).

If you have not already done so, [use the instructions here](/adopters/)
or give us a ping and we will help to add you. Not only is it great for
us to get to know and welcome you to our community. It also gives the
team a big boost in morale to know where in the world Flux is used
everywhere.

#### More docs and website news

We are constantly improving our documentation and website - here are a
couple of small things we landed recently:

- We simplified the build process of the website. We are on a very
  recent version of the Docsy theme again!
- Our [Bootstrap Cheatsheet](/flux/cheatsheets/bootstrap/)
  now contains instructions on how to enable notifications for third
  party controllers.
- [Flux End-To-End documentation](/flux/flux-e2e/) was
  updated to reflect recent changes.
- We added a lot of new videos to [the Flux Resources page](/resources/).
- Many small improvements and fixes across the entire site and docs.

Thanks a lot to these folks who contributed to docs and website: Stefan
Prodan, Kingdon Barrett, Arhell, Paulo Gomes, Max Jonas Werner, Vanessa
Abankwah, Santosh Kaluskar, Batuhan Apaydın, Stacey Potter, Bang Nguyen,
Sven Nebel, Aurel Canciu, David Harris, Gustaf Lindstedt, Simo
Aleksandrov and annaken.

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
  2022-10-06 or 2022-10-12.
- Talk to us in the \#flux channel on [CNCF Slack](https://slack.cncf.io/)
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux, take a look at our [Get
  Started guide](/flux/get-started/) and give us feedback
- Social media: Follow [Flux on Twitter](https://twitter.com/fluxcd), join the
  discussion in the [Flux LinkedIn group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.
