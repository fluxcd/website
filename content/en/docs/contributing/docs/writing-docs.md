---
title: Writing docs
weight: 2
description: >
    Our docs are just Markdown, but offer you more flexibility and styling options.
---

## Getting Started

If you already know **Markdown**, this is going to be straight-forward. For our docs we use markdown, and we get some additions through the [Hugo](https://gohugo.io) static website generator and the [Docsy](https://docsy.dev) theme, which we are going to line out here.

If you are unfamiliar with Markdown, please see <https://guides.github.com/features/mastering-markdown/> (it's a good cheat-sheet) or <https://www.markdownguide.org/> if you are looking for something more substantial.

## Starting at the top

Hugo allows you to specify metadata concerning an article at the top of the Markdown file, in a section called **Front Matter**. The Hugo website has a [great article about it](https://gohugo.io/content-management/front-matter/) which explains all the relevant options.

For now, let's take a look at a quick example which should explain the most relevant entries in Front Matter:

```markdown
---
title: Using Flux on OpenShift
linkTitle: OpenShift
description: "How to bootstrap Flux on OpenShift."
weight: 20
---

## OpenShift Setup

Steps described in this document have been tested on OpenShift 4.6 only. 

[...]
```

If you have looked at ...
