---
author: dholbach
date: 2022-05-03 8:30:00+00:00
title: April 2022 update
description: New Flux and Flagger releases bring you the latest and greatest just yet! KubeCon news, GitOps Days coming up and lots of new resources - potentially the most newly added videos in particular! Lots of great contributions from our community. 💖
url: /blog/2022/05/april-2022-update/
tags: [monthly-update]
---

As the Flux family of projects and its communities are growing, we
strive to inform you each month about what has already landed, new
possibilities which are available for integration, and where you can get
involved. Read our [last update here](/blog/2022/03/february-update/).

It's the beginning of May 2022 - let's recap together what happened in
April - it has been a lot!

**Update:** Earlier versions of this post referred to the pre-KubeCon
Bug Bash. Unfortunately we had to cancel our participation.

## News in the Flux family

### Latest Flux release series is 0.29

This is the latest and greatest, but before we get into the list of
great features and improvements, let's take a look at the breaking
changes beforehand:

- From this release on, the `RUNTIME_NAMESPACE` environment variable is
  no longer taken into account to configure the advertised HTTP/S
  address of the storage. Instead, [variable
  substitution](https://kubernetes.io/docs/tasks/inject-data-application/define-interdependent-environment-variables/#define-an-environment-dependent-variable-for-a-container)
  must be used, as described in [the changelog entry
  for](https://github.com/fluxcd/flux2/releases#052)
  v0.5.2.
- Use of file-based `KubeConfig` options are now permanently disabled
  (e.g. `TLSClientConfig.CAFile`, `TLSClientConfig.KeyFile`,
  `TLSClientConfig.CertFile` and `BearerTokenFile`). The drive behind
  the change was to discourage insecure practices of mounting
  Kubernetes tokens inside the controller's container file system.
- Use of `TLSClientConfig.Insecure` in `KubeConfig` file is disabled by
  default, but can be enabled at controller level with the flag
  `--insecure-kubeconfig-tls`.
- Use of `ExecProvider` in `KubeConfig` file is now disabled by default,
  but can be enabled at controller level with the flag
  `--insecure-kubeconfig-exec`.

With that out of the way, here are the highlights of the release:

#### Notification Improvements

A new notification is now emitted to identify recovery from failures. It
is triggered when a failed reconciliation is followed by a successful
one.

#### In-memory cache for HelmRepository

An opt-in in-memory cache for HelmRepository that addresses issues where
the index file is loaded and unmarshalled in concurrent reconciliation
resulting in a heavy memory footprint. It can be configured using the
flags: `--helm-cache-max-size`, `--helm-cache-ttl`,
`--helm-cache-purge-interval`.

#### Configurable retention of Source Artifacts

Garbage Collection is enabled by default, and now its retention options
are configurable with the flags: `--artifact-retention-ttl` (default:
60s) and `--artifact-retention-records` (default: 2). They define the
minimum time to live and the maximum amount of artifacts to survive a
collection.

#### Configurable Key Exchange Algorithms for SSH connections

Using the flag `--ssh-kex-algos`. Note this applies to the `go-git`
`gitImplementation` or the `libgit2` `gitImplementation` but only when Managed
Transport is being used.

#### Configurable Exponential Back-off retry settings

With the new flags: `--min-retry-delay` (default: 750ms) and
`--max-retry-delay` (default: 15min). Previously the defaults were set to
5ms and 1000s, which in some cases impaired the controller's ability to
self-heal (e.g. retrying failing SSH connections).

#### Experimental managed transport for libgit2 Git implementation

Now has self-healing capabilities, to recover from failure when
long-running connections become stale.

#### SOPS refactored and optimized

Including various improvements and extended code coverage. Age
identities are now imported once and reused multiple times, optimizing
CPU and memory usage between decryption operations.

#### Helm chart directory loader improvements

Introduction of a secure directory loader which improves the handling of
Helm charts paths.

For a more detailed list of changes in the series, please refer to the
change logs of
[0.29.0](https://github.com/fluxcd/flux2/releases/tag/v0.29.0),
[0.29.1](https://github.com/fluxcd/flux2/releases/tag/v0.29.1),
[0.29.2](https://github.com/fluxcd/flux2/releases/tag/v0.29.2),
[0.29.3](https://github.com/fluxcd/flux2/releases/tag/v0.29.3),
[0.29.4](https://github.com/fluxcd/flux2/releases/tag/v0.29.4),
and
[0.29.5](https://github.com/fluxcd/flux2/releases/tag/v0.29.5).

### Flagger 1.20.0

This release comes with improvements to the AppMesh, Contour and Istio
integrations.

#### Improvements

- AppMesh: Add annotation to enable Envoy access logs
  [\#1156](https://github.com/fluxcd/flagger/pull/1156)
- Contour: Update the httproxy API and enable `RetryOn`
  [\#1164](https://github.com/fluxcd/flagger/pull/1164)
- Istio: Add destination port when port discovery and delegation are
  true
  [\#1145](https://github.com/fluxcd/flagger/pull/1145)
- Metrics: Add canary analysis result as Prometheus metrics
  [\#1148](https://github.com/fluxcd/flagger/pull/1148)

#### Fixes

- Fix canary rollback behaviour
  [\#1171](https://github.com/fluxcd/flagger/pull/1171)
- Shorten the metric analysis cycle after confirm promotion gate is
  open
  [\#1139](https://github.com/fluxcd/flagger/pull/1139)
- Fix unit of time in the Istio Grafana dashboard
  [\#1162](https://github.com/fluxcd/flagger/pull/1162)
- Fix the service toggle condition in the podinfo helm chart
  [\#1146](https://github.com/fluxcd/flagger/pull/1146)

### Flux Ecosystem

#### Flux Subsystem for Argo

In the latest release, we have added checkboxes to enable Flux Subsystem
in the Argo CD UI. We also have a [tutorial to use TF-controller with
Flux Subsystem for
Argo](https://flux-subsystem-argo.github.io/website/tutorials/terraform/).
With this you have an alternative option to Crossplane to manage
infrastructure.

#### Terraform-controller

We have released TF-controller v0.9.4 which is a bug-fix release. We
also added **cloud cost estimation** to our road map. Please feel free
to give us feedback on how you would like this feature to be:

- Issues here: <https://github.com/weaveworks/tf-controller/issues>, and
- Discussions here: <https://github.com/weaveworks/tf-controller/discussions>

#### Weave GitOps

Weave GitOps is a powerful, open source extension to Flux, which
provides insights into your deployments, and makes continuous delivery
with GitOps easier to adopt and scale across your teams. You can easily
install alongside an existing Flux setup, adding (or removing) Weave
GitOps as a standard Helm resource.

[The v0.8.0 release](https://github.com/weaveworks/weave-gitops/releases/tag/v0.8.0)
brings multi-namespace querying so you can see objects from across your
cluster in the Web UI, several UI enhancements and bug fixes, as well as
supporting the Source `v1beta2` API - this breaking change means we now
require Flux v0.29.0 or later.

## Recent & Upcoming Events

It's important to keep you up to date with new features and developments
in Flux and provide simple ways to see our work in action and chat with
our engineers.

### Recent Events (ICYMI) 📺

We feel blessed to have such a big community of users, contributors and
integrators and so many are happy to talk about their experiences. In
April here are a couple of talks we would like to highlight:

[Managing Thousands of Clusters and Their Workloads with Max Jonas Werner](https://youtu.be/V1AOVwzmIKE?t=272)
D2iQ uses Flux to automatically enable this experience in its products. Join Max for this hands-on session on multi-cluster management using GitOps.

[CNCF on-demand webinar: Flux for Helm Users with Scott Rigby](https://youtu.be/r_vKf5l1D1M)
Scott Rigby, Flux & Helm Maintainer, takes you on a tour of Flux’s Helm Controller, shares the additional benefits Flux adds to Helm and then walks through a live demo of how to manage helm releases using Flux.

[Women In GitOps Panel](https://youtu.be/0bwM40Ye5bQ?t=2)
We celebrated international women’s day, GitOps Style. This event gathered female role models who innovate, challenge and embrace the world of GitOps. Inspirational women who have achieved great success within the sector and will share stories of their journey and explore the question why is it important to “Get on GitOps.”

[Securing GitOps Debug Access with Flux, Pinniped, Dex, & GitHub with Leigh Capili](https://youtu.be/etbvuV9EjLc?t=284)
In this live demo, Leigh will show how the incredibly flexible, open-source combo of Flux, Pinniped, and Dex can empower a team to leave a traceable solution during a production incident. He explores effective team debugging habits with Kubernetes and git.

[Security: The Value of SBOMs with Dan Luhring (Anchore)](https://youtu.be/-3K74I7t7CQ?t=447)
During this session, Dan Luhring, OSS Engineering Manager at Anchore, dives into SBOMs - what they are, why you need them, some common use cases and how to get your pipeline ready for SBOM generation and verification using the Flux SBOM as an example.

[OpenSource 101: WTF is GitOps & Why Should You Care? with Priyanka Ravi](https://youtu.be/arZVt-3HHP0)
Pinky shares from personal experience why GitOps has been an essential part of achieving a best-in-class delivery and platform team, gives a brief overview of definitions, CNCF-based principles, and Flux’s capabilities: multi-tenancy, multi-cluster, (multi-everything!), for apps and infra, and more.

[From Zero to GitOps Heroes with Mae Large, Russ Parmer, & Priyanka Ravi](https://youtu.be/73kOXNTrNVU?t=431)
During this session Mae, Pinky, & Riss share key learnings from their early days of assessing GitOps as an idea and methodology to how it evolved into the de facto automated software change process in less than 1 year.

### Upcoming Events 📆

We are happy to announce that we have a number of events coming up in
May - tune in to learn more about Flux and GitOps best practices, get
to know the team and join our community.

#### Flux Bug Scrub

Our Flux Bug Scrubs still are happening on a weekly basis and remain one
of the best ways to get involved in Flux. They are a friendly and
welcoming way to learn more about contributing and how Flux is organised
as a project.

The next dates are going to be:

- [May 04 at 12:00 UTC, 14:00
  CEST](https://www.meetup.com/GitOps-Community/events/fbhnssydchbgb/)
- [May 12 at 10am PT / 1pm
  ET](https://www.meetup.com/GitOps-Community/events/ndjjssydchbqb/)
- [May 18 at 12:00 UTC/ 14:00
  CEST](https://www.meetup.com/GitOps-Community/events/fbhnssydchbxb/)
- [May 26 at 10am PT / 1pm
  ET](https://www.meetup.com/GitOps-Community/events/ndjjssydchbjc/)

We are flexible with subjects and often go with the interests of the
group or of the presenter. If you want to come and join us in either
capacity, just show up or if you have questions, reach out to Kingdon on
Slack.

We really enjoyed this [demo of the k3d git
server](https://www.youtube.com/watch?v=hNt3v0kk6ec)
recently. It's a local Git server that runs outside of Kubernetes, to
support offline dev in a realistic but also simple way that does not
depend on GitHub or other hosted services.

#### KubeCon / CloudNativeCon Europe 2022 coming up

As every other project in the Cloud Natice space, we are very busy
preparing everything for [KubeCon / CloudNativeCon Europe
2022](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/),
which is going to be 16-20 May 2022 in Valencia, Spain (and virtual of
course!).

We will post a separate announcement as soon as everything is confirmed,
but we already want to inform you about what's likely to happen, so you
can plan accordingly or collaborate with us!

#### The Bug Bash

Unfortunately we will not be participating in the Bug Bash this KubeCon!

Despite earlier announcements claiming we would do this, we felt we
could not do this well enough. If you were looking forward to this,
we are sorry - but you know what: we still have the weekly Bug Scrub! Your
weekly one-on-one mentoring to learn the ropes of working on Flux!

#### Monday, 16 May

13:00 - 17:00 (Room 2H - Event Center): Flux Project Meeting: We will
kick off the Flux get-togethers and festivities with an in-person
meeting for all Flux users, contributors, maintainers and generally
interested folks. This will be an opportunity to get to know each other,
have a chat, see what people's interests are and to potentially start
contributing. ([Sign up
here](https://linuxfoundation.surveymonkey.com/r/WYGBGPZ).)
Contact people on the ground are: Scott Rigby, Somtochi Onyekwere and
Stefan Prodan.

> Join Flux Maintainers Stefan Prodan, Somtochi Onyekwere & Scott Rigby
> for this Flux Project Meeting in-person at KubeCon EU on Monday, May
> 16 from 1pm - 5pm CEST
>
> Click here to register
> ([here](https://linuxfoundation.surveymonkey.com/r/WYGBGPZ))
> for the Flux Project Meeting. Please note that you must be a KubeCon +
> CloudNativeCon Europe
> ([here](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/))
> registrant in order to attend this meeting.
>
> Details Flux Project Meeting Monday, May 16, 13:00 - 17:00 CEST Room
> 2H | Event Center
>
> Space is limited *Please note: we will not have any live streaming,
> recordings, or any virtual component available for this meeting.*

#### Tuesday 17 May - [GitOpsCon](https://events.linuxfoundation.org/gitopscon-europe/program/schedule/)

Lots and lots of talks about GitOps in general and Flux in particular,
here's a short selection of what to look forward to:

- [What is GitOps and How to Get It Right - Dan Garfield (Codefresh);
  Chris Short (AWS) & Scott Rigby
  (Weaveworks)](https://sched.co/zrpk) (9:00 - 9:35)
- [Hiding in Plain Sight - How Flux Decrypts Secrets -
  Somtochi Onyekwere (Weaveworks)](https://sched.co/zrq5)
  (11:05 - 11:15)
- [Taming the Thundering Gitops Herd with Update Policies - Joaquim
  Rocha & Iago López Galeiras (Microsoft)](https://sched.co/zrqK)
  (11:35 - 11:45)
- [GitOps and Progressive Delivery with Flagger, Istio and Flux -
  Marco Amador (Anova)](https://sched.co/zrqW) (13:20-13:30)
- [Creating A Landlord for Multi-tenant K8s Using Flux, Gatekeeper,
  Helm, and Friends - Michael Irwin (Docker)](https://sched.co/zrqf)
  (13:35-14:05)
- [GitOps, A Slightly Realistic Situation on Kubernetes with Flux -
  Laurent Grangeau (Google) & Ludovic Piot
  (theGarageBandOfIT)](https://sched.co/zrqi) (14:10 - 14:40)
- [Solving Environment Promotion with Flux - Sam Tavakoli & Adelina
  Simion (Form3)](https://sched.co/zrql) (14:10 - 14:40)
- [Managing Thousands of Clusters and Their Workloads with Flux - Max
  Jonas Werner (D2iQ)](https://sched.co/zrqu) (14:55 - 15:25)
- [Crossing the Divide: How GitOps Brought AppDev & Platform Teams
  Together! - Russ Palmer (State Farm) & Priyanka 'Pinky' Ravi
  (Weaveworks)](https://sched.co/zrqx) (15.30 - 16:00)
- [GitOps Everything!? We Sure Can!, AppsFlyer](https://sched.co/zrr0)
  (15:30 - 16:00)
- [Lightning Talk: Addressing Log4Shell with Software Supply Chains -
  Duane DeCapite (VMware)](https://sched.co/ytwg)
  (18:04 - 18:09)

#### Wednesday 18 May - Friday May 20 - [KubeCon](https://kccnceu2022.sched.com/?iframe=no)

Over these three days we are going to be at the Flux booth (both
virtually and on the ground), so come over for a chat. We are planning
loads of talks, demos and ample time to have a chat, get to know
everyone, ask questions and have great new ideas together!

On top of that, here is a list of talks, workshops and sessions during
those days:

- Wed 18: [Flux Security Deep Dive - Stefan Prodan
  (Weaveworks)](https://sched.co/ytlV) (11:55 - 12:30)
- Wed 18: [Intro to Kubernetes, GitOps, and Observability Hands-On
  Tutorial - Johee Chung (Microsoft) & Tiffany Wang
  (Weaveworks)](https://sched.co/ytkj) (11:00 - 12:30)
- Wed 18: [Flux Bug Scrub - Kingdon
  Barrett](https://weaveworks.zoom.us/j/85821738864?pwd=cjk4QjRabEpUVlRlcFBqMm9UZ2xNZz09)
  (13:00 - 14:00)
- Wed 18: [A New Generation of Trusted GitOps for Mixed K8s and
  Non-K8s End Users - Alexis & Vasu Chandrasekhara
  (SAP)](https://sched.co/ytmW) (15:25 - 16:00)
- Thu 19: [GitOps to Automate the Setup, Management and Extension a
  K8s Cluster - Kim Schlesinger (DigitalOcean)](https://sched.co/yto4)
  (11:00 - 12:30)
- Thu 19: Flux Project Office Hour - Paulo Gomes (Weaveworks)
  (13:30 - 14:15)
- Fri 20: [Observing Fastly's Network at Scale Thanks to K8s and the
  Strimzi Operator - Fernando Crespo & Daniel Caballero,
  (Fastly)](https://sched.co/ytrM) (11:00 - 11:35)
- Fri 20: [Simplifying Service Mesh Operations with Flux and
  Flagger - Mitch Connors (Google) &
  Stefan Prodan (Weaveworks)](https://kccnceu2022.sched.com/#)
  (14:55 - 15:30)

Please note: all of the above might be subject to change. Please
double-check the schedule beforehand. Please reach out to Vanessa
Abankwah or Daniel Holbach on Slack if you have questions or would like
to participate in any of the above.

We very much look forward to seeing you there!

### GitOps Days 2022

GitOps Days 2022 is a free 2-day online event on June 8-9, 2022.

This is **THE** event for your GitOps journey! Getting started? Taking
GitOps to the next level? We'll cover all of the steps for your success!

The event will run from **9:00 am PT to ~3:00 pm PT** each day as a free
online event.

✨✨ [Register
now](https://youtube.com/playlist?list=PL9lTuCFNLaD0NVkR17tno4X6BkxsbZZfr) to
reserve your spot to receive updates to the schedule and speakers. ✨✨

*Join the conversation!* Chat with the speakers and other attendees!
Invite yourself at
[https://slack.weave.works](https://weave-community.slack.com/join/shared_invite/zt-yqwtav03-QPo7W4Qoi1pL6W8UQYk2yQ)
and hang out with us at
[\#gitopsdays](https://bit.ly/GitOpsDays_Slack)

What to expect?

- Talks and tutorials on how to get started with Kubernetes and GitOps
- Talks from Flux users about their use cases
- How to do GitOps securely
- Platforms that offer GitOps: Microsoft Arc Kubernetes, AWS Anywhere,
  Weave GitOps, D2iQ Kubernetes Platform, and more! all using Flux!
- Flux in the CNCF and the GitOps Ecosystem
- Flux support and Integrations: Flux + Helm, Terraform, HashiCorp Vault,
  Jenkins, OpenShift, Visual Studio Code, and much much more!
- Technical deep dives with Flux maintainers
- Music from DJ Desired State 🎶

## In other news

### People writing/talking about Flux

We love it when you all write about Flux and share your experience,
write how-tos on integrating Flux with other pieces of software or other
things. Give us a shout-out and we will link it from this section! ✍

#### Manage Kubernetes Secrets for Flux with HashiCorp Vault

Rosemary Wang from HashiCorp wrote a great blog post about how to
[manage Kubernetes Secrets for Flux with HashiCorp Vault](https://www.hashicorp.com/blog/manage-kubernetes-secrets-for-flux-with-hashicorp-vault). The how-to
is nicely written with a lot of detail and will take you through the steps
to configure the Secrets Store CSI driver with HashiCorp Vault to securely
inject secrets into Flux or other GitOps tools on Kubernetes.

We are looking forward to more collaboration together!

#### Full GitOps Tutorial: Getting started with Flux

{{< youtube 5u45lXmhgxA >}}

This video is great for everyone who gets started, but also everyone who enjoys a story well-told.

In this video, Anais Urlichs covers

- What is GitOps and how does Flux work
- Flux installation
- Managing Helm Charts with Flux
- Managing Kubernetes Manifests with Flux
- Setting up alerts with Flux

Anais also sat down wrote this all up in [blog-post from](https://anaisurl.com/full-tutorial-getting-started-with-flux-cd/).

#### How To Apply GitOps To Everything Using Crossplane And Flux

{{< youtube dunU2ABitMA >}}

Viktor Farcic has done it again - check out this great video where he
shows how to leverage the extensibility of Crossplane and Flux features
to apply GitOps not only to applications running in Kubernetes but to
everything (infrastructure, services, applications running anywhere, etc.)

#### Encrypted gitops secrets with flux and age

Major Hayden wrote a nice article about how to get [encrypted gitops secrets
with flux and age](https://major.io/2022/04/19/encrypted-gitops-secrets-with-flux-and-age)
right.

Here you will learn how to store encrypted kubernetes secrets safely in
your GitOps repository with easy-to-use `age` encryption. 🔐

#### Basic authentication with Traefik on kubernetes

Another post from Major Hayden! This time about [Basic authentication
with Traefik on kubernetes](https://major.io/2022/04/20/basic-auth-with-traefik-on-kubernetes/).

It's nicely detailed and will take you through all the steps to
keep prying eyes away from your sites behind Traefik with basic authentication. 🛃

#### Automated Canary Deployments with Rancher Fleet and Flagger

{{< youtube 2x5q89YLdc0 >}}

In this video, Lukonde Mwila will demonstrate how to execute automated
canary deployments with Rancher Fleet and Flagger.

### News from the Website and our Docs

#### Flux Adopters shout-out

We are very pleased to announce that the following adopters of Flux have
come forward and added themselves to our website:
[Stackspin](https://www.stackspin.net/),
[Maersk](https://www.maersk.com/) and
[Rungway](https://www.rungway.com/).

If you have not already done so, [use the instructions
here](/adopters/) or give us a ping and we
will help to add you. Not only is it great for us to get to know and
welcome you to our community. It also gives the team a big boost in
morale to know where in the world Flux is used everywhere.

#### More docs and website news

We are constantly improving our documentation and website - here are a
couple of small things we landed recently.

- If you always wanted to join Team Flux and weren't quite sure how,
  please read our blog post [Contributing to
  Flux](/blog/2022/04/contributing-to-flux/)
  and say Hi on Slack!
- Many mobile UI fixes!
- Add [flux-subsystem-argo/flamingo](https://github.com/flux-subsystem-argo/flamingo)
  and [weaveworks/vscode-gitops-tools](https://github.com/weaveworks/vscode-gitops-tools)
  to the Flux Ecosystem page.
- New videos under [Flux Resources](/resources/)! 😍
- Various docs fixes.
- And here is a big one: we moved all docs from <https://flagger.app> into
  <https://fluxcd.io/flagger> - this is part of a bigger move to subsume all
  of our documentation and web-presence into one place, so we won't
  have to maintain too many pieces of infrastructure.\
  This has been on our to-do list since Flux became a CNCF
  Incubating project. Now that we are going for Graduation, we
  finally got around to doing it.

Thanks a lot to these folks who contributed to docs and website: Ihor
Sychevskyi, Kingdon Barrett, Stefan Prodan, Endre Czirbesz, Maarten de
Waard and Patrick Rodies.

In particular we would like to thank Ihor Sychevskyi who recently took
on fixing small UI glitches all over the place - especially on mobile
the site should work a lot better now!

## Flux Project Facts

We are very proud of what we put together, here we want to reiterate
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
  chat systems](/flux/components/notification/provider/).
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
  2022-05-05 or 2022-05-11.
- Talk to us in the \#flux channel on [CNCF
  Slack](https://slack.cncf.io/)
- Join the [planning
  discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux, take a look at our [Get
  Started guide](/flux/get-started/) and give us feedback
- Social media: Follow [Flux on Twitter](https://twitter.com/fluxcd),
  join the discussion in the [Flux LinkedIn
  group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.
