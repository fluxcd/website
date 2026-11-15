---
title: "Enterprise best practices"
linkTitle: "Reconnemdations for using Flux by large, regulated companies"
description: "What features does Flux offer to support very large, regulated cluster-deployments"
weight: 15
---

This guide presents you ways how Flux supports GitOps deployment practices at scale

## Use OCIRepository as a manifest source

While GitOps has `git` in its name, in reality it does not require `git` to work, and storing manifests in an OCI registry has several advantages over Git storage.

- Registries are designed to have very high availability and support large scale pull operations
- Registries might be more accessible for your cluster than your SCM because of networking restrictions
- Pushing to a registry can help with compliance for regulated industries as the "push" step can be made manual
- You can save network bandwidth and memory by creating small OCI containers to store manifests, avoiding the pulling of a larger git repository into the cluster
- Registries might have additional features like scanners that look only at the content meant to be deployed, not all your repository
- As containers can be signed, Flux can check their provenance at deploy time

## Vertical scaling

When Flux is managing hundreds of applications that are deployed multiple times per day, cluster admins can fine tune the Flux controller at bootstrap time. 
We have [dedicated documentation on configuring vertical scaling with Flux](../installation/configuration/vertical-scaling.md).

## Horizontal scaling

When Flux is managing tens of thousands of applications, it is advised to adopt a sharding strategy to spread the load between multiple instances of Flux controllers.
To enable horizontal scaling, each controller can be deployed multiple times with a unique label selector which is used as the sharding key.

We have [dedicated documentation on configuring horizontal scaling with Flux](../installation/configuration/horizontal-scaling.md).

## Supply-chain security

When using [OciRepository](../components/source/ocirepositories.md#verification) or ([Helm fetched from an OCI registry](../components/source/helmcharts/#verification)), Flux offers container signature verification at deploy time.

## Consultancy

In the end, it might still be intimidating to not only adopt a best in class GitOps tool, but do it at the enterprise scale. 
If the documentation and community support can not answer all your questions, we recommend taking professional consultancy services.
The following is a non-comprehensive list of companies offering such services:

- [ControlPlane]([url](https://control-plane.io/)) (the primary sponsor of FluxCD)

(To add your services here, please, open a PR)
