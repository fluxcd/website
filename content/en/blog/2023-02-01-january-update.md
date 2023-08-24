---
author: dholbach
date: 2023-02-01 08:30:00+00:00
title: January 2023 Update
description: "After Graduation Flux and Flagger development continue at full pace. Here is our update of December and January full of new releases, features, events and community news."
url: /blog/2023/02/january-2023-update/
tags: [monthly-update]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

As the Flux family of projects and its communities are growing, we
strive to inform you each month about what has already landed, new
possibilities which are available for integration, and where you can get
involved. Read our last update [here](/blog/2022/12/november-2022-update/).

Now it's the beginning of February 2023 - let's recap together what
happened in December and January - it has been a lot!

## News in the Flux family

### Flux 0.38 brings performance improvements and new features

We have released Flux v0.38. Users are encouraged to upgrade for the best
experience. Here is a short summary of its features and improvements:

- Graduation of Notification APIs to `v1beta2`, to upgrade please see
  [the release notes](https://github.com/fluxcd/flux2/releases/tag/v0.38.0).
- Support for defining Kustomize components with `Kustomization.spec.components`.
- Support for piping multi-doc YAMLs when publishing OCI artifacts with
  `kustomize build . | flux push artifact --path=-`.
- Support for Gitea commit status updates with `Provider.spec.type` set to
  `gitea`.
- Improve the memory usage of `helm-controller` by disabling the caching of
  `Secret` and `ConfigMap` resources.
- Update the Helm SDK to v3.10.3 (fix for Helm CVEs).
- All code references to `libgit2` were removed, and the
  `GitRepository.spec.gitImplementation` field is no longer being honored.

The official [example repository](https://github.com/fluxcd/flux2-kustomize-helm-example)
was refactored. The new version comes with the following improvements:

- Make the example compatible with ARM64 Kubernetes clusters.
- Add Weave GitOps Helm release to showcase the [Flux
  UI](https://github.com/fluxcd/flux2-kustomize-helm-example#access-the-flux-ui).
- Replace the ingress-nginx Bitnami chart with the official one that contains
  multi-arch container images.
- Add cert-manager Helm release to showcase how to install CRDs and custom
  resources using `dependsOn`.
- Add Let’s Encrypt ClusterIssuer to showcase how to patch resources in
  production with Flux `Kustomization`.
- Add the `flux-system` overlay to showcase how to configure Flux at
  bootstrap time.

♥ Big thanks to all the Flux contributors that helped us with this release!

### Security news

Flux 0.39, the [upcoming release](https://github.com/fluxcd/flux2/issues/3533),
will come with SBOMs and SLSA Provenance attached to all the controllers
container images. In addition, all controller images will be updated to
Alpine 3.17 (which contains CVE fixes for OS packages).

Starting with 0.39, the Flux controllers should consume less memory on busy
clusters due to the disabling of `Secret` and `ConfigMap` caching.

### Flagger 1.27 and 1.28 add support for APISIX and different autoscaling configs

1.28 comes with support for setting a different autoscaling
configuration for the primary workload.
The `.spec.autoscalerRef.primaryScalerReplicas` is useful in the
situation where the user does not want to scale the canary workload
to the exact same size as the primary, especially when opting for a
canary deployment pattern where only a small portion of traffic is
routed to the canary workload pods.

1.27 comes with support for [Apache APISIX](https://apisix.apache.org/).
For more details see [the tutorial](/flagger/tutorials/apisix-progressive-delivery).

### Flux Ecosystem

#### Flux Subsystem for Argo

[Flamingo](https://github.com/flux-subsystem-argo/flamingo) is a tool that
combines Flux and Argo CD to provide the best of both worlds for
implementing GitOps on Kubernetes clusters. With Flamingo, you can:

- Automate the deployment of your applications to Kubernetes clusters and
  benefit from the improved collaboration and deployment speed and
  reliability that GitOps offers.
- Enjoy a seamless and integrated experience for managing deployments,
  with the automation capabilities of Flux embedded inside the
  user-friendly interface of Argo CD.
- Take advantage of additional features and capabilities that are not
  available in either Flux or Argo CD individually, such as the robust Helm
  support from Flux, Flux OCI Repository, Weave GitOps Terraform Controller
  for Infrastructure as Code, Weave Policy Engine, or Argo CD
  `ApplicationSet` for Flux-managed resources.

In recent releases, the team updated Flamingo to support Flux v0.38 and Argo
CD v2.5.7, v2.4.19 and v2.3.13. Please note that Argo CD v2.2 will not be
supported and updated by Flamingo anymore.

|Flux  | Argo CD | Image
|:----:|:-------:|---------------------------
|v0.38 | v2.5    | v2.5.9-fl.3-main-14aff24e
|v0.38 | v2.4    | v2.4.21-fl.3-main-14aff24e
|v0.38 | v2.3    | v2.3.15-fl.3-main-14aff24e
|v0.37 | v2.2    | v2.2.16-fl.3-main-2bba0ae6

#### Terraform-controller

The [tf-controller](https://github.com/weaveworks/tf-controller) team
is currently working on getting [the new release
v0.14](https://github.com/weaveworks/tf-controller/issues/344) out.
They are updating the Terraform binary to version 1.3.7 and the Flux tool
to version 0.38. Additionally, they are fixing the Helm chart and enabling
the parallelism option for the apply stage. They are currently at release
candidate v0.14.0-rc.2 with the new Helm chart version 0.10.0. Please stay
tuned for further updates.

#### Weave GitOps

Besides a huge amount of general small improvements, the team has fixed two
security vulnerabilities
([1](https://github.com/weaveworks/weave-gitops/security/advisories/GHSA-wr3c-g326-486c),
[2](https://github.com/weaveworks/weave-gitops/security/advisories/GHSA-89qm-wcmw-3mgg))
and made [GitOps Run](https://docs.gitops.weave.works/docs/gitops-run/overview/) much
more secure along the way. If you're using a version older than 0.12.0 you are highly
encouraged to upgrade.

Also with GitOps Run you can now open the deployed application's Web UI by
simply hitting a key on your keyboard. GitOps Run sets up the port-forwarding
and opens up a browser window for you.

As always lots of improvements went into Weave GitOps' Web UI so make sure to
take a look.

On the Weave GitOps Enterprise side you can now automatically [create Pipelines
from
GitOpsTemplates](https://docs.gitops.weave.works/docs/pipelines/pipeline-templates/),
the [Terraform UI](https://docs.gitops.weave.works/docs/terraform/overview/)
has been improved to allow for a more detailed view into a Terraform inventory
and [support for observing and managing
Secrets](https://docs.gitops.weave.works/docs/releases/#secrets-management) has
landed in its initial incarnation.

## Recent & Upcoming Events

It's important to keep you up to date with new features and developments
in Flux and provide simple ways to see our work in action and chat with
our engineers.

### Recent Events (ICYMI) 📺

We feel blessed to have such a big community of users, contributors and
integrators and so many are happy to talk about their experiences. In
December and January here are a couple of talks we would like to highlight.

{{< youtube JHmQlSvL0II >}}

> HashiCorp User Group Luxembourg: GitOps your Terraform Configurations
>
> Flux Terraform Controller is a controller for Flux to reconcile Terraform
> configurations in the GitOps way with the power of Flux and Terraform,
> Terraform Controller allows you to GitOps-ify your infrastructure, and
> your application resources, in the Kubernetes and Terraform universe.
>
> Flux Terraform Controller ensures what you’ve defined in your Terraform
> configurations is what’s always running and available. Flux continuously
> looks for changes and reconciles with the desired state. Take advantage
> of all the benefits of GitOps: streamlined and secure deployments, quicker
> time to market, and more time to concentrate on app development!

{{< youtube uRiCRTSkPOQ >}}

> Flux’s Security & Scalability with OCI & Helm (Part 2) with Kingdon Barrett
>
> With Flux, you can distribute and reconcile Kubernetes configuration packaged
> as OCI artifacts. Instead of connecting Flux to a Git repository where the
> application desired state is defined, you can connect Flux to a container
> registry where you’ll push the application deploy manifests, right next to
> the application container images.
>
> During this session Kingdon Barrett, OSS Engineer at Weaveworks & Flux
> Maintainer, shows you how to quickly create scalable and Cosign-verified GitOps
> configurations with Flux using the same process with two demo environments: one
> will be a Kustomize Environment and the other a Helm-based environment.

{{< youtube Bmh7kKYLIhY >}}

> Flux Security & Scalability using VS Code GitOps Extension
>
> Recently Flux has released two new features (OCI and Cosign) for scalable and
> secure GitOps. Juozas Gaigalas, a Developer Experience Engineer at Weaveworks,
> will demonstrate how developers and platform engineers can quickly create
> scalable and Cosign-verified GitOps configurations using VS Code GitOps Tools
> extension. New and experienced Flux users can learn about Flux’s OCI and Cosign
> support through this demo. Join us!

Here is a list of additional videos and topics we really enjoyed -
please let us know if we missed anything of interest and we will make
sure to mention it in the next post!

{{< youtube H9MJtNSYFi8 >}}

{{< youtube al049I2j1jk >}}

### Upcoming Events 📆

We are happy to announce that we have a number of events coming up in
February - tune in to learn more about Flux and GitOps best practices,
get to know the team and join our community.

### Flux Bug Scrub

Our Flux Bug Scrubs still are happening on a weekly basis and remain one
of the best ways to get involved in Flux. They are a friendly and
welcoming way to learn more about contributing and how Flux is organised
as a project.

The next dates are going to be:

- [2023-02-02 18:00 UTC, 19:00 CET](/#calendar)
- [2023-02-08 13:00 UTC, 14:00 CET](/#calendar)
- [2023-02-16 18:00 UTC, 19:00 CET](/#calendar)
- [2023-02-22 13:00 UTC, 14:00 CET](/#calendar)

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

### Conference Call For Papers

Conferences are all about the people. It's also more fun to present
together. You get to share collective experience and be more entertaining
as a duo!

Two upcoming call for paper deadlines are the following

- CFP until 2023-02-05, [SustainabilityCon](https://events.linuxfoundation.org/cdcon-gitopscon/program/cfp/)
  > May 10 – 12, 2023 | Vancouver, Canada
  > Join the community of developers, technologists, sustainability leaders
  > and anyone working on technological solutions to decarbonize the global
  > economy, mitigate and address the impacts of climate change, and build a
  > more sustainable future. SustainabilityCon provides a forum to drive open
  > source innovation in energy efficiency and interoperability and clean
  > development practices within industries ranging from manufacturing to
  > agriculture and beyond through collaboration and learning within the community.
- CFP until 2023-02-10, [GitOpsCon](https://events.linuxfoundation.org/cdcon-gitopscon/program/cfp/)
  > May 8 – 9, 2023 | Vancouver, Canada
  >
  > cdCon + GitOpsCon is designed to foster collaboration, discussion, and
  > knowledge sharing by bringing two communities together. It’s the best
  > place for vendors and end users to collaborate in shaping the future of
  > GitOps and Continuous Delivery (CD).

Talk to Niki Manoledaki for SustainabilityCon and in general to Vanessa
Abankwah and Stacey Potter if you want to present anything Flagger, Flux,
GitOps related at any of the events with us!

### Soulé Ba joins Flux Core Maintainers

Soulé Ba has been working on Flux for a long while. Already a maintainer
of Flux's `go-git-providers`, he didn't stop there but was involved in
a lot of the RFC planning process of many features and contributed code and
fixes for a long long time.

The Flux community is grateful to have you. Well deserved becoming a
[Core maintainer now](https://github.com/fluxcd/community/pull/271), Soulé!

### Your Community Team

We have been working on filling up the speakers calendar for the next weeks
and organising proposals for the upcoming CFP deadlines for the next
conferences. If you are interested in speaking about Flux and GitOps, please
reach out to us!

Next up we are going to look into [making our Community page more interesting
and useful](https://github.com/fluxcd/website/issues/1102). We are also going
to [apply for Google Season of
Docs](https://github.com/fluxcd/website/issues/1363). If you have input or
ideas and would like to get involved, talk to us on Slack!

### People writing/talking about Flux

We love it when you all write about Flux and share your experience,
write how-tos on integrating Flux with other pieces of software or other
things. Give us a shout-out and we will link it from this section! ✍

[Bill Doerrfeld: Introduction to Flux
(containerjournal.com)](https://containerjournal.com/features/introduction-to-flux/)

Read more in this article about Flux, where Bill interviewed Priyanka "Pinky"
Ravi about what's new in Flux. It's a nice introduction to Flux.

> GitOps has become a chosen strategy for releasing and deploying
> cloud-native microservices. The goal of GitOps, a term coined by Alexis
> Richardson, CEO of Weaveworks, in 2017, is to “make operations automatic
> for the whole system based on a model of the system which was living
> outside the system.” And propelling the GitOps practice is Flux, an open
> source tool that provides GitOps for apps and infrastructure.
>
> In late 2022, Flux became the 18th project to reach graduation status with
> the Cloud Native Computing Foundation (CNCF). Earlier this year, downloads of
> the Flux container image surpassed a staggering one billion.

[Max Strübing: Automatic deployment updates with Flux (D2iQ Engineering
Blog)](https://eng.d2iq.com/blog/automatic-deployment-updates-with-flux/)

We were very pleased to see this blog post from our friends at D2iQ. Do go
check it out, particularly if you are new to Flux. Max takes a how-to approach
to explaining automatic deployment updates with Flux and explains why this
is generally a good idea:

> - You can deploy fast, easily and often by simply pushing to a repository
> - You can run a git revert if you messed up your environment and everything
    is like it was before
> - This means you can easily roll back to every state of your application or
    infrastructure
> - Not everyone needs access to the actual infrastructure environment, access
    to the git repository is enough to manage the infrastructure
> - Self-documenting infrastructure: you do not need to ssh into a server and
    look around running services or explore all resources on a Kubernetes cluster
> - Easy to create a demo environment by replicating the repository or creating
    a second deploy target

### News from the Website and our Docs

#### Flux Adopters shout-out

We are very pleased to announce that the following adopters of Flux have
come forward and added themselves to our website:
[DoneOps](https://www.doneops.com/) and [Riley](https://riley.ai/).

If you have not already done so, [use the instructions
here](/adopters/) or give us a ping and we will help to add you. Not only
is it great for us to get to know and welcome you to our community. It
also gives the team a big boost in morale to know where in the world
Flux is used everywhere.

#### More docs and website news

We are constantly improving our documentation and website - here are a
couple of small things we landed recently:

- The [Flux landing page](/) is shorter and less overwhelming now.
  This was achieved by moving the adopters logos into a horizontal
  scroll band, dropping some old content and there will be more to
  come here.
- Flagger docs were update to the latest.
- Flux Bootstrap: cheatsheet for how to [Persistent storage for Flux
  internal artifacts](/flux/installation/configuration/vertical-scaling/#persistent-storage-for-flux-internal-artifacts)
- [Our FAQ](/flux/faq/) now has entries about how to safely rename a
  Flux Kustomization and how to set local overrides to a Helm chart.
  As it's one of the very common FAQs: We also mention the different
  Flux UIs a lot more prominently now!
- [Flux GCP docs](/flux/use-cases/gcp-source-repository/) were updated.
- We improved the [Flux Support page](/support) to be even clearer
  about how to get Support for Flux, no matter if it's professionally
  or for community support.
- We renived a lot of unnecessary website build code; now a lot of the
  dynamic content is generated straight from YAML through Hugo Data
  Templates. This makes the website build process a lot more stable
  and we have less build scripts to maintain!
- Update to latest hugo plus docsy and gallery themes.

Thanks a lot to these folks who contributed to docs and website: Stefan
Prodan, Arhell, Aurel Canciu, Hidde Beydals, Sanskar Jaiswal, h20220026,
Paulo Gomes, Stacey Potter, Johannes Wienke, Jonathan Meyers, Kingdon
Barrett, Lassi Pölönen, Max Jonas Werner, Nate, Scott Rigby, Sunny,
Tarunbot, h20220025, surya.

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
  2023-02-09 or 2023-02-15.
- Talk to us in the #flux channel on [CNCF Slack](https://slack.cncf.io/)
- Join the [planning discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux, take a look at our [Get
  Started guide](/flux/get-started/) and give us feedback
- Social media: Follow [Flux on Twitter](https://twitter.com/fluxcd),
  join the discussion in the [Flux LinkedIn
  group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.
