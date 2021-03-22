---
title: Flux - the GitOps family of projects
description: > 
  Flux is a set of continuous and progressive delivery solutions for Kubernetes, and they are open and extensible. 
  
  Flux v2 will be GA within the next few months! 
  
  This means that Flux v1 will be deprecated before the end of 2021, so now is a good time to start using v2.

---

{{< blocks/celebration
  emoji="🎉"
  url="/blog/2021/03/flux-is-a-cncf-incubation-project/" >}}
Flux is now a CNCF Incubation project!
{{< /blocks/celebration >}}

{{< blocks/hero title="Flux - the GitOps family of projects" color="primary" height="full" >}}

Aliqua adipisicing enim duis irure incididunt culpa reprehenderit nisi. In esse cillum proident anim in ullamco. Laborum in irure quis tempor incididunt amet magna nisi fugiat labore.

Labore magna dolore proident reprehenderit esse irure quis dolor occaecat laborum non dolore. Voluptate est aute duis sunt nisi amet aute elit amet nulla nostrud. Amet laborum culpa fugiat dolor incididunt aliqua sint tempor. In amet nulla amet officia duis pariatur.

{{< /blocks/hero >}}


{{% blocks/section color="white" %}}

{{% blocks/feature icon="fab fa-git-square fa-3x" title="Declarative" height="auto" color="blue" %}}

Describe the entire desired state of your system in [Git](https://git-scm.com). This includes apps, configuration,
dashboards, monitoring, and everything else.

{{% /blocks/feature %}}

{{% blocks/feature icon="fas fa-robot fa-3x" title="Automated" height="auto" color="blue" %}}

  Use [YAML](https://yaml.org) to enforce conformance to the declared system. You don't need to run
  [`kubectl`](https://kubectl.docs.kubernetes.io/) because all changes are synced automatically.

{{% /blocks/feature %}}

{{% blocks/feature icon="fas fa-code fa-3x" title="Auditable" height="auto" color="blue" %}}

  Everything is controlled through pull requests. Your Git history provides a sequence of transactions, allowing you to
  recover state from any snapshot.

{{% /blocks/feature %}}

{{% blocks/feature icon="fas fa-drafting-compass fa-3x" title="Designed for Kubernetes" height="auto" color="blue" %}}

  Declaratively configurable using Custom Resources, state reports in the
  [object's status](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/#object-spec-and-status)
  and via [Kubernetes Events](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application-introspection/),
  and integrations with Kubernetes RBAC

{{% /blocks/feature %}}

{{% blocks/feature icon="fas fa-box-open fa-3x" title="Out-of-the-box integrations" height="auto" color="blue" %}}

Support for e.g. [Kustomize](https://kustomize.io), [Helm](https://helm.sh); GitHub, GitLab, Harbor and custom
webhooks; notifications to most team communication platforms; and many more.

{{% /blocks/feature %}}

{{% blocks/feature icon="fas fa-cube fa-3x" title="Extensible" height="auto" color="blue" %}}

Easily create a continous delivery solution with only the components you need, or use the [GitOps Toolkit](#gitops-toolkit)
to extend Flux.

{{% /blocks/feature %}}

{{< /blocks/section >}}

<!-- RESOURCES HERE -->

{{% blocks/section %}}

If you are new to Flux, you might want to check out some of the following resources to get started.

{{% blocks/resource
  youtube="nGLpUCPX8JE"
  title="The Evolution of Flux v2 with Stefan Prodan" %}}
Stefan introduces Flux v2, explains why it was reshaped into a composable continuous delivery solution that goes beyond Git sync to accommodate multi-tenancy, infrastructure dependencies and cluster-api fleet management.
{{% /blocks/resource %}}

{{% blocks/resource
  youtube="0v5bjysXTL8"
  title="The Power of GitOps with Flux v2 & GitOps Toolkit with Leigh Capili" %}}
Leigh demos bootstrapping with GitOps Toolkit, app deployment, and monitoring with Prometheus.
{{% /blocks/resource %}}

{{% blocks/resource
  youtube="JcKUawSQfQ0"
  title="Flux v2 for Helm Users with Scott Rigby" %}}
Scott covers what to keep in mind as Helm 2 support ends, the benefits of Helm Controller, and how to migrate from Helm Operator to Helm Controller.
{{% /blocks/resource %}}

{{% blocks/resource
  youtube="7W27tAv7Tvs"
  title="Managing Remote Clusters with Flux v2 (CAPI demo) with Leigh Capili" %}}
Leigh covers cluster API integration, dependency management & ordering, security model updates, and delegation & multi-tenancy via users.
{{% /blocks/resource %}}

{{% blocks/resource
  youtube="R6OeIgb7lUI"
  title="Flux v2 overview, demo, & review with Viktor Farcic" %}}
Stefan introduces Flux v2, explains why it was reshaped into a composable continuous delivery solution that goes beyond Git sync to accommodate multi-tenancy, infrastructure dependencies and cluster-api fleet management.
{{% /blocks/resource %}}

{{% blocks/resource
  url="https://www.youtube.com/playlist?list=PLG9qZAczREKmCq6on_LG8D0uiHMx1h3yn"
  title="Flux v2 Deep Dive series with Geert Baeke" %}}
In this 5 video series, Geert Baeke takes a deep dive of Flux v2 and the use of GitOps principles with an Intro to Flux v2, Intro to Kustomize, Deploying Manifests, Monitoring & Alerting, and Helm Basics.
{{% /blocks/resource %}}

{{< /blocks/section >}}

{{< blocks/cncf >}}
