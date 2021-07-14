---
title: Custom Hugo Shortcodes
linkTitle: hugo-shortcodes
weight: 10
---

This page explains the custom Hugo shortcodes that can be used in Flux Markdown documentation.

Read more about shortcodes in the [Hugo documentation](https://gohugo.io/content-management/shortcodes).

## Code snippets

You can embed code snippets from a file.

``language`` is any [language supported by GitHub flavored markdown](https://github.com/github/linguist/blob/master/lib/linguist/languages.yml).

``file`` is the path to the file you want to use in the code block.

```go-html-template
{{%/* codeblock file="/static/snippet/example.yaml" language="yaml" */%}}
```

{{% codeblock file="/static/snippet/example.yaml" language="yaml" %}}

## Tabbed sections

You can create tabbed sections that contain both markdown and code snippets.

{{% alert title="Warning" color="warning" %}}
Do not use headers in code blocks. When following a header permalink, that is placed in a tab, the page will not switch to that tab.
{{% /alert %}}

```go-html-template
{{%/* tabs */%}}
{{%/* tab "codeblock and text in a tab" */%}}

cool sample text

{{%/* codeblock file="/static/snippet/example.yaml" language="yaml" */%}}

{{%/* /tab */%}}
{{%/* tab "codeblock in a tab" */%}}

{{%/* codeblock file="/static/snippet/example.yaml" language="yaml" */%}}

{{%/* /tab */%}}
{{%/* tab "text in a tab" */%}}

cool sample text

{{%/* /tab */%}}{{%/* /tabs */%}}

```

{{% tabs %}}
{{% tab "codeblock and text in a tab" %}}

cool sample text

{{% codeblock file="/static/snippet/example.yaml" language="yaml" %}}

{{% /tab %}}
{{% tab "codeblock in a tab" %}}

{{% codeblock file="/static/snippet/example.yaml" language="yaml" %}}

{{% /tab %}}
{{% tab "text in a tab" %}}

cool sample text

{{% /tab %}}{{% /tabs %}}
