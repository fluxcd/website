---
title: "Troubleshooting cheatsheet"
linkTitle: "Troubleshooting"
description: "Showcase various ways to get more information out of Flux controllers to debug potential problems."
weight: 40
---

## Getting basic information

Show all Flux objects that are not ready

```cli
flux get all -A --status-selector ready=false
```

Show flux warning events 

```cli
kubectl get events -n flux-system --field-selector type=Warning
```

Flux CLI (check for `Ready=True` and `Suspend=False`)

```cli
flux get sources all -A
```

See the CLI reference for [`get_sources_all`](/docs/cmd/flux_get_sources_all/).

`kubectl` (check for `Ready=True`)

```cli
kubectl get gitrepositories.source.toolkit.fluxcd.io -A
kubectl get helmrepositories.source.toolkit.fluxcd.io -A
```

Flux CLI (check for Ready=True and Suspend=False)

```cli
flux get kustomizations -A
flux get helmreleases -A
```

CLI reference for [`get_kustomizations`](/docs/cmd/flux_get_kustomizations/) and [`get_helmreleases`](/docs/cmd/flux_get_helmreleases/).


`kubectl` (check for `Ready=True`)

```cli
kubectl get kustomizations.kustomize.toolkit.fluxcd.io -A
kubectl get helmreleases.helm.toolkit.fluxcd.io -A
kubectl get helmcharts.source.toolkit.fluxcd.io -A
```

Looking for controller errors:

```cli
flux logs --all-namespaces --level=error
```

Check controllers readiness and versions:

```cli
flux check
```

CLI reference for [`check`](/docs/cmd/flux_check/).

### Changes not being applied

1. Are the sources up-to-date and ready?
   How to check:
   1. Grafana Dashboard - Flux Cluster Stats
      ![Cluster Dashboard](/img/cluster-dashboard.png)
   1. Flux CLI (check for `Ready=True` and `Suspend=False`)
      ```cli
      flux get sources all -A
      ```
      See the CLI reference for [`get_sources_all`](/docs/cmd/flux_get_sources_all/).
   1. `kubectl` (check for `Ready=True`)
      ```cli
      kubectl get gitrepositories.source.toolkit.fluxcd.io -A
      kubectl get helmrepositories.source.toolkit.fluxcd.io -A
      ```
1. `Kustomization`/`HelmReleases` configured and ready?
   How to check:
   1. Grafana Dashboard - Flux Cluster Stats
   1. Flux CLI (check for `Ready=True` and `Suspend=False`)
      ```cli
      flux get kustomizations -A
      flux get helmreleases -A
      ```
      CLI reference for [`get_kustomizations`](/docs/cmd/flux_get_kustomizations/) and [`get_helmreleases`](/docs/cmd/flux_get_helmreleases/).
   1. `kubectl` (check for `Ready=True`)
      ```cli
      kubectl get kustomizations.kustomize.toolkit.fluxcd.io -A
      kubectl get helmreleases.helm.toolkit.fluxcd.io -A
      kubectl get helmcharts.source.toolkit.fluxcd.io -A
      ```











