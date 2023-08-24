---
author: 'dholbach & pjbgf'
date: 2022-05-10 8:30:00+00:00
title: May 2022 Security Announcement
description: 'The Flux Team has found three security vulnerabilities in Flux, Today we will go through them and talk about what this may mean to you. We strongly advise you to upgrade your clusters as soon as you can. 🔒' 
url: /blog/2022/05/may-2022-security-announcement/
tags: [security]
---

## tl;dr

The Flux Team has found three security vulnerabilities in
Flux, and we strongly advise you to upgrade your clusters as soon as you
can.

| CVE | Advisory | Severity | Affected versions
| --- | --- | --- | --- | ---
| CVE-2022-24817 | [Improper kubeconfig validation allows arbitrary code execution](https://github.com/fluxcd/flux2/security/advisories/GHSA-vvmq-fwmg-2gjc) | Critical | `< 0.29.0 >= v0.1.0`
| CVE-2022-24877 | [Improper path handling in Kustomization files allows path traversal](https://github.com/fluxcd/flux2/security/advisories/GHSA-j77r-2fxf-5jrw) | Critical | `< v0.29.0`
| CVE-2022-24878 | [Improper path handling in Kustomization files allows for denial of service](https://github.com/fluxcd/flux2/security/advisories/GHSA-7pwf-jg34-hxwp) | High | `< v0.29.0 >= v0.19.0`

Breaking changes to be aware of in the upgrade process:
[0.29](/blog/2022/05/april-2022-update/#latest-flux-release-series-is-029),
[0.28](https://github.com/fluxcd/flux2/discussions/2567),
[0.27](/blog/2022/03/february-update/#latest-flux-is-027),
[0.26](/blog/2022/01/january-update/#flux-v026-more-secure-by-default),
[0.24 - 0.21](/blog/2021/11/december-update/#a-flurry-of-flux-releases).

If you cannot immediately update or are hard pressed for time and need a
work-around for now, please see the CVE advisories linked above for more
information.

## Some Background

Last week the Flux Security Team disclosed three new vulnerabilities
which affect v0.28 and older versions, and have a greater impact in
multi-tenancy deployments.

The reason why the impact is greater in multi-tenancy deployments is due
to the way that Flux/GitOps works. Flux tends to operate like a cluster
admin, having permissions to apply any changes to a cluster, regardless
of their scope - at namespace or cluster levels. Users having access to
a source repository, or simply having access to create/alter Flux
objects within a cluster can instruct Flux to apply such changes, which
in single tenancy effectively means that such users have cluster admin
permissions to the target clusters. The caveat being that using Flux you
can add additional security controls between the user and the target
cluster, for example, before each change is merged into a repository
Pull Requests must be created requiring peer reviews. The Open GitOps
community started defining and codifying this further - have a look [at
this blog post](https://opengitops.dev/blog/sec-gitops/) if
you want to know more.

In multi-tenant environments, users with similar permissions can only
affect part of a cluster, or an isolated cluster in a group of clusters.
Therefore, if a user can gain escalated privileges (or deny service) at a Flux
level, it will have an impact way larger than on single-tenant clusters, as
the users can impact more than just themselves.

At time of writing, we are unaware of any public exploits in the wild,
and therefore have no reason to believe such vulnerabilities have been
actively exploited.

## The advisories in detail

### [CVE-2022-24817](https://github.com/fluxcd/flux2/security/advisories/GHSA-vvmq-fwmg-2gjc) - Kubeconfig Validation

At the beginning of the Flux2's journey we implemented a feature to apply
state to remote clusters. It enables users to have a management cluster
in which Flux is installed, which then applies changes to other
clusters, making it ideal for some multi-tenancy scenarios in which high
isolation across tenants is needed.

The connection between the management cluster and the target clusters is
done by referencing a Kubernetes secret containing a kubeconfig, which is set at the `spec.KubeConfig` field in
either `Kustomization` or `HelmRelease` objects.

One interesting thing about kubeconfigs is that they are quite
extensible. You can for example define an executable which will then be
automatically called by `kubectl` every time it requires a new on-demand
access token. An example of this in action is
[aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator),
which enables AWS users to authenticate against AWS and then use the
returning JWT tokens to access their EKS clusters. Once the token expires,
the process happens again. All that is managed by `kubectl` behind the scenes
without user intervention.

The problem here is that first, the use of executables in kubeconfigs
was enabled by default. Meaning that a malicious tenant would be able to
craft a malicious kubeconfig which could lead to privilege escalation
within the cluster.

As a solution, we decided to disable this feature by default. It can
still be enabled at a cluster level via a new flag
`--insecure-kubeconfig-exec` being sent to the controller binary.

For cluster admins considering this feature, we also recommend the use
of AppArmor and SELinux profiles to enforce at Kernel level what
binaries could be executed.

### [CVE-2022-24877](https://github.com/fluxcd/flux2/security/advisories/GHSA-j77r-2fxf-5jrw) - Kustomization Path Traversal

Flux allows users to lean on Kustomize features to make their lives
easier as they go on about declaring the state of their clusters. Some
of those features could result in sensitive data from the pod filesystem
to be exposed into the target cluster, which could lead to a malicious
tenant being privy to anything sensitive that may exist in the
controller's filesystem or attached volumes (e.g. token).

The mitigation for the path traversal was to create stronger bounds,
enforcing that all `kustomize` operations happen within such bounds or
result in error.

### [CVE-2022-24878](https://github.com/fluxcd/flux2/security/advisories/GHSA-7pwf-jg34-hxwp) - Kustomization Denial of Service

Whilst working on the mitigation of the previous CVE, we have noticed
that in some scenarios a specially crafted `kustomization.yaml` could lead
to the `kustomize-controller` to enter into an endless loop, and finally
crash.

For single-tenant clusters, this would mean that an user may make a mistake and
the controller stops working, potentially resulting in future
reconciliations not being applied. For multi-tenant clusters, depending on the
deployment model, a tenant could cause a disruption to affect not only
itself but also the other tenants and potentially even the management
cluster.

The solution mitigating this vulnerability was to further improve our
validation and ensure that such scenarios are not processed in the first
place.

## Inspecting your Flux system version

To check if your system is currently vulnerable, run `flux version --context=my-cluster`
with the `--context` set to the cluster you want to inspect. This will
report the current Flux binary and controller versions.

### Vulnerable Flux system

To find out if your system could be vulnerable, simply find out the
version of Flux. Here it's important to check you are running all of
these:

- flux `< v0.29.0`
- helm-controller `< v0.19.0`
- kustomize-controller `< v0.24.0`.

You can do this like so:

```cli
$ flux version
flux: v0.22.1
helm-controller: v0.12.2
kustomize-controller: v0.17.0
notification-controller: v0.18.1
source-controller: v0.17.2
```

### Updating your vulnerable system

:collision: If you find the controllers versioned within the range
mentioned above, follow the upgrade procedure for your system. For
`flux bootstrap`, this can be done by running the command again with
the same arguments as used during install.

:warning: Please note that if you are upgrading from below one of the
versions in the following list, there are breaking changes and, pre-
and/or post-upgrade notes you need to take into account:
[0.29](/blog/2022/05/april-2022-update/#latest-flux-release-series-is-029),
[0.28](https://github.com/fluxcd/flux2/discussions/2567),
[0.27](/blog/2022/03/february-update/#latest-flux-is-027),
[0.26](/blog/2022/01/january-update/#flux-v026-more-secure-by-default),
[0.24 - 0.21](/blog/2021/11/december-update/#a-flurry-of-flux-releases).

### Up-to-date Flux system

An up to date Flux system should at least have versions listed below:

- flux `>= v0.29.0`
- helm-controller `>= v0.19.0`
- kustomize-controller `>= v0.24.0`

So in practice the output could look like this:

```cli
$ flux version
flux version
flux: v0.30.2
helm-controller: v0.21.0
kustomize-controller: v0.25.0
notification-controller: v0.23.5
source-controller: v0.24.4
```

We encourage all users to keep Flux up-to-date. We offer a [GitHub Action](https://github.com/fluxcd/flux2/tree/main/action#automate-flux-updates) with which you can automate the Flux upgrades in a GitOps manner, without having to connect from CI to the cluster's API, as Flux is capable of upgrading itself from Git.
## Flux Security more generally speaking

It is no secret that the Flux community has been investing in security
for a long time. Early on the Flux journey we re-architectured the
codebase to avoid shelling out to binaries to decrease the likelihood of
code execution vulnerabilities. The story about our Git integration [we
wrote down here](/blog/2022/03/flux-puts-the-git-into-gitops/).

As Security is such a central pillar of Flux, we are [keen to write
about it](/tags/security/) and tell you how you can benefit from all
the individual features and improvements we worked on, e.g. SBOMs,
CI Checks, Branch Protection, restricted pod security standard and
more. Since the beginning we worked hard to ensure that we ship code
that does what it needs to do, even when that means having to rewrite
parts of upstream dependencies.

When we had our [first security audit last
year](/blog/2021/11/flux-security-audit/), the results were quite
reassuring as most of the findings were quite small, with the exception
of a [RCE in
kustomize-controller](https://github.com/fluxcd/kustomize-controller/security/advisories/GHSA-35rf-v2jv-gfg7),
which speaks to the security improvements we have been investing on, and
how they are resulting in better development practices.

Another recommendation from the auditors was to implement and follow a
stricter and more elaborate RFC process, which is [what we
did](https://github.com/fluxcd/flux2/tree/main/rfcs). They
also recommended we get in touch with other security teams or auditors
for getting feedback on a refined and more general multi-tenancy
proposal - which we also did as mentioned below.

## What's next for Flux

The way we shaped the Flux Roadmap for GA was

1. Feature party with Flux Legacy
2. Stable APIs (this was after the controller refactoring which
   consolidated functionality in
   [fluxcd/pkg](https://github.com/fluxcd/pkg))
3. Straightforward multi-tenancy implementation
4. GA release

[Here is the status
quo](https://github.com/fluxcd/flux2/issues/2655) regarding
multi-tenancy:

> *Flux2 supports multi-tenancy, and users have been using it in
> production for* *[some time
> now](https://www.youtube.com/watch?v=F7B_TBcIyl8).*
>
> *The documentation around the subject covers a* *[bootstrap
> example](https://github.com/fluxcd/flux2-multi-tenancy)
> to help users kick start their multi-tenancy deployments. And also how
> to implement control plane isolation with the*
> *[multi-tenancy-lockdown](/flux/installation/configuration/multitenancy/).*
>
> ***What\'s next***
>
> *In summary, the documentation needs expanding to better inform users
> around the security risks of multi-tenancy and the recommended
> deployment models for their specific isolation/security requirements.*
>
> *There are proposed changes that would further improve Flux in
> multi-tenancy environments, by for example enabling tenants to share
> resources amongst themselves. Such changes must be progressed once the
> security impact of such changes have been assessed.*

To help us get this right, we are engaging with the [CNCF TAG
Security](https://github.com/cncf/tag-security). This is
the upstream group where key contributors and experts of the CNCF
Landscape assemble and define security best practices across all the
individual Cloud Native projects. We are [asking them for an
independent security
review](https://github.com/cncf/tag-security/issues/896)
and recommendations, particularly around multi-tenancy.

If you want to join the conversation, we are all ears. Please refer to
the open RFC documents and have your say there. We definitely want to
get this right for everyone.

- [RFC: Define Flux tenancy models #2086](https://github.com/fluxcd/flux2/pull/2086)
- [RFC: Access control for cross-namespace source refs #2092](https://github.com/fluxcd/flux2/pull/2092)
- [RFC: Flux Multi-Tenancy Mode #2093](https://github.com/fluxcd/flux2/pull/2093)

In addition to that we are working hard to round up features, improve
their performance, security and overall stability.

If you want to follow all the other GA related work, we explained [how
to do that
here](/blog/2022/04/march-update/#flux-maintainers-focus-project-board)
and if you would like to participate in any of the discussions, [come
and find us](/blog/2022/04/contributing-to-flux/)
on Slack or in our regular meetings. We are always looking forward to
growing Team Flux and the closer we get to GA, it's getting even more
important to have all voices heard.
