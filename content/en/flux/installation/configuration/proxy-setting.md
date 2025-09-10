---
title: "Flux proxy settings"
linkTitle: "Proxy settings"
description: "How to configure proxies for Flux controllers"
weight: 18
---

If the Kubernetes cluster has Internet restrictions, requiring egress traffic to go
through a proxy for accessing external services, you can configure the Flux controllers
to use a HTTP/S and/or SOCKS5 SSH proxy. 

## Using HTTP/S proxy for egress traffic

If your cluster uses an HTTP proxy to reach GitHub or other external services,
you must set `NO_PROXY=.cluster.local.,.cluster.local,.svc`
to allow the Flux controllers to talk to each other.

To set the HTTP/S proxy [during bootstrap](bootstrap-customization.md), add the following patches to the flux-system `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: all
      spec:
        template:
          spec:
            containers:
              - name: manager
                env:
                  - name: "HTTPS_PROXY"
                    value: "https://proxy.example.com"
                  - name: "NO_PROXY"
                    value: ".cluster.local.,.cluster.local,.svc"
    target:
      kind: Deployment
      labelSelector: app.kubernetes.io/part-of=flux
```

## Git repository access via SOCKS5 SSH proxy

To configure a SOCKS5 proxy, set the environment variable `ALL_PROXY` to allow
both source-controller and image-automation-controller to connect through the
proxy.

To set the SOCKS5 proxy [during bootstrap](bootstrap-customization.md), add the following patches to the flux-system `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: all
      spec:
        template:
          spec:
            containers:
              - name: manager
                env:
                  - name: "ALL_PROXY"
                    value: "socks5://proxy.example.com:1080"
    target:
      kind: Deployment
      labelSelector: app.kubernetes.io/part-of=flux
      name: "(source-controller|image-automation-controller)"
```
