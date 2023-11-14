---
title: "Using the GitOps Toolkit APIs with Go"
linkTitle: "Using the GitOps Toolkit APIs with Go"
description: "The GitOps Toolkit client libraries documentation."
weight: 10
---

While you can use the GitOps Toolkit APIs in a declarative manner with `kubectl apply`,
we provide client library code for all our toolkit APIs that makes it easier to access them from Go.

## Go Packages

The GitOps Toolkit Go modules and controllers are released by following the [semver](https://semver.org) conventions.

The API schema definitions modules have the following dependencies:

* [github.com/fluxcd/pkg/apis/meta](https://pkg.go.dev/github.com/fluxcd/pkg/apis/meta)
* [github.com/fluxcd/pkg/runtime](https://pkg.go.dev/github.com/fluxcd/pkg/runtime)
* [k8s.io/apimachinery](https://pkg.go.dev/k8s.io/apimachinery)
* [sigs.k8s.io/controller-runtime](https://pkg.go.dev/sigs.k8s.io/controller-runtime)

The APIs can be consumed with the [controller-runtime client](https://pkg.go.dev/sigs.k8s.io/controller-runtime/pkg/client).

### source.toolkit.fluxcd.io

Download package

```sh
go get github.com/fluxcd/source-controller/api
```

Import package

```go
import sourcev1b2 "github.com/fluxcd/source-controller/api/v1beta2"
```

and for `GitRepository` objects:

```go
import sourcev1 "github.com/fluxcd/source-controller/api/v1"
```

API Types

| Name                                                       | Version |
|------------------------------------------------------------|---------|
| [GitRepository](../components/source/gitrepositories.md)   | v1      |
| [HelmRepository](../components/source/helmrepositories.md) | v1beta2 |
| [HelmChart](../components/source/helmcharts.md)            | v1beta2 |
| [Bucket](../components/source/buckets.md)                  | v1beta2 |

### kustomize.toolkit.fluxcd.io

Download package

```sh
go get github.com/fluxcd/kustomize-controller/api
```

Import package

```go
import kustomizev1 "github.com/fluxcd/kustomize-controller/api/v1"
```

API Types

| Name                                                       | Version |
|------------------------------------------------------------|---------|
| [Kustomization](../components/kustomize/kustomizations.md) | v1      |

### helm.toolkit.fluxcd.io

Download package

```sh
go get github.com/fluxcd/helm-controller/api
```

Import package

```go
import helmv2 "github.com/fluxcd/helm-controller/api/v2beta1"
```

API Types

| Name                                              | Version |
|---------------------------------------------------|---------|
| [HelmRelease](../components/helm/helmreleases.md) | v2beta1 |

### notification.toolkit.fluxcd.io

Download package

```sh
go get github.com/fluxcd/notification-controller/api
```

Import package

```go
import notificationv1b3 "github.com/fluxcd/notification-controller/api/v1beta3"
```

and for `Receiver` objects:

```go
import notificationv1 "github.com/fluxcd/notification-controller/api/v1"
```

API Types

| Name                                               | Version |
|----------------------------------------------------|---------|
| [Receiver](../components/notification/receiver.md) | v1      |
| [Provider](../components/notification/provider.md) | v1beta3 |
| [Alert](../components/notification/alert.md)       | v1beta3 |

### image.toolkit.fluxcd.io

Download package

```sh
go get github.com/fluxcd/image-reflector-controller/api
go get github.com/fluxcd/image-automation-controller/api
```

Import package

```go
import (
	imagev1 "github.com/fluxcd/image-reflector-controller/api/v1beta2"
	autov1 "github.com/fluxcd/image-automation-controller/api/v1beta1"
)
```

API Types

| Name                                                                   | Version |
|------------------------------------------------------------------------|---------|
| [ImageRepository](../components/image/imagerepositories.md)            | v1beta2 |
| [ImagePolicy](../components/image/imagepolicies.md)                    | v1beta2 |
| [ImageUpdateAutomation](../components/image/imageupdateautomations.md) | v1beta1 |

## CRUD Example

Here is an example of how to create a Helm release, wait for it to install, then delete it:

```go
package main

import (
  "context"
  "fmt"
  "time"

  apiextensionsv1 "k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1"
  "k8s.io/apimachinery/pkg/api/meta"
  metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
  "k8s.io/apimachinery/pkg/runtime"
  "k8s.io/apimachinery/pkg/types"
  "k8s.io/apimachinery/pkg/util/wait"
  _ "k8s.io/client-go/plugin/pkg/client/auth"
  ctrl "sigs.k8s.io/controller-runtime"
  "sigs.k8s.io/controller-runtime/pkg/client"

  helmv2 "github.com/fluxcd/helm-controller/api/v2beta1"
  apimeta "github.com/fluxcd/pkg/apis/meta"
  sourcev1 "github.com/fluxcd/source-controller/api/v1beta2"
)

func main() {
  // register the GitOps Toolkit schema definitions
  scheme := runtime.NewScheme()
  _ = sourcev1.AddToScheme(scheme)
  _ = helmv2.AddToScheme(scheme)

  // init Kubernetes client
  kubeClient, err := client.New(ctrl.GetConfigOrDie(), client.Options{Scheme: scheme})
  if err != nil {
    panic(err)
  }

  // set a deadline for the Kubernetes API operations
  ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
  defer cancel()

  // create a Helm repository pointing to Bitnami
  helmRepository := &sourcev1.HelmRepository{
    ObjectMeta: metav1.ObjectMeta{
      Name:      "bitnami",
      Namespace: "default",
    },
    Spec: sourcev1.HelmRepositorySpec{
      URL: "https://charts.bitnami.com/bitnami",
      Interval: metav1.Duration{
        Duration: 30 * time.Minute,
      },
    },
  }
  if err := kubeClient.Create(ctx, helmRepository); err != nil {
    fmt.Println(err)
  } else {
    fmt.Println("HelmRepository bitnami created")
  }

  // create a Helm release for nginx
  helmRelease := &helmv2.HelmRelease{
    ObjectMeta: metav1.ObjectMeta{
      Name:      "nginx",
      Namespace: "default",
    },
    Spec: helmv2.HelmReleaseSpec{
      ReleaseName: "nginx",
      Interval: metav1.Duration{
        Duration: 5 * time.Minute,
      },
      Chart: helmv2.HelmChartTemplate{
        Spec: helmv2.HelmChartTemplateSpec{
          Chart:   "nginx",
          Version: "8.x",
          SourceRef: helmv2.CrossNamespaceObjectReference{
            Kind: sourcev1.HelmRepositoryKind,
            Name: "bitnami",
          },
        },
      },
      Values: &apiextensionsv1.JSON{Raw: []byte(`{"service": {"type": "ClusterIP"}}`)},
    },
  }
  if err := kubeClient.Create(ctx, helmRelease); err != nil {
    fmt.Println(err)
  } else {
    fmt.Println("HelmRelease nginx created")
  }

  // wait for the a Helm release to be reconciled
  fmt.Println("Waiting for nginx to be installed")
  if err := wait.PollImmediate(2*time.Second, 1*time.Minute,
    func() (done bool, err error) {
      namespacedName := types.NamespacedName{
        Namespace: helmRelease.GetNamespace(),
        Name:      helmRelease.GetName(),
      }
      if err := kubeClient.Get(ctx, namespacedName, helmRelease); err != nil {
        return false, err
      }
      return meta.IsStatusConditionTrue(helmRelease.Status.Conditions, apimeta.ReadyCondition), nil
    }); err != nil {
    fmt.Println(err)
  }

  // print the reconciliation status
  fmt.Println(meta.FindStatusCondition(helmRelease.Status.Conditions, apimeta.ReadyCondition).Message)

  // uninstall the release and delete the repository
  if err := kubeClient.Delete(ctx, helmRelease); err != nil {
    fmt.Println(err)
  }
  if err := kubeClient.Delete(ctx, helmRepository); err != nil {
    fmt.Println(err)
  }
  fmt.Println("Helm repository and release deleted")
}
```

For an example on how to build a Kubernetes controller that interacts with the GitOps Toolkit APIs see
[source-watcher](source-watcher.md).
