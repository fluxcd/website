---
description: Flagger is a progressive delivery Kubernetes operator
weight: 1
title: Flagger
cascade:
  type: docs
---

[Flagger](https://github.com/fluxcd/flagger) is a progressive delivery tool that automates the release
process for applications running on Kubernetes. It reduces the risk associated with introducing a new software
version in production by gradually shifting traffic to the new version while measuring metrics
and running conformance tests.

Flagger implements several deployment strategies (Canary releases, A/B testing, Blue/Green mirroring)
using a service mesh (App Mesh, Istio, Linkerd, Kuma, Open Service Mesh)
or an ingress controller (Contour, Gloo, NGINX, Skipper, Traefik, APISIX) for traffic routing.
For release analysis, Flagger can query Prometheus, InfluxDB, Datadog, New Relic, CloudWatch, Stackdriver
or Graphite and for alerting it uses Slack, MS Teams, Discord and Rocket.

![Flagger overview diagram](/img/diagrams/flagger-overview.png)

Flagger can be configured with Kubernetes custom resources and is compatible with
any CI/CD solutions made for Kubernetes. Since Flagger is declarative and reacts to Kubernetes events,
it can be used in **GitOps** pipelines together with tools like Flux, JenkinsX, Carvel, Argo, etc.

## Getting started

To get started with Flagger, choose one of the supported routing providers and
[install](install/flagger-install-with-flux.md) Flagger with Flux.

After installing Flagger, you can follow one of these tutorials to get started:

**Service mesh tutorials**

* [Istio](tutorials/istio-progressive-delivery.md)
* [Linkerd](tutorials/linkerd-progressive-delivery.md)
* [AWS App Mesh](tutorials/appmesh-progressive-delivery.md)
* [AWS App Mesh: Canary Deployment Using Flagger](https://www.eksworkshop.com/advanced/340_appmesh_flagger/)
* [Open Service Mesh](tutorials/osm-progressive-delivery.md)
* [Kuma](tutorials/kuma-progressive-delivery.md)

**Ingress controller tutorials**

* [Contour](tutorials/contour-progressive-delivery.md)
* [Gloo](tutorials/gloo-progressive-delivery.md)
* [NGINX Ingress](tutorials/nginx-progressive-delivery.md)
* [Skipper Ingress](tutorials/skipper-progressive-delivery.md)
* [Traefik](tutorials/traefik-progressive-delivery.md)

**Hands-on GitOps workshops**

* [Istio](https://github.com/stefanprodan/gitops-istio)
* [Linkerd](https://helm.workshop.flagger.dev)
* [AWS App Mesh](https://eks.handson.flagger.dev)

## CNCF

Flagger is a [Cloud Native Computing Foundation](https://cncf.io/) project
and part of [Flux](/) family of GitOps tools.

_The Linux Foundation® (TLF) has registered trademarks and uses trademarks.
For a list of TLF trademarks, see [Trademark Usage](https://www.linuxfoundation.org/trademark-usage)._
