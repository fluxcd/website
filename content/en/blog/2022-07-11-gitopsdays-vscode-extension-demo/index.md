---
author: 'kingdonb'
date: 2022-07-11 14:30:00+00:00
title: 'GitOps Days - VSCode Extension Demo'
description: 'If you want GitOps in your IDE, check out this post and video from Kingdon who presented the GitOps VSCode Extension at the recent GitOps Days event.'
url: /blog/2022/07/gitopsdays-vscode-extension-demo/
tags: [event]
resources:
- src: "**.{jpg,png}"
  title: "Image #:counter"
---

Helping to close out GitOps Days 2022, Kingdon Barrett, OSS Engineer
at Weaveworks, Flux Maintainer, and maintainer of the Weaveworks 
[GitOps Tools extension for VSCode](https://github.com/weaveworks/vscode-gitops-tools) 
presented the new Flux extension. Kingdon showed the new extension and 
how it helps minimize context switching, keeping you in your editor 
where you can be most productive!

{{< imgproc vscode-gitops-commands Resize 800x >}}
{{< /imgproc >}}

The presentation starts down in the trenches after
Kingdon launched the new VSCode [Extension
Marketplace](https://marketplace.visualstudio.com/items?itemName=Weaveworks.vscode-gitops-tools)
page and soft-launched the extension's availability to install from the
store the night before, and fully launching the marketplace entry during
the conference only a few hours earlier!

The VSCode extension is still considered a prerelease even though it's
been available for some time and is in the store now. Since the
extension was first launched outside of the marketplace its development
was hampered with low usage and low discoverability. He wanted to avoid
launching with glaring usability issues and ensure that integration with
Flux was a tight fit. Ultimately several key usability issues have been
addressed since the alpha extension was demonstrated in an earlier
state, and he decided that GitOpsDays was going to be a great time to
formally launch the extension in the store!

The addition of a Flux status widget in the VSCode editor makes
monitoring the changes as Flux automatically deploys without leaving the
comfort of your editor window a total snap.

When Flux detects an issue in your manifest and the deployment fails,
the editor extension shines most brightly as you can see the error and
the condition status in a mouse-over hover panel above the resources
that are having issues.

This quick demonstration gives an overview of the GitOps extension for
Flux, and also what it's like to use the extension to help recover when
things have gone wrong. What kind of live demo is it if nothing went
wrong? (Hint...an unrealistic one, as something always goes
wrong!) These tools make recovery fast and ensure you can do it without
a heavy context switch out of the editor and into monitoring dashboards
or terminal CLI debugging land.

If you want to try it out, just search "GitOps" or "FluxCD" in the
extension marketplace! The new VSCode extension is available right now,
in the marketplace, no compiler necessary.

If you're already familiar with the VSCode Kubernetes extension then
you'll be happy to know the configuration of both are identical, as the
Flux VSCode extension just uses your KUBECONFIG there is nothing else to
configure, so you can start using the extension to help manage your
workloads and avoid unnecessary context switching in your day to day!

Here's the video in its entirety if you'd like to watch from start to
finish:

{{% youtube QRZTc6hlCjI %}}

### Next Steps

The GitOps Days team will be publishing more blog posts along with videos
from the event to the [GitOps Days 2022
Playlist](https://youtube.com/playlist?list=PL9lTuCFNLaD0NVkR17tno4X6BkxsbZZfr),
so stay tuned for more as they become available. And don't forget to
[subscribe to the YouTube
channel](https://www.youtube.com/channel/UCmIz9ew1lA3-XDy5FqY-mrA?sub_confirmation=1)!
