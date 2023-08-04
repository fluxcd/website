---
title: "Proxy settings for HTTP/s & SOCKS5 SSH"
linkTitle: "Proxy settings for HTTP/s & SOCKS5 SSH"
description: "How to configure proxy settings via HTTP/s & SOCKS5 SSH"
weight: 18
---

Flux lets you configure proxies for egress traffic in your Kubernetes cluster. 
You can set up an HTTP/S proxy to reach external services like GitHub, or use a SOCKS5 SSH proxy for Internet-restricted environments. 
This page provides the YAML configuration for setting up both types of proxies and ensuring efficient communication while managing external connections and Git repository access.

## Using HTTP/S proxy for egress traffic

If your cluster must use an HTTP proxy to reach GitHub or other external services,
you must set `NO_PROXY=.cluster.local.,.cluster.local,.svc`
to allow the Flux controllers to talk to each other.

To use an HTTP proxy [during bootstrap](_index.md), add the following patches to the flux-system `kustomization.yaml`:

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
                    value: "http://proxy.example.com:3129"
                  - name: "NO_PROXY"
                    value: ".cluster.local.,.cluster.local,.svc"
    target:
      kind: Deployment
      labelSelector: app.kubernetes.io/part-of=flux
```

## Git repository access via SOCKS5 SSH proxy

If your cluster has Internet restrictions, requiring egress traffic to go
through a proxy, you must use a SOCKS5 SSH proxy to be able to reach GitHub
(or other external Git servers) via SSH.

To configure a SOCKS5 proxy, set the environment variable `ALL_PROXY` to allow
both source-controller and image-automation-controller to connect through the
proxy.

This can be done by adding the following patches to the flux-system `kustomization.yaml`:


```
ALL_PROXY=socks5://<proxy-address>:<port>
```

The following is an example of patching the Flux setup kustomization to add the
`ALL_PROXY` environment variable in source-controller and
image-automation-controller:

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
