---
title: Flux Integrations
description: "Projects that extend and integrate with Flux."
type: page
---

## Flux Extensions and Integrations

These tools and integrations with Flux are available today.

To join this list, please

- if you are an organisation: add yourself to [the adopters page](/adopters)
- file a PR on [this file](https://github.com/fluxcd/website/blob/main/content/en/integrations.md)
- (optional) find us on Slack and maybe let's do joint blog posts, etc?

We are happy and proud to have you all as part of our community! :sparkling_heart:

## Flux Extensions

These projects extend Flux with new capabilities.

| Source                                                                        | Description |
| ----------------------------------------------------------------------------- | ----------- |
| [pelotech/jsonnet-controller](https://github.com/pelotech/jsonnet-controller) | A Flux controller for managing manifests declared in jsonnet. |

## Integrations

These projects make use of Flux to offer GitOps capabilities to their users.

| Source                                                                      | Description |
| --------------------------------------------------------------------------- | ----------- |
| [aws/eks-anywhere](https://github.com/aws/eks-anywhere)                     | Amazon EKS Anywhere is an open-source deployment option for Amazon EKS that allows customers to create and operate Kubernetes clusters on-premises. |
| [fidelity/kraan](https://github.com/fidelity/kraan)                         | Kraan is a Kubernetes Controller that manages the deployment of HelmReleases to a cluster. |
| [microsoft/bedrock](https://github.com/microsoft/bedrock)                   | Automation for Production Kubernetes Clusters with a GitOps Workflow. |
| [microsoft/fabrikate](https://github.com/microsoft/fabrikate)               | Making GitOps with Kubernetes easier one component at a time. |
| [microsoft/gitops-connector](https://github.com/microsoft/gitops-connector) | A GitOps Connector integrates a GitOps operator with CI/CD orchestrator. |
| [telekom/das-schiff](https://github.com/telekom/das-schiff)                 | This is home of Das Schiff - Deutsche Telekom Technik's engine for Kubernetes Cluster as a Service (CaaS) in on-premise environment on top of bare-metal servers and VMs. |
| [weaveworks/eksctl](https://github.com/weaveworks/eksctl)                   | The official CLI for creating and managing Kubernetes clusters on Amazon EKS. |
| [weaveworks/weave-gitops](https://github.com/weaveworks/weave-gitops)       | Weave GitOps enables an effective GitOps workflow for continuous delivery of applications into Kubernetes clusters. |

## Ancillary Tools

The functionality of Flux can be easily extended with ancillary utility tools. Here is a list of tools we like. If yours is missing, feel free to send a PR to add it.

| Source                                                                | Description | Documentation |
| --------------------------------------------------------------------- | ----------- | ------------- |
| [jgz/s3-auth-proxy](https://github.com/jgz/s3-auth-proxy)             | Creates a simple basic-auth proxy for an s3 bucket. | [README](https://github.com/jgz/s3-auth-proxy#readme) |
| [tarioch/flux-check-hook](https://github.com/tarioch/flux-check-hook) | A [pre-commit](http://pre-commit.com) that validates values of HelmRelease using helm lint | [README](https://github.com/tarioch/flux-check-hook#readme) |
