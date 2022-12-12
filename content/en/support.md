# Looking for help

The success and happiness of our users is essential to the Flux community. We are working very hard to make all of our tools obvious and self-explanatory, to make them composable with other tools and make our documentation easy to follow.

You might still run into issues. This page is meant to be a guide to help you figure out how and where to look for help.

## Documentation for individual Flux projects

Implementing GitOps or any \*Ops is a process which involves many layers and technologies. We therefore place a lot of importance on encoding shared knowledge and best practices in our documentation.

To be mindful of everybody's time, please make sure you checked and followed the documentation before filing issues.
Here are some good entry points to get started with our documentation including Getting Started Guides:

Project   | Links
--------- | ----------------------------------------
Flux | [Entry point](https://fluxcd.io/flux/), [Core Concepts](https://fluxcd.io/flux/concepts/), [Getting Started Guide](https://fluxcd.io/flux/get-started/), [FAQ](https://fluxcd.io/flux/faq/)
Flagger | [Entry point](https://docs.flagger.app/), [Getting Started Guide](https://docs.flagger.app/install/flagger-install-on-kubernetes), [FAQ](https://docs.flagger.app/faq)
Helm Operator (legacy - v1) | [Entry point](https://fluxcd.io/legacy/helm-operator/), [Getting Started Guide](https://fluxcd.io/legacy/helm-operator/get-started/quickstart/), [FAQ](https://fluxcd.io/legacy/helm-operator/faq/), [Troubleshooting](https://fluxcd.io/legacy/helm-operator/troubleshooting/)
Flux (legacy - v1) | [Entry point](https://fluxcd.io/legacy/flux/), [Getting Started Guide](https://fluxcd.io/legacy/flux/get-started/), [FAQ](https://fluxcd.io/legacy/flux/faq/), [Troubleshooting](https://fluxcd.io/legacy/flux/troubleshooting/)

## I am stuck

We as a community are both very thankful and proud to have attracted many incredibly kind and clever individuals who are all interested in the same thing and who are helping each other out.

As we have been overwhelmed with general questions, troubleshooting requests, feature requests, etc. in the past months, we would like to ask you to:

- Read the [documentation](https://fluxcd.io/flux/get-started/) carefully, check the individual troubleshooting sections for advice on how to interpret logs, use relevant tools, etc.
- For Flux 2 questions, see if there are answers on the [GH Discussions page](https://github.com/fluxcd/flux2/discussions)
- Please don't direct-message project maintainers or relevant others with specific support questions. The few Flux maintainers cannot answer all questions. If you post on [GH Discussions page](https://github.com/fluxcd/flux2/discussions) for Flux 2 questions or message in the appropriate Slack channel, you'll have a better chance at getting an answer from a community member willing to help.
- Make sure you don't share private information.
- Help out if you can, e.g. if somebody just answered your question and it was missing in the FAQ or other docs, please consider adding it, it might help somebody in the future.

🕰 **Another note:** Understanding somebody's infrastructure and settings takes time. Please provide relevant information up-front. If a Flux contributor spends an hour in a question-and-answer ping-pong with you, that's one hour they are going to spend less on other parts of Flux.

If all of this sounds like we're putting you off, that's not how this is meant. We want to be there for each other in this community, but we want to be mindful of each other's time.

*Let's be excellent to each other.*

### Consider this

Support for Flux users and community is mostly provided by volunteers, who are all on equal footing as peers in the Flux community. This implies that (free) support is provided on a best-effort basis, with no SLA or quality-of-service guarantee.

[Best-effort delivery](https://en.wikipedia.org/wiki/Best-effort_delivery) is explained on Wikipedia in terms of a "**best-effort network**, [on which] all users obtain best-effort service. Under best-effort, network performance characteristics such as network delay and packet loss depend on the current network traffic load."

Similar to a best-effort network, the capacity for our community as a whole to provide quality support for community members, and a welcoming environment for all contributors, depends heavily on the grace and good behavior of individual community members.

You can help ensure a higher quality of best-effort support by formulating inquiries thoughtfully and making a considerate effort to place them in the most appropriate venue.

Here are some guidelines about which venue makes the most sense:

| Form of inquiry                                             | Venue                 |
| ------------------------------------------------------------| --------------------- |
| Something is not working as intended / I found a bug        | [Issue](https://github.com/fluxcd/flux2/issues) |
| A feature is too limited for my `<use-case>`                | Discussion ([General](https://github.com/fluxcd/flux2/discussions/categories/general)) |
| I want Flux to be able to do `<x>`                          | Discussion ([Proposal](https://github.com/fluxcd/flux2/discussions/categories/proposals)) |
| Something is not working, (but I am not sure if I am doing it right) | Discussion ([Q&A](https://github.com/fluxcd/flux2/discussions/categories/q-a)) |
| Quick question                                              | [#flux][] on [CNCF Slack][] |

Bearing in mind that Issues and [Discussions](https://github.com/fluxcd/flux2/discussions) are more permanent and searchable than Slack conversations, we can avoid unduly expending finite community resources by searching before asking. If you are not exactly sure how to ask your question or otherwise daunted by the idea of permanence, visitors are always welcome in [#flux][] on the [CNCF Slack][].

If your needs are more urgent, more broadly demanding, or more persistent than the best-effort community support resources can provide, you may also consider [a paid support option](#my-employer-needs-additional-help).

## Community Help Resources

For questions around Flux v2, please visit our [Flux2 Discussions](https://github.com/fluxcd/flux2/discussions) section on Github.

## I found a bug

If you made sure you encountered an actual issue, we definitely want to hear about it.

Here's how to proceed:

Check [Github](https://github.com/fluxcd) to locate the correct project

Many Flux projects and project facets are maintained by different code owners under separate repositories, and filing your issue under the correct repository can better ensure that relevant maintainers are notified.

### Flux core projects (in active development

- [flux2](https://github.com/fluxcd/flux2) - the main Flux project repository (current version)
- [source-controller](https://github.com/fluxcd/source-controller) - handles artifacts acquisition from external sources such as Git, Helm repositories and S3 buckets.
- [kustomize-controller](https://github.com/fluxcd/kustomize-controller) - runs continuous delivery pipelines defined with Kubernetes manifests and assembled with Kustomize.
- [helm-controller](https://github.com/fluxcd/helm-controller) - declaratively manages Helm chart releases (the successor to Helm Operator from Flux v1).
- [notification-controller](https://github.com/fluxcd/notification-controller) - event forwarder and notification dispatcher.
- [image-reflector-controller](https://github.com/fluxcd/image-reflector-controller) - scans container image repositories and reflects the metadata in Kubernetes resources. Pairs with the image update automation controller to drive automated config updates.
- [image-automation-controller](https://github.com/fluxcd/image-automation-controller) - automates updates to Git when new container images are available.
- [flagger](https://github.com/fluxcd/flagger) - the progressive delivery tool, reduces the risk of introducing a new software version in production by gradually shifting traffic to the new version while measuring metrics and running conformance tests.

### Project documentation

- [website](https://github.com/fluxcd/website) - the project's landing page at <https://fluxcd.io> and docs
- [community](https://github.com/fluxcd/community) - this page!

### Stable Flux repositories (in maintenance mode)

- [flux (v1)](https://github.com/fluxcd/flux)
- [helm-operator](https://github.com/fluxcd/helm-operator)

Now check the issue template and include any requested information

For example, the [flux2 repo issue template](https://github.com/fluxcd/flux2/issues/new) requests the output of `flux check` and `flux --version`. If you are using an older version of the project, review the release notes from later versions to be sure your issue has not already been resolved. Also check for other issue reports, as if your issue was already reported, this can help avoid duplicate reports.

Any relevant information depending on your specific issue should also be included, like your Kubernetes cluster version and/or cloud provider; or for example if you are reporting an issue related to image automation, tell what type of image hosting is used, or what container registry provider hosts your cluster's images.

## My employer needs additional help

Luckily some of the companies who employ Flux developers offer paid support, so if you need an architecture review, training or help implementing certain features, you might want to reach out to the following companies:

- DoneOps: <https://www.doneops.com/#contactus>
- Weaveworks: <https://www.weave.works/contact/>
- Xenit: <https://xenit.se/contact/>

---

*Flux is a CNCF project, so this "paid support" section is not tied to any single company in particular. If you want to add your company to the list, please file a PR and tag the [Core Maintainers](https://github.com/fluxcd/community/blob/main/GOVERNANCE.md#core-maintainers).*

*If your company has a track record of Flux engineering and/or support we will get you added.*

[#flux]: https://cloud-native.slack.com/archives/CLAJ40HV3
[CNCF Slack]: https://slack.cncf.io/
