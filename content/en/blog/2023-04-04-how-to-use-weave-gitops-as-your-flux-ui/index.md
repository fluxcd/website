---
author: dholbach
date: 2023-04-04 08:30:00+00:00
title: How to use Weave GitOps as your Flux UI
description: "User of Flux have been asking for a Flux UI for a long time. Weave GitOps fills that gap and does lots more. Check out this post in our Flux Ecosystem series and learn about its other features, including 'GitOps Run' which you can see in the demo."
url: /blog/2023/04/how-to-use-weave-gitops-as-your-flux-ui/
tags: [ecosystem]
resources:
- src: "**.{png,jpg}"
  title: "Image #:counter"
---

Here comes the newest blog post in our [ecosystem category](/tags/ecosystem/).
One of the key reasons to rewrite Flux was to break up the former monolith
solution into separate controllers which provide distinct parts of the
functionality. This allows users to pick just the parts they need, and
integrators to very easily build on top of Flux's APIs. Today we have a very
active [Flux Ecosystem](/ecosystem/) - we very much welcome this to happen and
see it as an indicator of success.

## An introduction to Weave GitOps

Today we would like to talk about [Weave
GitOps](https://github.com/weaveworks/weave-gitops). It has
been built out in the open for about a year and brings among other
things one of the most requested additions to Flux: a UI.

{{< gallery match="wego*.png" sortOrder="desc" rowHeight="150" margins="5"
            thumbnailResizeOptions="600x600 q90 Lanczos"
            previewType="color" embedPreview=true >}}

<br>

With Weave GitOps you

- manage and view applications all in one place
- easily see your continuous deployments and what is being produced
  via GitOps
- sync your latest git commits directly from the UI
- leverage Kubernetes RBAC to control permissions in the dashboard
- quickly see the health of your reconciliation deployment runtime

The Weave GitOps team works very closely together with the Flux
Community - many engineers on both teams are actually colleagues.

In addition to the UI Weave GitOps provides a frictionless way
to get up to speed with your GitOps experience: [GitOps
Run](https://docs.gitops.weave.works/docs/gitops-run/overview/).
All you need to get started is a cluster and the Weave GitOps CLI.
Everything else, including Flux and the Weave GitOps Dashboard will be
set up automatically for you.

GitOps Run actually does more than the setup. You see changes sync
almost in real time instead of the normal loop, where everything goes
through a PR process, enabling you to iterate very quickly without
sacrificing the GitOps pattern. The moment you are happy with the
changes you create a PR just as usual. It's the best of both worlds.

Watch this short video to see the beauty and ease of use: set up

{{< youtube id=2TJz7RhDtAc >}}

If you are a Terraform user, you will love that the terraform-controller
is integrated by default and your terraform resources will show up in
the dashboard as well.

## Getting Started

Using GitOps Run as shown in the video above is the easiest way to get
set up. Period.

Here is an example of how to get an app deployment set up using GitOps
(powered by Flux), including the dashboard.

1. `brew install fluxcd/tap/flux`
1. Head to [podinfo](https://github.com/stefanprodan/podinfo)
   and create a fork with the name `podinfo-gitops-run`.
1. Clone locally and change into the directory

   ```cli
   export GITHUB_USER=<your github username>
   # you can ignore these two commands if you already created and
   # cloned your repository
   git clone git@github.com:$GITHUB_USER/podinfo-gitops-run.git
   cd podinfo-gitops-run
   ```

1. Now run the `gitops` command with `--no-session` as it's a single user
   cluster which we want to use in direct mode. The port-forward
   points at the `podinfo` pod we will create later on.

   ```cli
   gitops beta run ./podinfo --no-session \
       --port-forward namespace=dev,resource=svc/backend,port=9898:9898
   ```

   The other arguments denote a directory where the manifests are
   going to be stored and we set up port-forwarding for the
   application we are about to install.
1. During the installation process, Flux will be installed if it isn't
   and you will now be asked if you want to install the GitOps
   [dashboard](https://docs.gitops.weave.works/docs/getting-started/intro/).
   Answer `yes` and **set a password**.

   Note: If you do not set a password, you won't be able to login to
   the GitOps UI 😱.

   Shortly after you should be able to [open the
   dashboard](http://localhost:9001). The username is `admin` and the
   password will be the one you set above.
1. If you check the contents of the podinfo directory, you will notice
   a `kustomization.yaml` file. Edit the resources element to list
   `"../deploy/overlays/dev"` as well. It should like below:

    ```yaml
    ---
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    name: dev-podinfo
    resources: [
     "../deploy/overlays/dev"
    ]
    ```

If you save the file, podinfo will be deployed and able to access it at
<http://localhost:9898>.

There's more: if you Ctrl-C the running "gitops" process in the
terminal, you will be asked if you want to change the deployment to be
in "GitOps mode", this means that the manifests for the cluster
definition and dashboard will be added as well and pushed to GitHub for
you.

As you can see, Weave GitOps takes care of a lot of the repetitive tasks
and heavy lifting. A beautiful way to get set up and know that Flux is
doing everything behind the scenes for you.

## Is there more?

There is an [Enterprise version of Weave
GitOps](https://docs.gitops.weave.works/docs/intro-ee/) as
well, so if you need professional support for everything mentioned
above, you will be covered. In addition to that, you get advanced
features, such as templates and GitOpsSets - these are what will enable
you to create a self-service for application teams.

The Weave GitOps team is very friendly and are always happy to help and
receive feedback. Just join them in the `#weave-gitops` channel on the
[Weave Users Slack](https://slack.weave.works).

## Come and talk to us

If you have feedback to this story, let us know on Slack or on social
media and if you have a story to tell yourself, come find us as well -
you can also hit us up on the [fluxcd.io website
repository](https://github.com/fluxcd/website/). We want to
report more stories from our ecosystem and Flux success stories. Thanks
in advance for reaching out!
