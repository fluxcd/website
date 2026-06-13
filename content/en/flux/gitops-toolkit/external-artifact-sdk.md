---
title: "Building ExternalArtifact Controllers"
linkTitle: "Building ExternalArtifact Controllers"
description: "Develop a Kubernetes controller that generates ExternalArtifacts using the Flux Artifact SDK."
weight: 30
---

In this guide you'll learn how to build a Kubernetes controller that acts as a
3rd-party source of truth for Flux by creating
[ExternalArtifact](/flux/components/source/externalartifacts/) resources.
Your controller will use the Flux Artifact SDK
([`github.com/fluxcd/pkg/artifact`](https://pkg.go.dev/github.com/fluxcd/pkg/artifact))
to package, store, and serve artifacts that can be consumed by
[kustomize-controller](/flux/components/kustomize/) and
[helm-controller](/flux/components/helm/).

## Overview

The `ExternalArtifact` API (part of [RFC-0012](https://github.com/fluxcd/flux2/blob/main/rfcs/0012-external-artifact/README.md))
allows 3rd-party controllers to expose artifacts in-cluster in the same way
`source-controller` does. This means Flux `Kustomization` and `HelmRelease`
resources can reference your custom source types via `ExternalArtifact`
without any changes to the Flux core.

The Artifact SDK provides four sub-packages:

| Package | Import Path | Purpose |
|---------|------------|---------|
| **config** | `github.com/fluxcd/pkg/artifact/config` | Flag binding and configuration for storage, server, retention, and digest options |
| **server** | `github.com/fluxcd/pkg/artifact/server` | HTTP file server with graceful shutdown for serving artifacts in-cluster |
| **storage** | `github.com/fluxcd/pkg/artifact/storage` | Artifact lifecycle management — create, archive, verify, copy, GC |
| **digest** | `github.com/fluxcd/pkg/artifact/digest` | Multi-algorithm digest computation (SHA1,SHA256, SHA512, BLAKE3) |

## Prerequisites

On your dev machine install the following tools:

* go >= 1.24
* kubebuilder >= 4.0
* kind >= 0.22
* kubectl >= 1.31
* Flux CLI >= 2.7

## Install Flux

Create a cluster for testing:

```sh
kind create cluster --name dev
```

Install Flux with the `ExternalArtifact` feature gate enabled:

```sh
flux install \
  --namespace=flux-system \
  --network-policy=false \
  --components=source-controller,kustomize-controller,helm-controller
```

Enable the `ExternalArtifact` feature gate on `kustomize-controller` and
`helm-controller`:

```sh
kubectl -n flux-system patch deployment kustomize-controller \
  --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--feature-gates=ExternalArtifact=true"}]'

kubectl -n flux-system patch deployment helm-controller \
  --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--feature-gates=ExternalArtifact=true"}]'
```

## Reference implementation

The [fluxcd/source-watcher](https://github.com/fluxcd/source-watcher) repository
contains a full reference implementation (branch `v2`) of an `ArtifactGenerator`
controller that uses the ExternalArtifact API and SDK. Clone it to follow along:

```sh
git clone https://github.com/fluxcd/source-watcher
cd source-watcher
git checkout v2
```

## SDK Quick Start

### 1. Add the dependency

```sh
go get github.com/fluxcd/pkg/artifact
go get github.com/fluxcd/source-controller/api
```

### 2. Configure the artifact server

Use `config.Options` to declare storage and server settings. The SDK provides
flag binding with environment variable support out of the box:

```go
import (
    "github.com/spf13/pflag"
    "github.com/fluxcd/pkg/artifact/config"
)

func main() {
    opts := &config.Options{}

    // Bind CLI flags for --storage-path, --storage-addr,
    // --storage-adv-addr, --artifact-retention-ttl,
    // --artifact-retention-records, --artifact-digest-algo.
    opts.BindFlags(pflag.CommandLine)
    pflag.Parse()
}
```

Available configuration flags and their defaults:

| Flag | Env Var | Default | Description |
|------|---------|---------|-------------|
| `--storage-path` | `STORAGE_PATH` | `/data` | Directory where artifacts are stored |
| `--storage-addr` | `STORAGE_ADDRESS` | `:9090` | Address the artifact server binds to |
| `--storage-adv-addr` | `STORAGE_ADV_ADDR` | _(auto)_ | In-cluster address advertised to clients |
| `--artifact-retention-ttl` | — | `1m` | Duration after which stale artifacts are GC'd |
| `--artifact-retention-records` | — | `2` | Max artifacts kept per source after GC |
| `--artifact-digest-algo` | — | `sha256` | Hashing algorithm for artifact digests |

### 3. Initialize Storage

The `storage.Storage` type manages artifact tarballs on the local filesystem:

```go
import (
    "github.com/fluxcd/pkg/artifact/config"
    "github.com/fluxcd/pkg/artifact/storage"
)

// Create storage from configuration options.
store, err := storage.New(opts)
if err != nil {
    panic(err)
}
```

### 4. Start the artifact file server

Start the HTTP file server after the controller manager is elected leader.
The server exposes artifacts under the configured storage path and supports
graceful shutdown via context cancellation:

```go
import (
    "github.com/fluxcd/pkg/artifact/server"
)

// Start the artifact server after the controller-manager receives leadership.
go func() {
    <-mgr.Elected()
    if err := server.Start(ctx, opts); err != nil {
        setupLog.Error(err, "unable to start artifact server")
    }
}()
```

### 5. Create and archive artifacts

In your controller's `Reconcile` function, use the storage API to create new
artifacts, archive directories into tarballs, and set digest/size metadata:

```go
import (
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    "github.com/fluxcd/pkg/apis/meta"
    "github.com/fluxcd/pkg/artifact/storage"
)

func (r *ArtifactGeneratorReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    // Create a new artifact descriptor.
    artifact := store.NewArtifactFor(
        "MySource",                    // kind
        &mySourceObject.ObjectMeta,    // metadata (namespace + name)
        revision,                      // e.g. "v1.0.0@sha256:abc123..."
        fmt.Sprintf("%s.tar.gz", hash),// filename
    )

    // Ensure the artifact directory exists.
    if err := store.MkdirAll(artifact); err != nil {
        return ctrl.Result{}, err
    }

    // Archive a directory into a tarball.
    // The filter excludes .git and other VCS directories.
    if err := store.Archive(&artifact, "/path/to/source/dir", nil); err != nil {
        return ctrl.Result{}, err
    }

    // At this point, artifact.Digest, artifact.Size, and
    // artifact.LastUpdateTime are automatically set by the SDK.
    return ctrl.Result{}, nil
}
```

### 6. Apply the ExternalArtifact status

After archiving, create or update the `ExternalArtifact` resource in the cluster.
The `ExternalArtifact` status must contain the artifact metadata so that
`kustomize-controller` and `helm-controller` can fetch and verify it:

```go
import (
    sourcev1 "github.com/fluxcd/source-controller/api/v1"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    "sigs.k8s.io/controller-runtime/pkg/client"
)

func (r *ArtifactGeneratorReconciler) reconcileExternalArtifact(ctx context.Context,
    name, namespace string, artifact meta.Artifact) error {

    ea := &sourcev1.ExternalArtifact{
        ObjectMeta: metav1.ObjectMeta{
            Name:      name,
            Namespace: namespace,
        },
    }

    _, err := ctrl.CreateOrUpdate(ctx, r.Client, ea, func() error {
        // Set the artifact status.
        ea.Status.Artifact = &artifact
        // Mark the ExternalArtifact as ready.
        ea.Status.Conditions = []metav1.Condition{
            {
                Type:               "Ready",
                Status:             metav1.ConditionTrue,
                LastTransitionTime: metav1.Now(),
                Reason:             "Succeeded",
                Message:            fmt.Sprintf("stored artifact for revision %s", artifact.Revision),
            },
        }
        return nil
    })
    return err
}
```

### 7. Implement garbage collection

The SDK provides built-in garbage collection based on retention TTL and
record count limits:

```go
import (
    "time"
    "github.com/fluxcd/pkg/artifact/storage"
)

func (r *ArtifactGeneratorReconciler) garbageCollect(ctx context.Context, artifact meta.Artifact) error {
    // GarbageCollect removes stale artifacts based on the
    // configured retention TTL and max records.
    deleted, err := store.GarbageCollect(ctx, artifact, 5*time.Minute)
    if err != nil {
        return err
    }
    if len(deleted) > 0 {
        log.Info("garbage collected artifacts", "count", len(deleted))
    }
    return nil
}
```

### 8. Verify artifact integrity

At startup, verify that artifacts in storage have not been tampered with:

```go
// Verify that the artifact on disk matches the expected digest.
if err := store.VerifyArtifact(artifact); err != nil {
    log.Error(err, "artifact integrity check failed")
    // Re-fetch or re-generate the artifact.
}
```

## Consuming ExternalArtifacts

Once your controller creates `ExternalArtifact` resources, Flux users can
reference them in `Kustomization` and `HelmRelease` resources.

### With Kustomization

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-app
  namespace: apps
spec:
  interval: 10m
  sourceRef:
    kind: ExternalArtifact
    name: my-app
  path: "./"
  prune: true
```

### With HelmRelease

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: my-chart
  namespace: apps
spec:
  interval: 10m
  releaseName: my-chart
  chartRef:
    kind: ExternalArtifact
    name: my-chart
```

## Storage API Reference

The `storage.Storage` type provides the following operations:

### Artifact Creation

| Method | Description |
|--------|-------------|
| `NewArtifactFor(kind, metadata, revision, fileName)` | Create a new `meta.Artifact` descriptor with URL |
| `MkdirAll(artifact)` | Create the artifact's base directory |
| `Archive(artifact, dir, filter)` | Archive a directory to a tarball with digest computation |
| `AtomicWriteFile(artifact, reader, mode)` | Atomically write content to the artifact path |
| `Copy(artifact, reader)` | Atomically copy reader content to the artifact path |
| `CopyFromPath(artifact, path)` | Atomically copy a file to the artifact path |

### Artifact Verification

| Method | Description |
|--------|-------------|
| `ArtifactExist(artifact)` | Check if an artifact exists in storage |
| `VerifyArtifact(artifact)` | Verify artifact integrity against its digest |
| `Lock(artifact)` | Create a file lock for the artifact |

### Artifact Cleanup

| Method | Description |
|--------|-------------|
| `Remove(artifact)` | Remove a single artifact file |
| `RemoveAll(artifact)` | Remove the artifact's entire directory |
| `RemoveAllButCurrent(artifact)` | Remove all files except the current artifact |
| `GarbageCollect(ctx, artifact, timeout)` | GC stale artifacts based on retention policy |

### Path and URL Helpers

| Method | Description |
|--------|-------------|
| `LocalPath(artifact)` | Secure local path of an artifact (relative to `BasePath`) |
| `SetArtifactURL(artifact)` | Set the HTTP URL on an artifact |
| `SetHostname(URL)` | Replace the hostname of a URL |
| `Symlink(artifact, linkName)` | Create or update a symlink for the artifact |
| `ArtifactPath(kind, ns, name, file)` | Generate an artifact path string |
| `ArtifactDir(kind, ns, name)` | Generate an artifact directory path string |

## Security Best Practices

When building 3rd-party controllers that generate `ExternalArtifact` resources,
follow these security guidelines from [RFC-0012](https://github.com/fluxcd/flux2/blob/main/rfcs/0012-external-artifact/README.md):

- **Authentication & Authorization**: Use `serviceAccountName` for workload
  identity, `secretRef` for long-lived credentials. Never cache credentials on
  disk or in-memory.
- **TLS Encryption**: Use `certSecretRef` for custom CA certificates. Prefer
  Mutual TLS authentication. Never skip TLS verification.
- **Provenance & Integrity**: Verify upstream artifacts using Sigstore Cosign
  or Notary Notation signatures. Prefer keyless verification with OIDC tokens.
- **Access Control**: Expose a `--no-cross-namespace-refs` flag to restrict
  cross-namespace `ExternalArtifact` generation. Use Kubernetes owner references
  for garbage collection.
- **Least Privilege**: Use a dedicated service account with minimal RBAC.
  Conform with the restricted pod security standard (no root, read-only rootfs).
- **Storage Integrity**: At startup, verify all stored artifact checksums
  against the `ExternalArtifact` digests in the cluster.
- **Network Policies**: Restrict artifact endpoint access to only
  `kustomize-controller` and `helm-controller`.

## Policy Enforcement

Cluster administrators can restrict which controllers can create
`ExternalArtifact` resources using `ValidatingAdmissionPolicy`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: "trusted-external-artifacts"
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups:   ["source.toolkit.fluxcd.io"]
      apiVersions: ["v1"]
      operations:  ["CREATE", "UPDATE"]
      resources:   ["externalartifacts"]
  validations:
    # Restrict the artifacts to be served only by trusted endpoints
    - expression: >
        !has(object.status.artifact) ||
        object.status.artifact.url.startsWith('http://my-controller.flux-system.svc.cluster.local./')
    # Restrict the artifact operations to trusted service accounts
    - expression: >
        request.userInfo.username == 'system:serviceaccount:flux-system:my-controller'
```

## Further Reading

- [ExternalArtifact API Reference](/flux/components/source/externalartifacts/)
- [RFC-0012: External Artifact](https://github.com/fluxcd/flux2/blob/main/rfcs/0012-external-artifact/README.md)
- [Artifact SDK Go Docs](https://pkg.go.dev/github.com/fluxcd/pkg/artifact)
- [Source Watcher Reference Implementation](https://github.com/fluxcd/source-watcher/tree/v2)
- [Watching for source changes](source-watcher.md)
