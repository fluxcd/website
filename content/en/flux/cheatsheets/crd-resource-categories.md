---
title: "CRD resource categories"
linkTitle: "CRD Resource Categories"
description: "How to list and discover Flux resources using kubectl CRD categories."
weight: 35
---

Starting with Flux 2.9, all Flux Custom Resource Definitions (CRDs)
include [Kubernetes resource categories](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#categories)
that allow you to use `kubectl get` with category selectors to list Flux resources
across multiple CRD types in a single command.

## Categories

Every Flux CRD is assigned exactly three categories:

| Category | Scope | Description |
|---|---|---|
| `all` | Cluster-wide | Includes Flux resources in `kubectl get all` output |
| `fluxcd` | All Flux CRDs | Lists every Flux custom resource |
| Resource-specific | Per resource | Lists resources matching a specific Flux CRD category |

The resource-specific categories are:

| Category | Controllers | CRDs |
|---|---|---|
| `fluxcd-sources` | source-controller, source-watcher, flux-operator | `GitRepository`, `OCIRepository`, `HelmRepository`, `HelmChart`, `Bucket`, `ExternalArtifact`, `ArtifactGenerator`, `ResourceSetInputProvider` |
| `fluxcd-appliers` | kustomize-controller, helm-controller, flux-operator | `Kustomization`, `HelmRelease`, `ResourceSet`, `FluxInstance` |
| `fluxcd-notifications` | notification-controller | `Alert`, `Provider`, `Receiver` |
| `fluxcd-images` | image-reflector-controller, image-automation-controller | `ImageRepository`, `ImagePolicy`, `ImageUpdateAutomation` |

## Flux CLI Comparison

### `flux get all`

```
NAME                       	REVISION              	SUSPENDED	READY	MESSAGE                                             
ocirepository/flux-operator	0.52.0@sha256:e25cf78b	False    	True 	stored artifact for digest '0.52.0@sha256:e25cf78b'	
ocirepository/flux-system  	latest@sha256:f94b6833	False    	True 	stored artifact for digest 'latest@sha256:f94b6833'	

NAME                       	REVISION          	SUSPENDED	READY	MESSAGE                                           
gitrepository/flux-operator	main@sha1:32cc2167	False    	True 	stored artifact for revision 'main@sha1:32cc2167'	

NAME                          	REVISION           	SUSPENDED	READY	MESSAGE                                                                                                                  
helmrelease/flux-operator     	0.52.0+e25cf78b888f	False    	True 	Helm upgrade succeeded for release flux-system/flux-operator.v75 with chart flux-operator@0.52.0+e25cf78b888f           	
helmrelease/flux-status-server	0.52.0+e25cf78b888f	False    	True 	Helm upgrade succeeded for release flux-system/flux-status-server.v217 with chart flux-operator@0.52.0+e25cf78b888f     	

NAME                     	REVISION              	SUSPENDED	READY	MESSAGE                                  
kustomization/eks-addons 	latest@sha256:f94b6833	False    	True 	Applied revision: latest@sha256:f94b6833	
kustomization/flux-system	latest@sha256:f94b6833	True     	True 	Applied revision: latest@sha256:f94b6833	
kustomization/policies   	latest@sha256:f94b6833	False    	True 	Applied revision: latest@sha256:f94b6833	
kustomization/preview    	latest@sha256:f94b6833	False    	True 	Applied revision: latest@sha256:f94b6833	
kustomization/tenants    	latest@sha256:f94b6833	False    	True 	Applied revision: latest@sha256:f94b6833	

NAME                          	SUSPENDED	READY	MESSAGE                                                                                               
receiver/flux-webhook-receiver	False    	True 	Receiver initialized for path: /hook/69e8f574d0c34d33ebe39a64ef882ac270c1e122383722aac8a36ef139ed42ac	

NAME            	READY	MESSAGE           
provider/grafana	True 	Provider is Ready	

NAME         	SUSPENDED	READY	MESSAGE        
alert/grafana	False    	True 	Alert is Ready	
```

### `kubectl get fluxcd`

```
NAME                                       AGE    READY   STATUS                           REVISION
fluxinstance.fluxcd.controlplane.io/flux   273d   True    Reconciliation finished in 14s   v2.8.8@sha256:0364968cd7f733e2d87d2237845812cd1f373342db3b573e19fd2cd977ee85d5

NAME                                     AGE    READY   STATUS                        LASTUPDATED
fluxreport.fluxcd.controlplane.io/flux   338d   True    Reporting finished in 165ms   2026-06-27T13:16:29Z

NAME                                                                 AGE    READY   STATUS
resourcesetinputprovider.fluxcd.controlplane.io/apps-preview-main    317d   True    Reconciliation finished in 516ms
resourcesetinputprovider.fluxcd.controlplane.io/apps-preview-prs     317d   True    Reconciliation finished in 406ms
resourcesetinputprovider.fluxcd.controlplane.io/flux-status-server   232d   True    Reconciliation finished in 568ms

NAME                                                     AGE    READY   STATUS
resourceset.fluxcd.controlplane.io/apps                  338d   True    Reconciliation finished in 332ms
resourceset.fluxcd.controlplane.io/apps-preview-main     317d   True    Reconciliation finished in 188ms
resourceset.fluxcd.controlplane.io/apps-preview-prs      317d   True    Reconciliation finished in 20ms
resourceset.fluxcd.controlplane.io/eks-storage-classes   84d    True    Reconciliation finished in 53ms
resourceset.fluxcd.controlplane.io/flux-addons           337d   True    Reconciliation finished in 133ms
resourceset.fluxcd.controlplane.io/flux-operator         338d   True    Reconciliation finished in 61ms
resourceset.fluxcd.controlplane.io/flux-status-server    190d   True    Reconciliation finished in 54ms
resourceset.fluxcd.controlplane.io/flux-tests            9d     True    Reconciliation finished in 43ms
resourceset.fluxcd.controlplane.io/infra                 338d   True    Reconciliation finished in 574ms
resourceset.fluxcd.controlplane.io/sso-rbac              156d   True    Reconciliation finished in 62ms

NAME                                                    AGE    READY   STATUS
helmrelease.helm.toolkit.fluxcd.io/flux-operator        273d   True    Helm upgrade succeeded for release flux-system/flux-operator.v75 with chart flux-operator@0.52.0+e25cf78b888f
helmrelease.helm.toolkit.fluxcd.io/flux-status-server   190d   True    Helm upgrade succeeded for release flux-system/flux-status-server.v217 with chart flux-operator@0.52.0+e25cf78b888f

NAME                                                    AGE    READY   STATUS
kustomization.kustomize.toolkit.fluxcd.io/eks-addons    84d    True    Applied revision: latest@sha256:f94b6833fca12be1f1ae24f7bef7445127b6ab36acaecae298bb3ac64c6e340e
kustomization.kustomize.toolkit.fluxcd.io/flux-system   273d   True    Applied revision: latest@sha256:f94b6833fca12be1f1ae24f7bef7445127b6ab36acaecae298bb3ac64c6e340e
kustomization.kustomize.toolkit.fluxcd.io/policies      84d    True    Applied revision: latest@sha256:f94b6833fca12be1f1ae24f7bef7445127b6ab36acaecae298bb3ac64c6e340e
kustomization.kustomize.toolkit.fluxcd.io/preview       273d   True    Applied revision: latest@sha256:f94b6833fca12be1f1ae24f7bef7445127b6ab36acaecae298bb3ac64c6e340e
kustomization.kustomize.toolkit.fluxcd.io/tenants       273d   True    Applied revision: latest@sha256:f94b6833fca12be1f1ae24f7bef7445127b6ab36acaecae298bb3ac64c6e340e

NAME                                                            AGE    READY   STATUS
receiver.notification.toolkit.fluxcd.io/flux-webhook-receiver   273d   True    Receiver initialized for path: /hook/69e8f574d0c34d33ebe39a64ef882ac270c1e122383722aac8a36ef139ed42ac

NAME                                           AGE
alert.notification.toolkit.fluxcd.io/grafana   273d

NAME                                              AGE
provider.notification.toolkit.fluxcd.io/grafana   273d

NAME                                                   URL                                                        AGE   READY   STATUS
gitrepository.source.toolkit.fluxcd.io/flux-operator   ssh://git@github.com/controlplaneio-fluxcd/flux-operator   9d    True    stored artifact for revision 'main@sha1:32cc21670b4089e30cac7b90d9b468354142cae4'

NAME                                                   URL                                                           READY   STATUS                                                                                                        AGE
ocirepository.source.toolkit.fluxcd.io/flux-operator   oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator      True    stored artifact for digest '0.52.0@sha256:e25cf78b888fb82afadcb0c06bbb3dce8c5c5d0313e304ce67b6a7744977e458'   273d
ocirepository.source.toolkit.fluxcd.io/flux-system     oci://123456789012.dkr.ecr.eu-west-2.amazonaws.com/d2-fleet   True    stored artifact for digest 'latest@sha256:f94b6833fca12be1f1ae24f7bef7445127b6ab36acaecae298bb3ac64c6e340e'   273d
```
