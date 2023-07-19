---
title: GitHub Actions Basic App Builder
linkTitle: GitHub Actions Basic App Builder
description: "How to build and push image tags for Flux from Git branches and tags."
weight: 39
---

{{% alert color="warning" title="Disclaimer" %}}
This document is under review and may be declared out of scope for Flux.

Note that this guide needs further review in consideration of Flux v2.0.0. It also predates the introduction of `OCIRepository` and likely needs updates in consideration of those advancements.

Expect this doc to either be archived soon, or to receive some overhaul.
{{% /alert %}}

This guide shows how to configure GitHub Actions to build an image for each new commit pushed on a branch, for PRs, or for tags in the most basic way that Flux's automation can work with and making some considerations for both dev and production.

A single GitHub Actions workflow is presented with a few variations but one simple theme: Flux's only firm requirement for integrating with CI is for the CI to build and push an image. So this document shows how to do just that.

### Scope of this document

Strictly speaking Flux considers CI to be out-of-scope, but this answer frequently leads to bad experiences caused by over-complicated CI built for users who did not firmly grasp the minimum requirements that Flux demands from a supporting CI. This example is intended to cover a majority of use cases with the simplest possible CI workflow.

Users are not expected to strictly adopt this minimum viable solution or view this guidance as strongly prescriptive. You can adapt the example workflow for your use, and you can incorporate Flux's automation into your dev or production release machinery at a variety of critical points, mostly independent of one another.

We anticipate in this guide that Flux users who are developing one or more apps likely want two build strategies for each app: a **Dev** build generates a (not semantically versioned) tag from some feature or environment branch with the branch name, commit hash, and timestamp; and a **Release** build produces a [semantic version] tag from the release tag that preceded it.

You might want deployment automation in either or both environments, or perhaps neither. This guide shows how to generate image tags in a way that will be ready to work with Flux's automation for either or both of these scenarios.

How to configure an `ImageUpdateAutomation` resource to take advantage of Release or Dev builds with automation is covered separately in the [Image Update Guide] and [Sortable image tags] guide, respectively.

## Example GitHub Actions Workflow

tl;dr: This build workflow does everything that Flux needs. Drop it into `.github/workflows/docker-build.yml` and reap the benefits.

First copy this example and update `IMAGE` to point to your own image repository target. Then set `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` and you are done. Most git push events will now result in images suitable for Flux to deploy.

For a deeper understanding and some variations, see the remainder of the doc.

```yaml
name: Docker Build, Push

on:
  push:
    branches:
      - '*'
    tags-ignore:
      - 'release/*'

jobs:
  docker:
    env:
      IMAGE: kingdonb/any_old_app
    runs-on: ubuntu-latest
    steps:
      - name: Prepare
        id: prep
        run: |
          BRANCH=${GITHUB_REF##*/}
          TS=$(date +%s)
          REVISION=${GITHUB_SHA::8}
          BUILD_ID="${BRANCH}-${REVISION}-${TS}"
          LATEST_ID=canary
          if [[ $GITHUB_REF == refs/tags/* ]]; then
            BUILD_ID=${GITHUB_REF/refs\/tags\//}
            LATEST_ID=latest
          fi
          echo BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') >> $GITHUB_OUTPUT
          echo BUILD_ID=${BUILD_ID} >> $GITHUB_OUTPUT
          echo LATEST_ID=${LATEST_ID} >> $GITHUB_OUTPUT


      - name: Set up QEMU
        uses: docker/setup-qemu-action@v2

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to DockerHub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push
        id: docker_build
        uses: docker/build-push-action@v4
        with:
          push: true
          tags: |
            ${{ env.IMAGE }}:${{ steps.prep.outputs.BUILD_ID }}
            ${{ env.IMAGE }}:${{ steps.prep.outputs.LATEST_ID }}

      - name: Image digest
        run: echo ${{ steps.docker_build.outputs.digest }}
```

This workflow incorporates a few key concepts and properties which are important for Flux.

### Workflow Event Triggers

There are two paths through this flow: when a commit is pushed to any branch and when a commit is pushed to any tag, with some exceptions possible as shown with `tags-ignore:` – this example is given in case you are using the `release/*` tags as shown in the [Jsonnet Render Action] example.

These workflows are executed by GitHub Actions on the `push` event for any branches and tags we specify.

```yaml
on:
  push:
    branches:
      - '*'
    tags-ignore:
      - 'release/*'
```

