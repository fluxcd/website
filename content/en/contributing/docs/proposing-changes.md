---
title: Proposing changes
weight: 5
description: >
   How to propose pull requests using either the GitHub UI or `git` locally.
---

## Getting started

1. Familiarize yourself with the [documentation repository](https://github.com/fluxcd/website) and the website's static site generator (Hugo).
1. Understand the process for opening a pull request and reviewing changes

## Opening a pull request

To contribute new pages or improve existing pages, open a pull request (PR).

If your change is small, or you're unfamiliar with git, read [Changes using GitHub](#Changes-using-GitHub).

### Changes using GitHub

If you're less experienced with git workflows, here's an easier method of opening a pull request.

{{% alert title="Maintainer Warning" color="warning" %}}
If you are a maintainer of the repo, the edit page button will not let you work off a fork, as you have write permission.
{{% /alert %}}

1. On the page you want to modify, select the pencil icon at the top right.
1. Make your changes in the GitHub markdown editor.
1. Below the editor, fill in the **Propose file change** form.

   In the first field, give your commit message a title.
   In the second field provide a description
   {{% alert title="Warning" color="warning" %}}
   Do not use any [GitHub Keywords](https://help.github.com/en/github/managing-your-work-on-github/linking-a-pull-request-to-an-issue#linking-a-pull-request-to-an-issue-using-a-keyword)
   in your commit message. You can add those to the pull request description later.
   {{% /alert %}}

1. Select **Propose file change**.
1. Select **Create pull request**.
1. The **Open a pull request** screen appears. Fill in the form:

   - The **Subject** field of the pull request defaults to the commit summary.
     You can change it if needed.
   - The **Body** contains your extended commit message, if you have one,
     and some template text. Add the
     details the template text asks for, then delete the extra template text.
   - Leave the **Allow edits from maintainers** checkbox selected.

   {{% alert title="" color="info" %}}
   PR descriptions are a great way to help reviewers understand your change. For more information, see [Opening a PR](#open-a-pr).
   {{% /alert %}}

1. Select **Create pull request**.

### Addressing feedback in GitHub

Before merging a pull request, community members review and approve it.

If a reviewer asks you to make changes:

1. Go to the **Files changed** tab.
2. Select the pencil (edit) icon on any files changed by the pull request.
3. Make the changes requested.
4. Commit the changes.

### Work from a local fork

If you're more experienced with git, or if your changes are larger than a few lines, work from a local fork.

#### Fork the fluxcd/website repository

1. Navigate to the [`fluxcd/website`](https://github.com/fluxcd/website/) repository.
1. Select **Fork**.
1. Navigate to the new `website` directory. Set the `fluxcd/website` repository as the `upstream` remote:

   ```bash
   cd website

   git remote add upstream https://github.com/fluxcd/website.git
   ```

1. Confirm your `origin` and `upstream` repositories:

   ```bash
   git remote -v
   ```

   Output is similar to:

   ```bash
   origin    git@github.com:<github_username>/website.git (fetch)
   origin    git@github.com:<github_username>/website.git (push)
   upstream  https://github.com/fluxcd/website.git (fetch)
   upstream  https://github.com/fluxcd/website.git (push)
   ```

1. Fetch commits from your fork's `origin/main` and `fluxcd/website`'s `upstream/main`:

   ```bash
   git fetch origin
   git fetch upstream
   ```

   This makes sure your local repository is up to date before you start making changes.

1. Create a new branch based on `upstream/main`:

    ```bash
    git checkout -b <my_new_branch> upstream/main
    ```

1. Make your changes using a text editor.

At any time, use the `git status` command to see what files you've changed.

#### Commit your changes

When you are ready to submit a pull request, commit your changes.

1. In your local repository, check which files you need to commit:

   ```bash
   git status
   ```

   Output is similar to:

   ```bash
   On branch <my_new_branch>
   Your branch is up to date with 'origin/<my_new_branch>'.

   Changes not staged for commit:
   (use "git add <file>..." to update what will be committed)
   (use "git checkout -- <file>..." to discard changes in working directory)

   modified:   content/en/contribute/new-content/run-locally.md

   no changes added to commit (use "git add" and/or "git commit -a")
   ```

1. Add the files listed under **Changes not staged for commit** to the commit:

   ```bash
   git add <your_file_name>
   ```

   Repeat this for each file.

1. After adding all the files, create a commit:

   ```bash
   git commit -sm "Your commit message"
   ```

   {{< alert >}}
   Do not use any [GitHub Keywords](https://help.github.com/en/github/managing-your-work-on-github/linking-a-pull-request-to-an-issue#linking-a-pull-request-to-an-issue-using-a-keyword) in your commit message. You can add those to the pull request
   description later.
   {{< /alert >}}

1. Push your local branch and its new commit to your remote fork:

    ```bash
    git push origin <my_new_branch>
    ```

#### Open a pull request from your fork to fluxcd/website

1. In a web browser, go to the [`fluxcd/website`](https://github.com/fluxcd/website/) repository.
1. Navigate to pull requests and select New pull request
1. Select compare across forks
1. From the **head repository** drop-down menu, select your fork.
1. From the **compare** drop-down menu, select your branch.
1. Select **Create Pull Request**.
1. Add a description for your pull request:
    - **Title** (50 characters or less): Summarize the intent of the change.
    - **Description**: Describe the change in more detail.
      - If there is a related GitHub issue, include `Fixes #12345` or `Closes #12345` in the description. GitHub's automation closes the mentioned issue after merging the PR if used. If there are other related PRs, link those as well.
      - If you want advice on something specific, include any questions you'd like reviewers to think about in your description.
1. Select the **Create pull request** button.

  Congratulations! Your pull request is available in [Pull requests](https://github.com/fluxcd/website/pulls).

#### Addressing feedback locally

1. After making your changes, amend your previous commit:

   ```bash
   git commit -as --amend
   ```

   - `-as`: commits all changes and adds your signoff
   - `--amend`: amends the previous commit, rather than creating a new one

1. Update your commit message if needed.

1. Use `git push origin <my_new_branch>` to push your changes and re-run the Netlify tests.

#### Changes from reviewers

Sometimes reviewers commit to your pull request. Before making any other changes, fetch those commits.

1. Fetch commits from your remote fork and rebase your working branch:

   ```bash
   git fetch origin
   git rebase origin/<your-branch-name>
   ```

1. After rebasing, force-push new changes to your fork:

   ```bash
   git push --force-with-lease origin <your-branch-name>
   ```

#### Adding DCO on commits retroactively

1. Open an interactive rebase session

   ```sh
   git rebase --signoff HEAD~<number of commits in your pr>
   ```

1. Verify you have signed the commits

   ```sh
   git log
   ```

1. Force push

   ```sh
   git push -f origin branchname
   ```

#### Merge conflicts and rebasing

{{< alert >}}
For more information, see [Git Branching - Basic Branching and Merging](https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging#_basic_merge_conflicts), [Advanced Merging](https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging), or ask in the `#sig-docs` Slack channel for help.
{{< /alert >}}

If another contributor commits changes to the same file in another PR, it can create a merge conflict. You must resolve all merge conflicts in your PR.

1. Update your fork and rebase your local branch:

   ```bash
   git fetch origin
   git rebase origin/<your-branch-name>
   ```

   Then force-push the changes to your fork:

   ```bash
   git push --force-with-lease origin <your-branch-name>
   ```

1. Fetch changes from `fluxcd/website`'s `upstream/main` and rebase your branch:

   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

1. Inspect the results of the rebase:

   ```bash
   git status
   ```

   This results in a number of files marked as conflicted.

1. Open each conflicted file and look for the conflict markers: `>>>`, `<<<`, and `===`. Resolve the conflict and delete the conflict marker.

   {{< alert >}}
   For more information, see [How conflicts are presented](https://git-scm.com/docs/git-merge#_how_conflicts_are_presented).
   {{< /alert >}}

1. Add the files to the changeset:

   ```bash
   git add <filename>
   ```

1. Continue the rebase:

   ```bash
   git rebase --continue
   ```

1. Repeat steps 2 to 5 as needed.

    After applying all commits, the `git status` command shows that the rebase is complete.

1. Force-push the branch to your fork:

   ```bash
   git push --force-with-lease origin <your-branch-name>
   ```

   The pull request no longer shows any conflicts.
