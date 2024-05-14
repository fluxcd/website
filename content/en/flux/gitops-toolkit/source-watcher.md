---
title: "Watching for source changes"
linkTitle: "Watching for source changes"
description: "Develop a Kubernetes controller that reacts to source changes."
weight: 20
---

In this guide you'll be developing a Kubernetes controller with
[Kubebuilder](https://github.com/kubernetes-sigs/kubebuilder)
that subscribes to [GitRepository](/flux/components/source/gitrepositories/)
events and reacts to revision changes by downloading the artifact produced by
[source-controller](/flux/components/source/).

## Prerequisites

On your dev machine install the following tools:

* go >= 1.22
* kubebuilder >= 3.0
* kind >= 0.22
* kubectl >= 1.29

## Install Flux

Install the Flux CLI with Homebrew on macOS or Linux:

```sh
brew install fluxcd/tap/flux
```

Create a cluster for testing:

```sh
kind create cluster --name dev
```

Verify that your dev machine satisfies the prerequisites with:

```sh
flux check --pre
```

Install source-controller on the dev cluster:

```sh
flux install \
--namespace=flux-system \
--network-policy=false \
--components=source-controller
```

## Clone the sample controller

You'll be using [fluxcd/source-watcher](https://github.com/fluxcd/source-watcher) as
a template for developing your own controller. The source-watcher was scaffolded with `kubebuilder init`.

Clone the source-watcher repository:

```sh
git clone https://github.com/fluxcd/source-watcher
cd source-watcher
```

Build the controller:

```sh
make
```

## Run the controller

Port forward to source-controller artifacts server:

```sh
kubectl -n flux-system port-forward svc/source-controller 8181:80
```

Export the local address as `SOURCE_CONTROLLER_LOCALHOST`:

```sh
export SOURCE_CONTROLLER_LOCALHOST=localhost:8181
```

Run source-watcher locally:

```sh
make run
```

Create a Git source:

```sh
flux create source git test \
--url=https://github.com/fluxcd/flux2 \
--ignore-paths='/*,!/manifests' \
--tag=v2.2.0
```

The source-watcher will log the revision:

```sh
{"level":"info","ts":"2024-05-14T16:43:42.703+0200","msg":"New revision detected","controller":"gitrepository","controllerGroup":"source.toolkit.fluxcd.io","controllerKind":"GitRepository","GitRepository":{"name":"test","namespace":"flux-system"},"namespace":"flux-system","name":"test","reconcileID":"ef0fe80e-3952-4835-ae9d-01760c4eadde","revision":"v2.2.0@sha1:81606709114f6d16a432f9f4bfc774942f054327"}
```

Change the Git tag:

```sh
flux create source git test \
--url=https://github.com/fluxcd/flux2 \
--ignore-paths='/*,!/manifests' \
--tag=v2.3.0
```

And source-watcher will log the new revision:

```sh
{"level":"info","ts":"2024-05-14T16:51:33.499+0200","msg":"New revision detected","controller":"gitrepository","controllerGroup":"source.toolkit.fluxcd.io","controllerKind":"GitRepository","GitRepository":{"name":"test","namespace":"flux-system"},"namespace":"flux-system","name":"test","reconcileID":"cc0f83bb-b7a0-4c19-a254-af9962ae39cd","revision":"v2.3.0@sha1:658925c2c0e6c408597d907a8ebee06a9a6d7f30"}
```

The source-controller reports the revision under `GitRepository.Status.Artifact.Revision` in the format: `<branch|tag>@sha1:<commit>`.

## How it works

The [GitRepositoryWatcher](https://github.com/fluxcd/source-watcher/blob/main/controllers/gitrepository_watcher.go)
controller does the following:

* subscribes to `GitRepository` events
* detects when the Git revision changes
* downloads and extracts the source artifact
* writes the extracted dir names to stdout

```go
type GitRepositoryWatcher struct {
	client.Client
	HttpRetry       int
	artifactFetcher *fetch.ArchiveFetcher
}

func (r *GitRepositoryWatcher) SetupWithManager(mgr ctrl.Manager) error {
	r.artifactFetcher = fetch.NewArchiveFetcher(
		r.HttpRetry,
		tar.UnlimitedUntarSize,
		os.Getenv("SOURCE_CONTROLLER_LOCALHOST"),
	)

	return ctrl.NewControllerManagedBy(mgr).
		For(&sourcev1.GitRepository{}, builder.WithPredicates(GitRepositoryRevisionChangePredicate{})).
		Complete(r)
}

// +kubebuilder:rbac:groups=source.toolkit.fluxcd.io,resources=gitrepositories,verbs=get;list;watch
// +kubebuilder:rbac:groups=source.toolkit.fluxcd.io,resources=gitrepositories/status,verbs=get

func (r *GitRepositoryWatcher) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	log := ctrl.LoggerFrom(ctx)

	// get source object
	var repository sourcev1.GitRepository
	if err := r.Get(ctx, req.NamespacedName, &repository); err != nil {
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}

	artifact := repository.Status.Artifact
	log.Info("New revision detected", "revision", artifact.Revision)

	// create tmp dir
	tmpDir, err := os.MkdirTemp("", repository.Name)
	if err != nil {
		return ctrl.Result{}, fmt.Errorf("failed to create temp dir, error: %w", err)
	}
	defer os.RemoveAll(tmpDir)

	// download and extract artifact
	if err := r.artifactFetcher.Fetch(artifact.URL, artifact.Digest, tmpDir); err != nil {
		log.Error(err, "unable to fetch artifact")
		return ctrl.Result{}, err
	}

	// list artifact content
	files, err := os.ReadDir(tmpDir)
	if err != nil {
		return ctrl.Result{}, fmt.Errorf("failed to list files, error: %w", err)
	}

	// do something with the artifact content
	for _, f := range files {
		log.Info("Processing " + f.Name())
	}

	return ctrl.Result{}, nil
}
```

To add the watcher to an existing project, copy the controller and the revision change predicate to your `controllers` dir:

* [gitrepository_watcher.go](https://github.com/fluxcd/source-watcher/blob/main/controllers/gitrepository_watcher.go)
* [gitrepository_predicate.go](https://github.com/fluxcd/source-watcher/blob/main/controllers/gitrepository_predicate.go)

In your `main.go` init function, register the Source API schema:

```go
import (
	utilruntime "k8s.io/apimachinery/pkg/util/runtime"
	clientgoscheme "k8s.io/client-go/kubernetes/scheme"

	sourcev1 "github.com/fluxcd/source-controller/api/v1"
)

func init() {
	utilruntime.Must(clientgoscheme.AddToScheme(scheme))
	utilruntime.Must(sourcev1.AddToScheme(scheme)

	// +kubebuilder:scaffold:scheme
}
```

Start the controller in the main function:

```go
func main()  {

	if err = (&controllers.GitRepositoryWatcher{
		Client:    mgr.GetClient(),
		HttpRetry: httpRetry,
	}).SetupWithManager(mgr); err != nil {
		setupLog.Error(err, "unable to create controller", "controller", "GitRepositoryWatcher")
		os.Exit(1)
	}

}
```

Note that the watcher depends on Flux [runtime](https://pkg.go.dev/github.com/fluxcd/pkg/runtime)
and Kubernetes [controller-runtime](https://pkg.go.dev/sigs.k8s.io/controller-runtime):

```go
require (
    github.com/fluxcd/pkg/runtime v0.47.1
    sigs.k8s.io/controller-runtime v0.18.2
)
```

That's it! Happy hacking!
