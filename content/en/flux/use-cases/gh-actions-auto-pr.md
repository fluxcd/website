---
title: GitHub Actions Auto Pull Request
linkTitle: GitHub Actions Auto PR
description: "How to configure GitHub Pull Requests for Flux image updates."
weight: 50
---

{{% alert color="warning" title="Disclaimer" %}}
Note that this guide needs review in consideration of Flux v2.0.0, and likely needs to be refreshed.

Expect this doc to either be archived soon, or to receive some overhaul.
{{% /alert %}}

This guide shows how to configure GitHub Actions to open a pull request whenever a selected branch is pushed.

From [Image Update Guide] we saw that Flux can set `.spec.git.push.branch` to [Push updates to a different branch] than the one used for checkout.

Configure an `ImageUpdateAutomation` resource to push to a target branch, where we can imagine some policy dictates that updates must be staged and approved for production before they can be deployed.

```yaml
kind: ImageUpdateAutomation
metadata:
  name: flux-system
spec:
  git:
    checkout:
      ref:
        branch: main
    push:
      branch: staging
```

We can show that the automation generates a change in the `staging` branch which, once the change is approved and merged, gets deployed into production. The image automation is meant to be gated behind a pull request approval workflow, according to policy you may have in place for your repository.

To create the pull request whenever automation creates a new branch, in your manifest repository, add a GitHub Action workflow as below. This workflow watches for the creation of the `staging` branch and opens a pull request with any desired labels, title text, or pull request body content that you configure.

```yaml
# ./.github/workflows/staging-auto-pr.yaml
name: Staging Auto-PR
on:
  create:
    branches: ['staging']

jobs:
  pull-request:
    name: Open PR to main
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
      name: checkout

    - uses: repo-sync/pull-request@v2
      name: pull-request
      with:
        destination_branch: "main"
        pr_title: "Pulling ${{ github.ref }} into main"
        pr_body: ":crown: *An automated PR*"
        pr_reviewer: "kingdonb"
        pr_draft: true
        github_token: ${{ secrets.GITHUB_TOKEN }}
```

You can use the [GitHub Pull Request Action] workflow to automatically open a pull request against a destination branch. When `staging` is merged into the `main` branch, changes are deployed in production. Be sure to delete the branch after merging so that the workflow runs the next time that the image automation finds something to change.

{{% alert title="Additional options" %}}
The "GitHub Pull Request Action" reference linked above documents more options, like `pr_reviewer` and `pr_assignee`, that setting will help make this workflow more usable. You can assign reviewers, labels, (use markdown emojis in the `pr_body`, make variable substitutions in the title, etc.)
{{% /alert %}}

The [Create Pull Request Action] action might be a viable option to use instead, in case it's necessary to make some scripted edits in the same workflow (eg. manifest generation routines.)

With your own scripts, manifests can be updated with any current tags to make the staging branch ready for deployment. The "Create Pull Request" workflow can find and commit any updates for you.

This way you can automatically push changes to a `staging` branch and require review with manual approval of any automatic image updates, before they are applied on your production clusters.

Experiment with these strategies to find the right automated workflow solution for your team!

[Image Update Guide]: /flux/guides/image-update/
[Push updates to a different branch]: /flux/guides/image-update/#push-updates-to-a-different-branch
[GitHub Pull Request Action]: https://github.com/marketplace/actions/github-pull-request-action
[Create Pull Request Action]: https://github.com/marketplace/actions/create-pull-request
