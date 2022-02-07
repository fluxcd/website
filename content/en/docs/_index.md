---
title: "Flux Documentation"
linkTitle: "Docs"
description: "Open and extensible continuous delivery solution for Kubernetes."
taxonomyCloud: []
---

Flux is a tool for keeping Kubernetes clusters in sync with sources of
configuration (like Git repositories), and automating updates to
configuration when there is new code to deploy.

Flux is built from the ground up to use Kubernetes'
API extension system, and to integrate with Prometheus and other core
components of the Kubernetes ecosystem. In version 2, Flux supports
multi-tenancy and support for syncing an arbitrary number of Git
repositories, among other long-requested features.

## Who is Flux for?

Flux helps

- **cluster operators** who automate provision and configuration of clusters;
- **platform engineers** who build continuous delivery for developer teams;
- **app developers** who rely on continuous delivery to get their code live.

## What can I do with Flux?

Flux is based on a set of Kubernetes API extensions ("custom
resources"), which control how git repositories and other sources of
configuration are applied into the cluster ("synced").
For example, you create a `GitRepository` object to mirror
configuration from a Git repository, then a `Kustomization` object to
sync that configuration.

Flux works with Kubernetes' role-based access control (RBAC), so you
can lock down what any particular sync can change. It can send
notifications to Slack and other like systems when configuration is
synced and ready, and receive webhooks to tell it when to sync.

The `flux` command-line tool is a convenient way to bootstrap the
system in a cluster, and to access the custom resources that make up
the API.

## Where do I start?

{{% alert title="Get started with Flux!" %}}
Following this [guide](get-started/) will just take a couple of minutes to complete:
After installing the `flux` CLI and running a couple of very simple commands,
you will have a GitOps workflow setup which involves a staging and a production cluster.
{{% /alert %}}

If you should need help, please refer to our **[Support page](/support/)**.

## More detail on what's in Flux

Features:

- Source configuration from Git and Helm repositories, and
  S3-compatible buckets (e.g., Minio)
- Kustomize and Helm support
- Event-triggered and periodic reconciliation
- Integration with Kubernetes RBAC
- Health assessment (clusters and workloads)
- Dependency management (infrastructure and workloads)
- Alerting to external systems (webhook senders)
- External events handling (webhook receivers)
- Automated container image updates to Git (image scanning and patching)
- Policy-driven validation (OPA, Kyverno, admission controllers)
- Seamless integration with Git providers (GitHub, GitLab, Bitbucket)
- Interoperability with workflow providers (GitHub Actions, Tekton, Argo)
- Interoperability with Cluster API (CAPI) providers

## What is the GitOps Toolkit?

Flux is constructed with the [GitOps Toolkit components](components/), which is a set of

- specialized tools and Flux Controllers
- composable APIs
- reusable Go packages for GitOps under the [fluxcd GitHub organisation](https://github.com/fluxcd)

for building Continuous Delivery on top of Kubernetes.

The [GitOps Toolkit](components/) can be used individually by **platform
engineers** who want to make their own continuous delivery system, and
have requirements not covered by Flux.

![GitOps Toolkit overview](/img/diagrams/gitops-toolkit.png)

## Community

Need help or want to contribute? Please see the links below. The Flux project is always looking for
new contributors and there are a multitude of ways to get involved.

- Getting Started?
    - Look at our [Get Started guide](get-started/) and give us feedback
- Need help?
    - First: Ask questions on our [GH Discussions page](https://github.com/fluxcd/flux2/discussions)
    - Second: Talk to us in the #flux channel on [CNCF Slack](https://slack.cncf.io/)
    - Please follow our [Support Guidelines](/support/)
      (in short: be nice, be respectful of volunteers' time, understand that maintainers and
      contributors cannot respond to all DMs, and keep discussions in the public #flux channel as much as possible).
- Have feature proposals or want to contribute?
    - Propose features on our [GH Discussions page](https://github.com/fluxcd/flux2/discussions)
    - Join our upcoming dev meetings ([meeting access and agenda](https://docs.google.com/document/d/1l_M0om0qUEN_NNiGgpqJ2tvsF2iioHkaARDeh6b70B0/view))
    - [Join the flux-dev mailing list](https://lists.cncf.io/g/cncf-flux-dev).
    - Check out [how to contribute](/contributing) to the project

### Events

Check out our **[events calendar](/#calendar)**,
both with upcoming talks you can attend or past events videos you can watch.

We look forward to seeing you with us!
