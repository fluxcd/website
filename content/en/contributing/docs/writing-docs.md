---
title: Docs from the ground up
linkTitle: Writing docs
weight: 4
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

The top section between two lines of `---` is the Front Matter section. Here we define a couple of entries which tell Hugo how to handle article:

- `title` is the equivalent of the `<h1>` in a HTML document or `# <title>` in a Markdown article
- `linkTitle` is the title to be used in the menu or navbar (usually you might want to pick something shorter and easier to spot)
- `description` is shown in a list of documents - maybe the directory you are looking at has a `_index.md` document - this is where you would see the list of articles (and the short descriptions). Note you can write multi-line descriptions like so:

  ```markdown
  description: >
    more text here
    here is even more description
  ```

- `weight` indicates where in the list of documents this is shown. It basically imposes an order on the articles in this directory.

{{% alert color="warning" title="Mixing Front Matter and top-level headings" %}}
Please note: Everything below the Front Matter entry is just the regular Markdown article as you would normally write it. Please note that headings start with `## <..>`, as the title is defined in the Front Matter. Mixing Front Matter and `# <..>` headings will trip up Hugo and it might error out or not show the article.
{{% /alert %}}

## Linking to other docs

You can easily link to other places using either

- Absolute URLs, for linking off to external sites like `https://github.com` or `https://k8s.io` - you can use any of the Markdown notations for this, so
  - `<https://k8s.io>` or
  - `[Kubernetes](https://k8s.io)` will work.
- Link to markdown files in other you can link to the `.md` file, or the resulting path. So if you are editing e.g. `article1.md` in `content/en/flux/section-a` and want to link to `article2.md` in the same directory you can use the following:
  - `[link](article2.md)`
  - `[link](../article2/)`
  - `[link](/flux/section-a/article2/)`

## Media, illustrations and more

If you want to illustrate the documentation and make things easier to read, there are lots of shortcodes either inherited through Hugo or through Docsy. Here is a list of our current favourites:

- [`pageinfo`](https://www.docsy.dev/docs/adding-content/shortcodes/#pageinfo) for quick "banner type" info boxes
- [`tabpane`](https://www.docsy.dev/docs/adding-content/shortcodes/#tabbed-panes) for pieces of text that go in different tabs
- [`cardpane` and `card`](https://www.docsy.dev/docs/adding-content/shortcodes/#card-panes) for adding cards and card panes
- [`gist`, `youtube`, `tweet` and more](https://gohugo.io/content-management/shortcodes/): lots of shortcodes we get from Hugo itself.

## Code snippets

You can embed code snippets from a file. Please refer to
<https://www.docsy.dev/docs/adding-content/shortcodes/#include-code-files> for
hot to use the `readfile` shortcode.

## Tabbed sections

You can create tabbed sections that contain both markdown and code snippets.
Please refer to <https://www.docsy.dev/docs/adding-content/shortcodes/#tabbed-panes>
for how to use the `tabpane` and `tab` shortcodes.

## Gallery shortcodes

You can use gallery shortcodes to easily create and display photo galleries or image sliders within your posts or blogs. 
Please refer to https://github.com/mfg92/hugo-shortcode-gallery for how to use the `hugo-shortcode-gallery` tool.
