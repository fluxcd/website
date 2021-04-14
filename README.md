# fluxcd.io

[![Netlify Status](https://api.netlify.com/api/v1/badges/fe297324-1b1d-4d66-96f7-0f8cb1abbe84/deploy-status)](https://app.netlify.com/sites/fluxcd/deploys)

This repo houses the assets used to build the Flux project's landing page at <https://fluxcd.io>.

> **Note**: The sources for some of Flux's documentation are housed in the other Flux repositories within <https://github.com/fluxcd>. Issues and pull requests for this documentation should be registered at that repos.
>
> Project       | Docs Site                                        | Github Source
> ------------- | ------------------------------------------------ | -------------
> Flux v1       | <https://docs.fluxcd.io>                         | <https://github.com/fluxcd/flux>
> Helm Operator | <https://docs.fluxcd.io/projects/helm-operator/> | <https://github.com/fluxcd/helm-operator>
> Flux v2       | <https://fluxcd.io/docs>                         | <https://github.com/fluxcd/website>
>
> We are in the process of moving everything into this repository: `/fluxcd/website`. The work can be tracked here: <https://github.com/fluxcd/website/issues/76>.

## How to modify this website

The main landing page of this website can be modified in `config.toml`.

All other content lives in the `content` directory:

- `./content/en/blog` contains all blog posts - make sure you update the front-matter for posts to show up correctly.
- `./external-sources/` defines how files from other repositories are pulled in. We currently do this for Markdown files from the `/fluxcd/community` and `/fluxcd/.github` repositories. (`make gen-content` pulls these in.)
- Flux CLI docs (`cmd`) and `components` docs: under `./content/en/docs` but pulled in through in `make gen-content` as well.

## Running the site locally

In order to run the Flux site locally, you need to install:

- [Node.js](https://www.npmjs.com/get-npm)
- The [Hugo](https://gohugo.io) static site generator. Make sure to [install](https://gohugo.io/getting-started/installing/) the "extended" variant of Hugo with support for the [Hugo Pipes](https://gohugo.io/hugo-pipes/introduction/) feature and to check the [`netlify.toml`](./netlify.toml) configuration file for which version of Hugo you should install.

Once those tools are installed, fetch the assets necessary to run the site:

```cli
npm install
make theme
```

Then run the site in "server" mode:

```cli
make serve
```

Navigate to <http://localhost:1313> to see the site running in your browser. As you make updates to the site, the browser will immediately update to reflect those changes.

## Publishing the site

The Flux website is published automatically by [Netlify](https://netlify.com) when changes are pushed to the `main` branch. The site does not need to be published manually.

### Preview builds

When you submit a pull request to this repository, Netlify builds a "deploy preview" of your changes. You can see that preview by clicking on the **deploy/netlify** link in the pull request window.

### Local Development (docker)

Run `make docker-preview` a and wait until the following output appears:

```
Environment: "development"
Serving pages from memory
Web Server is available at //localhost:1313/ (bind address 0.0.0.0)
Press Ctrl+C to stop
```

Visit [http://localhost:1313](http://localhost:1313), changes will be visible from inside of the running container. Markdown files updated in `content/` should trigger the browser refresh when they are saved.

The `docker-preview` target builds the theme, which takes a while and doesn't need to be repeated unless you are making changes to the theme. On subsequent runs, `make docker-serve` if used can skip building the theme.

This depends on the Docker image `fluxcd/website:hugo-support` which should be kept updated when the website's build-time dependencies have changed; this image contains everything needed to run the docs locally.

If this doesn't work, the image may be stale. The instructions to update it are below.

### Remote Development (kubernetes / okteto CLI)

This works the same as local development above, but with the Okteto CLI you do not need to run a Linux machine or virtual machine on your local development environment.

First, make sure you are permitted to deploy pods on any local or remote Kubernetes cluster. Download the [Okteto CLI](https://okteto.com/docs/getting-started/installation/index.html) for Windows, Mac, or Linux.

Okteto CLI is another light-weight client-side tool that replaces Docker with a remote cluster. You can run `hugo server` remotely in this way; any changes to the local clone are synchronized to the cluster. The experience is basically the same as local development.

Instead of `make docker-serve`, type `okteto up`. You can change the behavior in `okteto.yml` according to the [Okteto Manifest Reference](https://okteto.com/docs/reference/manifest/index.html), for example adding a persistent volume to speed up the synchronization of the working directory to the remote pod on repeated runs.

### Updating the Development/preview container image

(For maintainers:) With a docker client, using an account that has permission to push to `docker.io/fluxcd/website` repo, run `make docker-push`.

The dependencies run by the `docker-push` target are explained below. If the above worked then you are done, and should not need to read below any further. Update this image whenever build-time dependencies have changed.

These targets as explained below are run in the appropriate order as dependencies of `make docker-push`.

`TODO`: add a system/integration test for `website` that verifies we have not broken `make docker-serve` by adding new dependencies without incorporating them in `docker-support/Dockerfile`.

The FluxCD.io website has some build-time dependencies including Python3, PyYAML, and others that are prepared in an image tagged as `docker.io/fluxcd/website:hugo-support`. This image is built from the `Dockerfile` in `docker-support/`; run `make docker-image` to rebuild it locally.

FluxCD also depends on a specific version of Hugo, which unfortunately does not provide docker images for each version. So we build it from source, with the `HUGO_BUILD_TAGS=extended` build arg enabled.

Run `make hugo` to get a clone of the `gohugoio/hugo` repository at the right `HUGO_VERSION` and `make docker-support` to build a hugo container base image. These are the dependencies of `make docker-image`. (The `docker-support` target compiles `golibsass` and may take a while.)
