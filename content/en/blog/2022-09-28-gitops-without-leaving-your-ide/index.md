---
author: "juozasg & dholbach"
date: 2022-09-28 11:00:00+00:00
title: GitOps Without Leaving your IDE
description: "Are you a fan of VS Code and would love to use all standard GitOps feature without ever changing windows. This one is for you. Access all Flux's goodness through the UI of your IDE!"
url: /blog/2022/09/gitops-without-leaving-your-ide/
tags: [ecosystem]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

Welcome to the second [blog post in our Flux Ecosystem category](/tags/ecosystem/)!
This time we are talking about one of the [Flux UIs](/ecosystem/#flux-uis): it's
the [VS Code GitOps Extension](https://github.com/weaveworks/vscode-gitops-tools).

If you already use VS Code, this extension will be straight up your alley: it
provides an intuitive way to manage, troubleshoot and operate your Kubernetes
environment following the GitOps operating model, accelerating your development
lifecycle and simplifying your continuous delivery pipelines. Of course it uses
Flux under the hood.

## Getting Started

Installing it: It's [in the Visual Studio Code
Marketplace](https://marketplace.visualstudio.com/items?itemName=Weaveworks.vscode-gitops-tools), so if you search for it in VS Code, it's just a click of
the Install button away.

{{< imgproc vscode-gitops-features Resize 800x >}}
{{< /imgproc >}}

Additionally, you will need to

- [Install Kubectl](https://kubectl.docs.kubernetes.io/installation/kubectl/)
- [Install Flux CLI](/docs/installation/#install-the-flux-cli)
- [Install git](https://git-scm.com/downloads)

Optionally, if available, the extension will make use of the `az` tool
(for Azure clusters) and `docker` as well.

With that out of the way, let's get going and take the extension for a
spin.

## Drive everything from your IDE

Once you launch VS Code, you should see available clusters listed in the
Clusters section of the GitOps extension. Now you can easily interact
with the resources in each of the clusters. This makes it very
straightforward to make changes in your manifests, commit and observe
changes in the clusters without leaving your IDE.

{{< imgproc vscode-gitops-commands-featured Resize 800x >}}
{{< /imgproc >}}

{{< imgproc vscode-gitops-tools Resize 800x >}}
{{< /imgproc >}}

The extension was designed so that you always have access to the
immediate tasks and events. Turning a manifest into a `Kustomization` or
`Source`? Right-click on the YAML file. View repositories, clusters,
sources, kustomizations, etc. - you see them at the first glance. View
GitOps Output panel with CLI command traces for diagnostics, cluster and
components versions, Flux controller logs, everything you might need to
debug. Enable/disable GitOps cluster operations with just a click.
Reconcile Sources and Workloads demand, and much more - links to
most-needed docs included.

## Constantly evolving

The extension is rapidly growing new features. In 0.21.0, the team added
OCI support which is supported natively in Flux. If you would like to
see a video demo of this, check out this talk done by Annie Talvasto and
Kingdon Barrett in the CNCF Webinar series.

{{% youtube id=Hz8IP_eprec %}}

In 0.22.0 basic support for Azure AKS/Arc was added. Future releases
will add a new beginner-friendly UI workflow for creating complete Flux
configurations using both generic Flux Source (Git, OCI, Bucket,
`HelmRepository`) and Workload (`Kustomization`, `HelmRelease`) resources
as well as Azure `FluxConfig` resources.

{{< imgproc azure-support Resize 800x >}}
{{< /imgproc >}}

The team has begun work to transition the extension implementation from
shell out commands to Javascript APIs for Kubernetes and Azure. Once
that is complete, extension responsiveness and performance will improve
dramatically.

## Join the community

The team behind the extension loves feedback. If you like what you see,
please star [the extension on
GitHub](https://github.com/weaveworks/vscode-gitops-tools)
or leave an issue if something is missing, or send a PR if you can.

All feedback is very welcome!
