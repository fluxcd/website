---
author: dholbach
date: 2021-09-28 12:30:00+00:00
title: Server-side reconciliation is coming
description: >
  The next Flux release will bring you a new reconciler based on Kubernetes "Server-Side Apply". It will make Flux more performant, observable, less error-prone and provide a generally more delightful experience. This post informs you of the changes you need to take to be able to upgrade.
url: /blog/2021/09/server-side-reconciliation-is-coming/
tags: [announcement]
---


**tl;dr**: Server-side reconciliation will make Flux more performant,
improve overall observability and going forward will allow us to add new
capabilities, like being able to preview local changes to manifests
without pushing to upstream.

⚠ **Changes required**: Due to a [Kubernetes
issue](https://github.com/kubernetes/kubernetes/pull/91748), we require
a certain set of Kubernetes releases (starting `1.16.11` - more on this below)
as a minimum. The logs, events and alerts that report Kubernetes namespaced
object changes are now using the `Kind/Namespace/Name` format instead of
`Kind/Name`.

---

We rarely do this, but this time we want to give you some advance notice
of a big upcoming feature you will be pleased about. Since Kubernetes
moved [server-side
apply](https://kubernetes.io/docs/reference/using-api/server-side-apply/)
to GA, we are offering you a new reconciler based on it, and graduating
the API to `v1beta2`.

## What's happening

- **When does this happen?**\
  With the release of Flux 0.18, we will move to the new reconciler.
  It will be released in the coming weeks. Refer to [this
  PR](https://github.com/fluxcd/kustomize-controller/pull/426)
  for more information.

- **Do I have to use the new thing?**\
  Yes. Flux will be more performant, less error-prone and from a
  maintenance perspective will be a lot easier for us. We understand
  that this new feature will require changes on your end, but we are
  certain you are going to like the new experience!

- **Will my clusters stop working?**\
  No, but you will need to do a little preparation to make sure Flux
  can still apply your configurations. See below.\
  *Note:* The pre-flight checks should be able to catch issues like meeting the
  minimum required Kubernetes version.

## Here is what you get

- The new reconciler improves performance (CPU, memory, network, FD
  usage) and reduces the number of calls to Kubernetes API by
  replacing `kubectl exec` calls with a specialized applier written in
  Go.
- We are able to validate and reconcile sources that contain both CRDs
  and CRs.
- Detects and reports drift between the desired state (git, s3, etc)
  and cluster state reliably.
- In the future: Preview of local changes to manifests without pushing
  to upstream (`flux diff -k` command TBA).
- Being able to wait for all applied resources to become ready without
  requiring users to fill in the health checks list.
- Improves the overall observability of the reconciliation process by
  reporting in real-time the garbage collection and health
  assessment actions.

## This is what you need to do to prepare

**Check the Kubernetes version you are running in your cluster.**
All the versions below fix a regression in the [managed fields and field
type](https://github.com/kubernetes/kubernetes/pull/91748).

| Kubernetes version | Minimum required\* |
| --- | --- |
| `v1.16` | `>= 1.16.11` |
| `v1.17` | `>= 1.17.7` |
| `v1.18` | `>= 1.18.4` |
| `v1.19` and later | `>= 1.19.0` |

*\* Update 2021-10-11:*

If you are using `APIService` objects (for example
[metrics-server](https://github.com/kubernetes-sigs/metrics-server)),
you will need to update to `1.18.18`, `1.19.10`, `1.20.6` or `1.21.0`
at least. See [this
post](https://github.com/fluxcd/flux2/discussions/1916#discussioncomment-1458041)
for more information.

**Namespaced objects must contain metadata.namespace, defaulting to the
default namespace is no longer supported**. This means you will need to
chase down any namespaced resources in your configuration files that are
left to default, and give them a namespace. Keep in mind that
kustomizations are often used to assign a namespace, so even if a
particular file doesn't have a namespace in it, it may not represent a
problem.

**The logs, events and alerts that report Kubernetes namespaced object
changes are now using the `Kind/Namespace/Name` format instead of
`Kind/Name`** e.g.:

```cli
Service/flux-demo/podinfo unchanged
Deployment/flux-demo/podinfo configured
HorizontalPodAutoscaler/flux-demo/podinfo deleted
```

Any automation or monitoring that relies on a particular format in the
logs will need to be adapted. Ideally, you should try to handle both the
old and new formats.

**In terms of API changes, the `kustomize.toolkit.fluxcd.io/v1beta2` API
is backwards compatible with `v1beta1`**. This is done automatically by
the Kubernetes API server, and no preparation is required. You may wish
to translate your Flux `Kustomization` resources, though, according to the
following table.

Additions and deprecations:

| Change in the new version  | What you should do |
| -------------------------- | ------------------ |
| Version is now `v1beta2`   | Change the version: `apiVersion: kustomize.toolkit.fluxcd.io/v1beta2`  |
| `.spec.validation` deprecated | Server-side validation is now assumed. Remove this field from `.spec.` |
| `.spec.patchesStrategicMerge` deprecated in favour of `.spec.patches` | Convert each entry from `.spec.patchesStrategicMerge` into an inline strategic merge patch, like [this example given in the Kustomize documentation](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/#patch-using-inline-strategic-merge), and append to `.spec.patches.`. Note that the value in the patch field is quoted; that is, it is the YAML or JSON of the patch, stringified. |
| `.spec.patchesJson6902` deprecated in favour of `.spec.patches` | Convert each entry from `.spec.patchesJson6902` into [an inline JSON6902 patch](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/#patch-using-inline-json6902), and append to `.spec.patches`. Note that the value in the patch field is quoted; that is, it is the YAML or JSON of the patch, stringified. |
| `.status.snapshot` replaced by `.status.inventory` | `.status` is not kept in files, so you will not need to account for this. |
| `.spec.wait` added | When true, the controller will wait for all the reconciled resources to become ready, and ignore `.spec.healthChecks`.  There is no preparation needed for this, since it's a new feature. |

## Why we are doing this

When we started Flux v2, we set a goal to stop relying on third party
binaries for core features. While we have successfully replaced the Git
CLI shell execs with Go libraries (go-git, git2go) and C libraries
(libgit2, libssh2), the kustomize CLI with Go libraries (kustomize/api,
kustomize/kyaml), we still depend on the kubectl CLI for the
three-way-merge apply feature. With Kubernetes "server-side apply"
[being promoted to
GA](https://kubernetes.io/docs/reference/using-api/server-side-apply/),
we can finally get rid of kubectl and drive the reconciliation using
exclusively the controller-runtime Go client.

Please take a look at [the PR introducing this
change](https://github.com/fluxcd/kustomize-controller/pull/426),
as it talks at length about the issues which are solved by this.

## Sneak-preview

**Updated on 2021-10-08**

The server-side reconciliation has been released in flux2 [v0.18.0](https://github.com/fluxcd/flux2/releases/tag/v0.18.0).

## What's next?

The biggest parts of the work have been done, here is what is still on
our TODO list until the release:

- Use the SSA manager in Flux CLI to for the `flux create` commands
- Use the SSA manager in Flux CLI to implement `flux build` and `flux
  diff` commands


## This is great - I want to participate in this

Please join us in the [\#flux
channel](https://cloud-native.slack.com/archives/CLAJ40HV3)
on CNCF Slack ([get an invite
here](https://slack.cncf.io)) to discuss this.

Or find out other ways of connecting (including our weekly meetings) on
[our Community page](/community/).

We are looking forward to having you in our community!