You may want to invert or adjust these patterns depending on how you are using branches, image tags, and git tags. Flux is not prescriptive about any of this. Maybe you only build tags that match a certain pattern, or only commits on the `main` branch, depending on the need. Some variations are expected and they are out of scope for this guide.

Now let's walk through the rest of this example workflow.

### Docker Build job

The workflow has one job with the id `docker` whose purpose is to turn commits from push events into deployable images.

An individual image tag name (string) has two parts, `IMAGE` which represents the image name that is common for all images in the same project, and following that image name separated by a colon is a `tag` which uniquely identifies a revision of the image. Repositories can hold many tags, and tags can utilize various forms and formats.

#### Mutable vs. Immutable tags

Image tags can be mutable or immutable. Flux works best with immutable tags: `latest` and `canary` are examples of mutable tags.

This example produces both mutable and immutable tags because Flux works with immutable tags, but many users still expect a `latest` tag even if Flux won't be able to take advantage of it. Mutable tags are useful for example with environment branches, to stably represent the latest build in a named environment, but their use is generally contrary to GitOps principles. Flux automation demands immutable tags, with a timestamp or something else sortable in the tag string. Thus mutable tags alone are not suitable for most purposes in Flux.

In this example, `LATEST_ID` represents a mutable tag and `latest` as a tag represents the last release build that was pushed from any Git tag. The `canary` tag is the last image that was pushed from any branch.

`BUILD_ID` represents the immutable tag in both the dev and release path. This is either a literal tag string from Git tag (Flux works best with semver tags) or a `${BRANCH}-${REVISION}-${TS}` in this build workflow.

The mutable tags `canary` and `latest` are chosen by the script depending on which event triggered the build. If the image is built from a tag, the `latest` tag is used. If it is built from a branch, `canary` is used instead. These tags will therefore always point at the "latest" release tag and the latest "canary" however you define it.

This example shows one useful convention among many possible uses for mutable image tags.

Another sensible choice could be to build and push canary images only from the `main` branch. This script can be as elaborate as you want, the important logic is all contained in the shell script embedded in the `Prepare` step:

### Prepare Step

```yaml
  steps:
  - name: Prepare
    id: prep
    run: |
      BRANCH=${GITHUB_REF##*/}
      TS=$(date +%s)
      REVISION=${GITHUB_SHA::8}
      BUILD_ID="${BRANCH}-${REVISION}-${TS}"
      LATEST_ID=canary
      if [[ $GITHUB_REF == refs/tags/* ]]; then
        BUILD_ID=${GITHUB_REF/refs\/tags\//}
        LATEST_ID=latest
      fi
      echo BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') >> $GITHUB_OUTPUT
      echo BUILD_ID=${BUILD_ID} >> $GITHUB_OUTPUT
      echo LATEST_ID=${LATEST_ID} >> $GITHUB_OUTPUT
```

This script has no external effects, it only takes some inputs from environment variables set by GitHub Actions and calculates them into several outputs: `BUILD_ID` and `LATEST_ID`. The `BUILD_DATE` is also exported as an output for informational purposes and is not used elsewhere in the workflow.

`TS` is the Unix timestamp in seconds, a monotonically increasing value that represents when the build got scheduled. This lets us reliably determine what build is actually latest, even when some builds may take longer or shorter.

{{% alert title="Use Immutable Tags" %}}
This section highlights another advantage of Flux's requirement for using timestamped tags instead of a mutable `latest` tag, in which case the longest build (and not necessarily the latest promoted build) can occasionally win out.
{{% /alert %}}

`REVISION` is the first 8 characters of the `GITHUB_SHA`, a fingerprint that is kept for humans to differentiate more easily between tags strings that are very similar. It is not meaningful for Flux and can be omitted if preferred. Only `TIMESTAMP` has any function as it is needed to create an `ImagePolicy` (reference: [Sortable image tags]).

### Dependencies Setup

These steps prepare the build environment with QEMU and Docker:

```yaml
      - name: Set up QEMU
# ...
      - name: Set up Docker Buildx
```

### DockerHub Login

Secrets for your container registry with read and write access can be added in GitHub as [Encrypted secrets] and retrieved for use when pushing images.

```yaml
      - name: Login to DockerHub
# ...
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
```

