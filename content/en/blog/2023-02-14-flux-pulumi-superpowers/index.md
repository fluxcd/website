---
author: Michael Bridgen
date: 2023-02-14 8:30:00+00:00
title: How Flux and Pulumi give each other superpowers
description: The Pulumi Kubernetes operator extends Flux to all your infrastructure, and Flux makes the Pulumi operator secure and super easy to work with.
url: /blog/2023/02/flux-pulumi-superpowers/
tags: [ecosystem]
---

[Pulumi](https://pulumi.com/) is an "Infrastructure as Code" tool that lets you specify your
infrastructure as programs written in JavaScript, Python, Java, Go, .NET languages, or YAML. The
[Pulumi Kubernetes operator](https://github.com/pulumi/pulumi-kubernetes-operator) drives Pulumi
from Kubernetes, so you can maintain your infrastructure by pushing commits to git and letting
automation take it from there.

<img class="img-fluid float-left m-3" alt="Pulumi mascot with sparkling cape" src="flying-sparkles-purple-cape-featured.png" />

Recently, we added support to the operator for [using Flux
sources](https://www.pulumi.com/docs/guides/continuous-delivery/pulumi-kubernetes-operator/#using-a-flux-source). This
is a great addition to the operator, but it's not the only way Flux and Pulumi can work together.

Below I'm going to talk about how Flux and Pulumi can be combined, and the superpowers each grants
to the other.

<h2 style="clear:left;">Adding OCI support and supply chain security to Pulumi</h2>

The support for Flux sources in the Pulumi operator gives you more ways to make your Pulumi programs
available to the operator. Notably, you can now package your program as an OCI image and push it to
an image registry, before using it with the operator. This might be appealing if you have deployment
pipelines to generate Kubernetes YAML (e.g., from [Cue](https://cuelang.org/)) or other data, before
using it in a program. It's also convenient when you're on a platform like AWS, GCP or Azure,
because these have OCI registries with useful operational features like caching, security scanning,
and so on.

But I think an even better reason for using Flux is that it can verify your sources. If you use a
Flux source in a Pulumi stack, you can better secure your supply chain. When you're using an OCI
repository source for example, [Flux will check Cosign
signatures](/flux/components/source/ocirepositories/#verification) on each image
for you, and refuse to update a source that does not have a valid signature.

<!-- ASCII art here? Or a YAML example. -->

A more subtle security benefit of Flux sources is context-based authorization. For example, in AWS
the Flux controller can take advantage of [workload
identity](/flux/cheatsheets/oci-artifacts/#contextual-authorization) to gain access
to an ECR container registry containing your sources, so that you don't have to explicitly manage
credentials.

## Using Pulumi to extend the reach of Flux

With Pulumi you are not restricted to Kubernetes resources -- you can create any resource defined in
a provider, e.g., within AWS, GCP, and Azure, among [many such platforms and
services](https://pulumi.com/registry/). You can [write a Pulumi program in
YAML](https://www.pulumi.com/docs/intro/languages/yaml/), and you can [declare a YAML program as a
Kubernetes custom
resource](https://www.pulumi.com/docs/guides/continuous-delivery/pulumi-kubernetes-operator/#using-a-program-object),
making the whole chain amenable to [Kubernetes Resource Model
(KRM)](https://github.com/kubernetes/design-proposals-archive/blob/main/architecture/resource-management.md)-oriented
tooling, including Flux.

For example, here's Kubernetes YAMLs for creating an AWS EC2 instance, and a security group, with
Pulumi:

```yaml
---
# This is a program for creating the EC2 instance and security group
apiVersion: pulumi.com/v1
kind: Program
metadata:
  name: ec2-instance
program:
    resources:
      group:
        type: aws:ec2:SecurityGroup
        properties:
          description: Enable HTTP access
          ingress:
            - protocol: tcp
              fromPort: 80
              toPort: 80
              cidrBlocks: ["0.0.0.0/0"]
      server:
        type: aws:ec2:Instance
        properties:
          ami: ami-6869aa05
          instanceType: t2.micro
          vpcSecurityGroupIds: ${group.name}
    outputs:
      publicIp: ${server.publicIp}
      publicDns: ${server.publicDns}
---
# This stack tells the operator how to run the program
apiVersion: pulumi.com/v1
kind: Stack
metadata:
  name: dev-ec2-instance
spec:
  stack: squaremo/ec2-instance/dev
  programRef:
    name: ec2-instance
  destroyOnFinalize: true
  config:
    aws:region: us-east-1
```

You can commit these in files in git, and have them synced by Flux. Then the Pulumi operator will
take over, create the infrastructure as it's declared, and mark the Stack object as ready. As far as
Flux knows, these are just regular Kubernetes resources -- but now you can bring your whole
infrastructure under control!

## Using Flux to simplify Kubernetes for Pulumi

Pulumi makes a huge variety of infrastructure accessible by [_just writing
programs_](https://www.pulumi.com/what-is/what-is-infrastructure-as-code/). In the specific context
of Kubernetes, many folks will find KRM-oriented tooling and YAML files easier. Flux's Kustomize and
Helm controllers work alongside its source controller, but happily they also work in harmony with
the Pulumi operator, and you can mix and match to suit yourself.

For example, you might find it useful to write all your Pulumi Program and Stack YAMLs as files in a
directory for Flux to sync, rather than trying to create them in Pulumi code (or -- horror --
applying them by hand).

## Getting started with Flux and the Pulumi operator

If you are already invested in Pulumi, it would make sense to bootstrap **Flux, using Pulumi**. You
can use the [Flux provider for Pulumi](https://www.pulumi.com/registry/packages/flux/) from your
Pulumi program, and gain verified sources and effortless YAML syncing.

And, vice versa -- if you are starting with Flux and want to expand its reach with Pulumi, you can
bootstrap the **Pulumi operator, using Flux**, by syncing the deployment manifests in the operator's
GitHub repo:

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: pulumi-operator
  namespace: flux-system
spec:
  interval: 5m0s
  ref:
    semver: "1.11.x"
  url: https://github.com/pulumi/pulumi-kubernetes-operator
---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: deploy-pulumi-operator
  namespace: flux-system
spec:
  interval: 5m0s
  path: ./deploy/yaml
  prune: true
  sourceRef:
    kind: GitRepository
    name: pulumi-operator
```

Visit [Pulumi's "Get Started" portal](https://www.pulumi.com/docs/get-started/) to learn more about
what you can accomplish with Pulumi.
