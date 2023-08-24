---
author: dholbach
date: 2022-01-31 9:30:00+00:00
title: January 2022 Update
description: New Flux and Flagger releases bring more security, terraform-controller team wants feedback, Flux articles and docs, upcoming Flux events helping you get started and more.
url: /blog/2022/01/january-update/
resources:
- src: "**.png"
  title: "Image #:counter"
tags: [monthly-update]
---

As the Flux family of projects and its communities are growing, we
strive to inform you each month about what has already landed, new
possibilities which are available for integration, and where you can get
involved. Read our [last update here](/blog/2021/11/december-update/).

It's the beginning of February 2022 and you have been waiting for a long
time - let's recap together what happened in January and December- there
has been so much happening!

## News in the Flux family

### Flux v0.26: more secure by default

We released [Flux v0.26.0](https://github.com/fluxcd/flux2/releases/tag/v0.26.0).
This release comes with new features and improvements.

First of all, please note that the minimum supported version of
Kubernetes is now v1.20.6. Flux may work on Kubernetes 1.19, but we
don't recommend running EOL versions in production.

On multi-tenant clusters, Flux controllers are now using the native
Kubernetes impersonation feature. When both `spec.kubeConfig` and
`spec.ServiceAccountName` are specified in Flux custom resources, the
controllers will impersonate the service account on the target cluster,
previously the controllers ignored the service account.

#### :lock: Security enhancements

- Platform admins have the option to [lock down Flux on multi-tenant
  clusters](/flux/installation/configuration/multitenancy/)
  and enforce tenant isolation at namespace level without having to
  use a 3rd party admission controller.
- The Flux installation conforms to the Kubernetes [restricted pod
  security standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted)
  and the Seccomp runtime default security profile was enabled for
  all controllers.
- The container images of all Flux's components are signed with
  [Cosign and GitHub OIDC](/flux/security/#signed-container-images).
- Flux releases include a [Software Bill of Materials
  (SBOM)](/flux/security/#software-bill-of-materials)
  that is available for download on the GitHub release page.

#### :rocket: New features and improvements

{{< imgproc featured-image Resize 800x >}}
New feature in action: flux diff kustomization
{{< /imgproc >}}

- Preview local changes against live clusters with the `flux diff
  kustomization` command.
- Undo changes made directly on clusters (with `kubectl` server-side
  apply) to Flux managed objects.
- Native support for [Hashicorp
  Vault](/flux/components/kustomize/kustomization/#hashicorp-vault)
  token-based authentication when decrypting SOPS encrypted secrets.
- Auto-login to AWS ECR, Azure ACR and Google Cloud GCR for [image
  update
  automation](/flux/guides/image-update/#imagerepository-cloud-providers-authentication)
  on EKS, AKS or GKE.
- On single-tenant clusters, image automation can now refer to Git
  repositories in other namespaces than the
  ImageImageUpdateAutomation object.

### Flux v0.25 the last to officially support Kubernetes 1.19

The Flux community has been hard at work and released Flux 0.25. We
encourage you to upgrade for the best experience!

- This version aligns Flux and its components with the [Kubernetes
  1.23](https://kubernetes.io/blog/2021/12/07/kubernetes-1-23-release-announcement/)
  release and [Helm
  3.7](https://github.com/helm/helm/releases/tag/v3.7.0).
- The Flux CLI and the GitOps Toolkit controllers are now built with
  Go 1.17 and Alpine 3.15.
- In addition, various Go and OS packages were updated to fix known
  CVEs.

:warning: Note that Kubernetes 1.19 has reached
end-of-life in November 2021. This is the last Flux release where
Kubernetes 1.19 is supported.

### Flagger 1.17 has landed

This release comes with support for [Kuma Service
Mesh](https://kuma.io/). For more details see the [Kuma
Progressive Delivery
tutorial](/flagger/tutorials/kuma-progressive-delivery).

{{< imgproc flagger-kuma-canary Resize 600x >}}
Kuma Progressive Delivery with Flagger
{{< /imgproc >}}

To differentiate alerts based on the cluster name, you can configure
Flagger with the `-cluster-name=my-cluster` command flag, or with Helm
`--set clusterName=my-cluster`.

In addition to that, Flagger now publishes a Software Bill of Materials
(SBOM) for every release and we added the cluster name to flagger
comment arguments for altering.

### Security news

Security was a big focus for us in the past weeks. If you take a look at
the ["Follow-Up" project](https://github.com/orgs/fluxcd/projects/5) after
the [CNCF-funded audit](/blog/2021-11-10-flux-security-audit/),
you will notice that almost all the tasks have been done (or are indeed
very close). It's largely the fuzzing work which is close to land and
some additional documentation. 2.5 months after the audit concluded we
are quite happy with where we have arrived - having the analysis of the
auditors in front of us gave us a solid focus.

In the 0.26 release of Flux, we applied the [restricted pod security
standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted)
to all controllers.
In practice this means:

- all Linux capabilities were dropped
- the root filesystem was set to read-only
- the `seccomp` profile was set to the runtime default
- run as non-root was enabled
- the filesystem group was set to 1337
- the user and group ID was set to 65534

Flux also enables the Seccomp runtime default across all controllers. Why is
this important? Well, the default `seccomp` profile blocks key system
calls that can be used maliciously, for example to break out of the
container isolation. The recently disclosed [kernel vulnerability
CVE-2022-0185](https://blog.aquasec.com/cve-2022-0185-linux-kernel-container-escape-in-kubernetes)
is a good example of that.

Big news are also that we

- [Publish SBOM for Flux and the GitOps Toolkit
  components](https://github.com/fluxcd/flux2/issues/2302)
  and
- [Sign the release checksums and container images with Cosign and
  GitHub
  OIDC](https://github.com/fluxcd/flux2/issues/2303)

One bit we are still working on and will be part of the next release is
upgrading our [dependency libgit2 to
1.3.0](https://github.com/fluxcd/source-controller/pull/557),
which will add support for ed25519 for both client authentication and
hostKey verification.

### A word on RFCs

After reviews from all maintainers, [RFC-0001
Authorization](https://github.com/fluxcd/flux2/tree/main/rfcs/0001-authorization)
is merged. This RFC describes in detail, for [Flux version
0.24](https://github.com/fluxcd/flux2/releases/tag/v0.24.0),
how Flux determines which operations are allowed to proceed, and how
this interacts with Kubernetes\' access control.

To this point, the Flux project has provided [examples of how to make a
multi-tenant
system](https://github.com/fluxcd/flux2-multi-tenancy/tree/v0.1.0),
but not explained exactly how they relate to Flux\'s authorization
model; nor has the authorization model itself been documented. Further
work on support for multi-tenancy, among other things, requires a full
account of Flux\'s authorization model as a baseline.

**Goals**: Give a comprehensive account of Flux\'s authorization model

**Non-Goals**: Justify the model as it stands; this RFC simply records
the state as at v0.24.

## Recent & Upcoming Events

It's important to keep you up to date with new features and developments
in Flux and provide simple ways to see our work in action and chat with
our engineers.

### January 27: GitOps & Flux: A Refresher - Priyanka Ravi

[View the video here](https://youtu.be/81EOeobifio).

Priyanka "Pinky" Ravi is an end user of GitOps and Flux, and now is
advocating for others like you to enjoy the benefits of GitOps today!

:tada: Benefits of GitOps and Flux!
How GitOps and Flux bring you security, reliability, velocity and more -
no more pagers on Saturdays! no more breaches to the cluster that you
can\'t roll back. no more worrying about how you\'ll fare in the next
security audit.

Pinky shares from personal experience why GitOps has been an essential
part of achieving a best-in-class delivery and platform team.

:tada: What is GitOps and Flux?
For beginners and advanced users alike, Pinky gives a brief overview of
definitions, CNCF-based principles, and Flux\'s capabilities:
multi-tenancy, multi-cluster, (multi-everything!), for apps and infra,
and more.

:tada: How Flux delivers these benefits
Pinky covers a little of Flux\'s microservices architecture and how the
various components deliver this robust, secure, and trusted open source
solution. Through the components of the Flux project, users today are
enjoying compatibility with Helm, Jenkins, Terraform, Prometheus, and
more as well as with cloud providers such as AWS, Azure, Google Cloud,
and more.

### February 2: Get Started with Flux - Priyanka Ravi

[Register here](https://www.meetup.com/GitOps-Community/events/283239976/)

Is your team stuck working weekends during an upgrade? Dealing with long
deployment windows due to manual processes? Are you tired of dealing
with too many vendor tools, or not having an audit trail for
compliance?

There\'s got to be a better way!

There is, and during this session Priyanka \"Pinky\" Ravi will give you
an overview of how to get better security, velocity, and reliability
with GitOps, and then how to get GitOps going on your own machine!

By the end of this talk, you\'ll see two easy paths to getting GitOps up
and running using Flux on Kubernetes. You\'ll see GitOps in action with
a sample app that you deploy and then customize using configs. And then
you\'ll hear ways that delivery and platform teams today are benefitting
from GitOps, saving them from headaches, boredom, fires, and saving them
time and money. Join us!

### February 16: GitOps with Amazon EKS Anywhere + Flux - Dan Budris

[Register here](https://www.meetup.com/GitOps-Community/events/283339915/)

Amazon EKS Anywhere is an open-source tool which helps you create and
manage Kubernetes clusters on-premises. EKS Anywhere allows you to
manage your Kubernetes clusters in a scalable and declarative manner
with the help of GitOps, powered under-the-hood with CNCF Flux. In this
session, Dan will share how EKS Anywhere integrates with Flux and uses
GitOps workflows to manage the cluster lifecycle.

Dan is a Software Engineer on the AWS EKS Anywhere team, working on
tools to help developers easily build and manage Kubernetes clusters on
premises. In the past, Dan has worked as a System Administrator, DevOps
Engineer, SRE, gardener, cook and professional door-knocker. When he's
not helping to build EKS Anywhere you can find him weeding the garden or
in the kitchen working his way through another cookbook.

### March 2: Managing Thousands of Clusters & Their Workloads with Flux - Max Jonas Werner

[Register here](https://www.meetup.com/GitOps-Community/events/283484465/)

One of the main goals of DevOps is to automate operations as much as
possible. By automating most operations, DevOps can provide business
agility and allow Developers to focus more on business applications.
This allows operations to be more efficient by being less error-prone
and repeatable, improving the overall developer experience. D2iQ uses
Flux to automatically enable this experience in its products. Join us
for a hands-on session on multi-cluster management using GitOps.

Max is a Senior Software Engineer at D2iQ (formerly Mesosphere) and is
based out of Hamburg. He is one of the lead developers of D2iQ\'s
multi-cluster management offering that is based on Flux.

### Flux Bug Scrub

If you've never joined a Flux Bug Scrub before, (or even if you have) we
welcome you to join this weekly meeting with Flux developers which is an
open "office hour" where we visit issues and discussions in the Flux
org, and have open discussion about it. We also try to make sure that
nobody is left blocked on an important question, waiting for a response.

This is a great venue for beginners to meet the Flux team and find "good
first issues" as we triage new issues together; you can get an issue
assigned to you here, a great help for folks as they are learning and
getting involved with the Flux Open Source project.

In the coming weeks, we also plan to make some additional changes to the
Bug Scrub format, opening up the possibility that we will have planned
presentations or predetermined discussion topics, so that these meetings
are less random and we can attract more interest. Look to the schedule
for information about how to join at
[https://fluxcd.io/\#calendar](/#calendar)
or [add the Flux events to your own
calendar](/community/#subscribing-to-the-flux-calendar)
if you want to participate, and be sure you don't miss out on the new
Flux Bug Scrub, Special Edition!

## In other news

A big shout-out to our friends at the Cloud Native Computing Foundation
(CNCF)! As part of [being an Incubating
project](/blog/2021/03/flux-is-a-cncf-incubation-project/),
we have access to resources which help us build and deliver Flux to a
significant degree.

This time around, we were [granted some Equinix ARM
machines](https://github.com/cncf/cluster/issues/196) to
help us with builds and running end-to-end tests on ARM64. A big thanks
from our community... :smiling_face_with_hearts:

### Community project: Terraform Controller for Flux

Chanwit Kaewkasi and others have been hard at work. They created a
[Flux controller which reconciles
Terraform](https://github.com/chanwit/tf-controller)
resources in the GitOps way.

It's important to understand that this is different from
`fluxcd/terraform-provider-flux`, which is for bootstrapping Flux from
Terraform (by a Terraform user).

The TF-controller is a Kubernetes controller that allows a Flux /
Kubernetes user to reconcile Terraform resources, e.g. deploying
PostgreSQL on AWS, enforcing Security Groups, and preparing IAM Role
Policies. So it considerably extends the scope of what is being
GitOps'ed.

It comes with GitOps models to support reconciling Terraform resources
within GitOps pipelines. For example,

- Full GitOps Automation
- GitOps for Existing Terraform resources
- GitOps model for plan and manually apply Terraform
- Drift Detection of Terraform resources

Its README goes into quite a bit of detail on how to make use of it. Its
latest version 0.8.0 supports Flux v0.25.x and Terraform 1.1.4. The Helma
chart for TF-controller is also available.

Please note that TF-controller isn't supporting multi-tenancy yet. And
we\'re actively working on a model of it:
[https://github.com/chanwit/tf-controller/issues/59](https://github.com/chanwit/tf-controller/issues/59)

We very much appreciate Chanwit and friends working on this and want to
extend their request for testing and feedback - take it for a spin and
let them know how it's working!

### People writing/talking about Flux

[Deutsche Telekom preps Kubernetes 5G core with
GitOps](https://searchitoperations.techtarget.com/news/252510456/Deutsche-Telekom-preps-Kubernetes-5G-core-with-GitOps)
📃

Beth Pariseau recently wrote about how "GitOps will help the German
mobile carrier manage IT automation for its 5G SA app on a large
internal Kubernetes platform with minimal staff needed to do hands-on
administration." Deutsche Telekom uses Flux in its [Das
Schiff](https://github.com/telekom/das-schiff) project, you
can also find this listed as an
[Integration](/integrations/) on our
website.

[Flux Multi-Cluster Multi-Tenant by Example
(Continued)](https://john-tucker.medium.com/flux-multi-cluster-multi-tenant-by-example-continued-4caa024e6dc7)
📃

John Tucker walks through this continuation of a [previous
article](https://john-tucker.medium.com/flux-multi-cluster-multi-tenant-by-example-a8d6f9cc82f0)
for using Flux to deliver applications in a multi-cluster multi-tenant
Kubernetes environment.

[Flux - Kubernetes GitOps (CNCFMinutes
20)](https://youtu.be/1X3JgCnRNsw) 📺

Want to know what Flux is and does in \~8 minutes? CNCF Ambassador
[Saiyam Pathak](https://twitter.com/saiyampathak) gave a
[brief overview of Flux](https://youtu.be/1X3JgCnRNsw) on
his [CNCFMinutes YouTube
Series](https://youtube.com/playlist?list=PL5uLNcv9SibB658blGUEv18IhcMGL0dxC)

Dan Wessels, Field Engineer at Solo.io has a couple of articles and a
talk to share on Flux:

- [https://www.solo.io/blog/gloo-edge-api-gateway-multi-cluster-provisioning-with-gitops/](https://www.solo.io/blog/gloo-edge-api-gateway-multi-cluster-provisioning-with-gitops/)
  📃
- [https://www.solo.io/blog/the-3-best-ways-to-use-flux-and-flagger-for-gitops-with-your-envoy-proxy-api-gateways/](https://www.solo.io/blog/the-3-best-ways-to-use-flux-and-flagger-for-gitops-with-your-envoy-proxy-api-gateways/)
  📃
- [Flux Booth talk: GitOps and Cloud Native API Gateways by Dan
  Wessels](https://youtu.be/yzE-9qgyJGg) 📺

The [External Secrets Operator
project](https://external-secrets.io/) describes itself as

> a Kubernetes operator that integrates external secret management
> systems like [AWS Secrets
> Manager](https://aws.amazon.com/secrets-manager/),
> [HashiCorp Vault](https://www.vaultproject.io/),
> [Google Secrets
> Manager](https://cloud.google.com/secret-manager),
> [Azure Key
> Vault](https://azure.microsoft.com/en-us/services/key-vault/)
> and many more. The operator reads information from external APIs and
> automatically injects the values into a [Kubernetes
> Secret](https://kubernetes.io/docs/concepts/configuration/secret/).

The team around it also wrote a [guide on how to use it with
Flux](https://external-secrets.io/guides-gitops-using-fluxcd/) - check it out.

There is also [Introduction to GitOps with Flux
v2](https://armmaster17.github.io/2021/11/07/gitops1/) by
[Joshua Zenn](https://twitter.com/zennjos) 📃.

### News from the Website and our Docs

How we present ourselves to users on our website and how we talk about
Flux and explain it in our documentation is important to us.

So since the last Flux update blog we got a lot done:

- We added instructions on how to [encrypt secrets using HashiCorp
  Vault](/flux/guides/mozilla-sops/#encrypting-secrets-using-hashicorp-vault)
- Also [instructions for auto-login
  (ACR/ECR/GCR)](/flux/guides/cron-job-image-auth/)
- We explain [how to bootstrap Flux on AWS EKS with CodeCommit Git
  repositories](/flux/use-cases/aws-codecommit/)
- Docs updates for Flux v0.26.0, including a \"Multi-tenancy
  lockdown\" section in the install docs
- References in the Helm Operator (legacy) section were updated to
  1.4.2.
- Updated Flux endorsements and [Resources - so many
  resources](/resources/)
- Many docs improvements and internal bug fixes
- Again we updated our internal dependencies like Hugo and Docsy to
  the latest to benefit from upstream fixes and new features

Thanks a lot to these contributors: Stefan Prodan, Lloyd Chang, Kingdon
Barrett, Andri Muhyidin, Luke Mallon, Somtochi Oneykwere, Stacey Potter,
Christian Berendt, Daniel Quackenbush, Hidde Beydals, Iñigo Iglesias,
Jens Fosgerau, Moritz, Phil Fenstermacher, Sam Cook, Scott Rigby, Soulé
Ba and vasu1124.

We are proud to announce new [Flux adopters](/adopters/) who officially
joined our community since last time: [SAP SE](https://sap.com),
[Alea](https://www.alea.com), [William & Mary](https://www.wm.edu),
[23 Technologies GmbH](https://www.23technologies.cloud), [DKB
Codefactory](https://www.dkbcodefactory.com), [99 Group](https://www.99.co),
[Trendhim](https://www.trendhim.com).

If you would like to add your organisation to the Flux Adopters page,
[here's how](https://github.com/fluxcd/website/tree/main/adopters).

#### CNCF TechDocs Team assess Flux Docs and Website

Alison Dowdney talked to the CNCF TechDocs team and asked for an
assessment of our docs and website to help us understand how we can
further improve. We are very grateful for the hard work Celeste Horgan
put into assessing our docs and [compiling a
report](https://github.com/cncf/techdocs/blob/main/assessments/0005-fluxcd.md).

We are very pleased with the outcome: our site consistently scores 4 or
5 (out of 5) on all criteria. There are a couple of very wise
recommendations we will discuss in our next dev meetings to figure out a
way forward. If you want to know more, either read the report, or have a
look at the [project
board](https://github.com/orgs/fluxcd/projects/3) we set up
to track this effort.

If you would like to [work with
us](/contributing/docs/) on the
website and documentation, please reach out to us on Slack. 💖

Thanks again CNCF and TechDocs team - we very much appreciate being part
of this community and receiving so much support in growing our project!

## Flux Project Facts!

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

- Join our [upcoming dev
  meetings](/community/#meetings) on
  2022-02-02 or 2022-02-10.
- Talk to us in the \#flux channel on [CNCF
  Slack](https://slack.cncf.io/)
- Join the [planning
  discussions](https://github.com/fluxcd/flux2/discussions)
- And if you are completely new to Flux, take a look at our [Get
  Started guide](/flux/get-started/)
  and give us feedback
- Social media: Follow [Flux on
  Twitter](https://twitter.com/fluxcd), join the
  discussion in the [Flux LinkedIn
  group](https://www.linkedin.com/groups/8985374/).

We are looking forward to working with you.