If the GitHub Container Registry ([GHCR.io][Working with GHCR]) is used, users can skip encrypting secrets and use the `write:packages` scope with ambient `GITHUB_TOKEN` instead. The [Docker Login action] has more specific instructions.

### Build and push tag(s)

Now that Docker is logged in, a generic build and push is invoked, pushing both a mutable and an immutable image tag:

```yaml
      - name: Build and push
        id: docker_build
# ...
        with:
          push: true
          tags: |
            ${{ env.IMAGE }}:${{ steps.prep.outputs.BUILD_ID }}
            ${{ env.IMAGE }}:${{ steps.prep.outputs.LATEST_ID }}
```

An image digest is printed at the end for information.

```yaml
      - name: Image digest
        run: echo ${{ steps.docker_build.outputs.digest }}
```

### Further Reading on CI

In [Image Update Guide] we can see how Flux's image update automation works with these image tags. In the [GitHub Actions Manifest Generation] guide, we see more CI workflows that go even further, rendering manifests in CI and committing them back to Git.

Some of those techniques are quite advanced beyond what is actually needed to work with Flux, but those suggested readings may clarify some of what other possibilities there are for Flux to work with different automation.

In general these approaches all embrace Git as a single source of truth, either pushing their updated truth as a new input for a standard GitOps deployment, or using another Git target as an intermediate store that still derives from GitOps intents declared further upstream. So automation can push directly back to a default branch, or we can configure Flux to [Push updates to a different branch] than the one used for checkout.

When Flux pushes directly to a default branch, those changes are deployed automatically on the next reconcile, or immediately with [Webhook Receivers]. When pushing to a different branch the [GitHub Actions Auto Pull Request] workflow is another option that can be used to keep some automation with manual control. The developers or other project stakeholders can then merge a PR that automation generated in order to manually promote the change in an automated way.

Further expansion on a more intricate design for CI that does any more than what Flux demands is out of scope. Some useful ideas for further enhancement in the scope of CI beyond this scope boundary are suggested nonetheless below.

#### Image Provenance Security

This guide does not cover or implement Image Provenance or any cryptographic signature, but Flux does provide examples of those workflows as they are implemented in Flux's own controllers!

Another exercise for the reader to implement after this basic builder could be implementing Cosign for cryptographically proving the image provenance as described in [Security: Image Provenance].

#### Caching for Fast Builds

One last bit of general parting guidance: Flux's deploy automation is designed to be scalable and fast. To make the developer experience good requires fast CI builds as well. Slow CI builds detract sharply from the experience; the faster the better as more time waiting for feedback from a build adds to cognitive load and context switching. Greater time spent waiting for CI/CD can unfortunately have outsized impacts on focus depletion and developer productivity.

The build result may provide test-driven feedback to support fast iteration for high-functioning rapid delivery teams. An average time of longer than 5 minutes to get that feedback may already be too long. If your CI builds for iterative development are taking much longer than 5 minutes, it's a good idea to start to consider some approaches to make them faster.

A skillfully designed `Dockerfile` can help provide some relief for builds that are too slow with heavyweight prerequisites that necessarily take a long time to build. Arranging your build order so the slow parts that change less frequently are built first, or in a separate staging, means they can be cached and repeated only as often as they change.

This is one good fundamental approach to reduce build times. On the topic of caching, more information that goes with this example is provided in the [docker/build-push-action Cache] documentation.

[semantic version]: /contributing/flux/#semantic-versioning
[Image Update Guide]: /flux/guides/image-update/
[Sortable image tags]: /flux/guides/sortable-image-tags/
[Jsonnet Render Action]: /flux/use-cases/gh-actions-manifest-generation/#jsonnet-render-action
[Encrypted secrets]: https://docs.github.com/en/actions/security-guides/encrypted-secrets
[Working with GHCR]: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
[Docker Login action]: https://github.com/docker/login-action#github-container-registry
[GitHub Actions Manifest Generation]: /flux/use-cases/gh-actions-manifest-generation/
[Push updates to a different branch]: /flux/guides/image-update/#push-updates-to-a-different-branch
[Webhook Receivers]: /flux/guides/webhook-receivers/
[GitHub Actions Auto Pull Request]: /flux/use-cases/gh-actions-auto-pr/
[Security: Image Provenance]: /blog/2022/02/security-image-provenance/
[docker/build-push-action Cache]: https://github.com/docker/build-push-action/blob/master/docs/advanced/cache.md
