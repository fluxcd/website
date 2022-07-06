---
title: Flux Ecosystem
description: "Projects that extend and integrate with Flux."
type: page
---

## Flux Ecosystem

These tools and integrations with Flux are available today.

{{% alert color="info" title="Join us" %}}
To join this list, please open a PR on [this file](https://github.com/fluxcd/website/blob/main/content/en/ecosystem.md).
If you represent an organisation, please add yourself to [the adopters page](/adopters).
We are happy and proud to have you all as part of our community! :sparkling_heart:
{{% /alert %}}

## Products and Services built on top of Flux

<div class="ecosystem">
{{< cardpane >}}
{{% card header="AWS [EKS Anywhere](https://anywhere.eks.amazonaws.com/docs/tasks/cluster/cluster-flux/)" %}}
![AWS](/img/logos/logo-generic.png)
{{% /card %}}
{{% card header="[Azure Arc](https://docs.microsoft.com/azure/azure-arc/)" %}}
![Azure](/img/logos/logo-generic.png)
{{% /card %}}
{{% card header="[D2iQ Kommander](https://d2iq.com/products/kommander)" %}}
![D2iQ](/img/logos/d2iq.png)
{{% /card %}}
{{% card header="[Giant Swarm Kubernetes Platform](https://docs.giantswarm.io/advanced/gitops/)" %}}
![Giant Swarm](/img/logos/giantswarm.svg)
{{% /card %}}
{{% card header="[Gimlet](https://gimlet.io/concepts/components/)" %}}
![Gimlet](/img/logos/logo-generic.png)
{{% /card %}}
{{% card header="[VMware Tanzu](https://tanzu.vmware.com/tanzu)" %}}
![VMware](/img/logos/logo-generic.png)
{{% /card %}}
{{% card header="[Weave GitOps Enterprise](https://www.weave.works/product/gitops-enterprise/)" %}}
![Weaveworks](/img/logos/weaveworks.png)
{{% /card %}}
{{< /cardpane >}}
</div>


## Flux UIs

These open source projects offer a dedicated UI for Flux.

<div class="ecosystem">
{{< cardpane >}}
{{% card header="[weaveworks/weave-gitops](https://github.com/weaveworks/weave-gitops)"
         footer="![Weaveworks](/img/logos/weaveworks.png)" %}}
Weaveworks offers a free and open source GUI for Flux under the [weave-gitops](https://docs.gitops.weave.works/docs/intro) project. You can install the Weave GitOps UI using a Flux `HelmRelease`, please see the [get started documentation](https://docs.gitops.weave.works/docs/getting-started/) for more details.
{{% /card %}}
{{< /cardpane >}}
</div>


## Flux Extensions

These open source projects extend Flux with new capabilities.

<div class="ecosystem">
{{< cardpane >}}
{{% card header="[weaveworks/tf-controller](https://github.com/weaveworks/tf-controller)"
         footer="![Weaveworks](/img/logos/weaveworks.png)" %}}
A Flux controller for managing Terraform resources.
{{% /card %}}
{{% card header="[pelotech/jsonnet-controller](https://github.com/pelotech/jsonnet-controller)"
         footer="![Pelotech](/img/logos/logo-generic.png)" %}}
A Flux controller for managing Terraform resources.
{{% /card %}}
{{% card header="[kluctl/flux-kluctl-controller](https://github.com/kluctl/flux-kluctl-controller)"
         footer="![Kluctl](/img/logos/logo-generic.png)" %}}
A Flux controller for managing [Kluctl](https://kluctl.io) deployments.
{{% /card %}}
{{< /cardpane >}}
</div>

## Integrations

These projects make use of Flux to offer GitOps capabilities to their users.

<div class="ecosystem">
{{< cardpane >}}
{{% card header="[23technologies/gardener-extension-shoot-flux](https://github.com/23technologies/gardener-extension-shoot-flux)"
         footer="![Weaveworks](/img/logos/logo-generic.png)" %}}
Gardener implements the automated management and operation of Kubernetes clusters as a service. With this extension fresh clusters will be reconciled to the state defined in the Git repository by the Flux controller.
{{% /card %}}
{{% card header="[aws/eks-anywhere](https://github.com/aws/eks-anywhere)"
         footer="![AWS](/img/logos/logo-generic.png)" %}}
Amazon EKS Anywhere is an open-source deployment option for Amazon EKS that allows customers to create and operate Kubernetes clusters on-premises.
{{% /card %}}
{{% card header="[fidelity/kraan](https://github.com/fidelity/kraan)"
         footer="![Fidelity](/img/logos/logo-generic.png)" %}}
Kraan is a Kubernetes Controller that manages the deployment of HelmReleases to a cluster.
{{% /card %}}

{{% card header="[flux-subsystem-argo/flamingo](https://github.com/flux-subsystem-argo/flamingo)"
         footer="![flux-subsystem-argo](/img/logos/logo-generic.png)" %}}
🚧 Technology preview: FSA (aka Flamingo) is Flux Subsystem for Argo. FSA's container image can be used as a drop-in replacement for the equivalent ArgoCD version to visualize, and manage Flux workloads, along side ArgoCD.
{{% /card %}}
{{% card header="[microsoft/bedrock](https://github.com/microsoft/bedrock)"
         footer="![Microsoft](/img/logos/logo-generic.png)" %}}
Automation for Production Kubernetes Clusters with a GitOps Workflow.
{{% /card %}}
{{% card header="[microsoft/fabrikate](https://github.com/microsoft/fabrikate)"
         footer="![Microsoft](/img/logos/logo-generic.png)" %}}
Making GitOps with Kubernetes easier one component at a time.{{% /card %}}
{{% card header="[microsoft/gitops-connector](https://github.com/microsoft/gitops-connector)"
         footer="![Microsoft](/img/logos/logo-generic.png)" %}}
A GitOps Connector integrates a GitOps operator with CI/CD orchestrator.
{{% /card %}}
{{% card header="[telekom/das-schiff](https://github.com/telekom/das-schiff)"
         footer="![Telekom](/img/logos/logo-generic.png)" %}}
This is home of Das Schiff - Deutsche Telekom Technik's engine for Kubernetes Cluster as a Service (CaaS) in on-premise environment on top of bare-metal servers and VMs.
{{% /card %}}
{{% card header="[weaveworks/eksctl](https://github.com/weaveworks/eksctl)"
         footer="![Weaveworks](/img/logos/weaveworks.png)" %}}
The official CLI for creating and managing Kubernetes clusters on Amazon EKS.
{{% /card %}}
{{% card header="[weaveworks/vscode-gitops-tools](https://github.com/weaveworks/vscode-gitops-tools)"
         footer="![Weaveworks](/img/logos/weaveworks.png)" %}}
🚧 Technology preview: GitOps Tools for Visual Studio Code: provides an intuitive way to manage, troubleshoot and operate your Kubernetes environment following the GitOps operating model.
{{% /card %}}
{{% card header="[weaveworks/weave-gitops](https://github.com/weaveworks/weave-gitops)"
         footer="![Weaveworks](/img/logos/weaveworks.png)" %}}
Weave GitOps enables an effective GitOps workflow for continuous delivery of applications into Kubernetes clusters.
{{% /card %}}
{{% card header="[kubevela/kubevela](https://github.com/kubevela/kubevela)"
         footer="![KubeVela](/img/logos/logo-generic.png)" %}}
KubeVela integrates fluxcd well for [Helm Chart delivery](https://kubevela.io/docs/tutorials/helm) and [GitOps](https://kubevela.io/docs/case-studies/gitops), and provide [multi-cluster capabilities](https://kubevela.io/docs/tutorials/helm-multi-cluster).
{{% /card %}}
{{< /cardpane >}}
</div>

## Ancillary Tools

The functionality of Flux can be easily extended with ancillary utility tools. Here is a list of tools we like. If yours is missing, feel free to send a PR to add it.

<div class="ecosystem">
{{< cardpane >}}
{{% card header="[renovatebot/renovate](https://github.com/renovatebot/renovate)"
         footer="![Renovate](/img/logos/logo-generic.png)" %}}
Universal dependency update tool that fits into your workflows.<br/><br/>[Documentation](https://docs.renovatebot.com/modules/manager/flux/)
{{% /card %}}
{{% card header="[jgz/s3-auth-proxy](https://github.com/jgz/s3-auth-proxy)"
         footer="![Pelotech](/img/logos/logo-generic.png)" %}}
Creates a simple basic-auth proxy for an s3 bucket.<br/><br/>[Documentation](https://github.com/jgz/s3-auth-proxy#readme)
{{% /card %}}
{{% card header="[tarioch/flux-check-hook](https://github.com/tarioch/flux-check-hook)"
         footer="![Kluctl](/img/logos/logo-generic.png)" %}}
A [pre-commit](https://pre-commit.com) that validates values of HelmRelease using helm lint.<br/><br/>[Documentation](https://github.com/tarioch/flux-check-hook#readme)
{{% /card %}}
{{< /cardpane >}}
</div>
