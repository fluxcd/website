---
title: Documentation Style Guide
linkTitle: Documentation Style Guide
weight: 6
description: >
    Style Guide for Flux Documentation
---
## Documentation formatting standards

This page gives writing style guidelines for the Flux documentation. These are guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request.

{{< note >}}
Flux documentation uses [Goldmark Markdown Renderer](https://github.com/yuin/goldmark) with some adjustments along with a few [Hugo Shortcodes](writing-docs.md) to support glossary entries, tabs, and representing feature state.
{{< /note >}}

### Use upper camel case for API objects

When you refer specifically to interacting with an API object, use [UpperCamelCase](https://en.wikipedia.org/wiki/Camel_case), also known as Pascal case.

When you are generally discussing an API object, use sentence-style capitalization.

You may use the word "resource", "API", or "object" to clarify a Flux resource type in a sentence.

Don't split an API object name into separate words. For example, use HelmRelease, not Helm Release.

The following examples focus on capitalization. For more information about formatting API object names, review the related guidance on [Code Style](#code-style-inline-code).

Do | Don't
:--| :-----
| The GitRepository resource is responsible for ... | The Git Repository resource is responsible for ... |

### Use angle brackets for placeholders

Use angle brackets (`<>`) for placeholders. Tell the reader what a placeholder represents, for example

Reconcile a kustomization :

```bash
flux reconcile kustomization <name> --with-source
```

### Use bold for user interface elements

Do | Don't
:--| :-----
Click **Fork**. | Click "Fork".
Select **Other**. | Select "Other".

### Use italics to define or introduce new terms

Do | Don't
:--| :-----
A _Reconciliation_ is ... | A "_Reconciliation_" is ...

### Use code style for filenames, directories, and paths

Do | Don't
:--| :-----
Open the `envars.yaml` file. | Open the envars.yaml file.
Go to the `/docs/tutorials` directory. | Go to the /docs/tutorials directory.
Open the `/_data/concepts.yaml` file. | Open the /\_data/concepts.yaml file.

### Use the international standard for punctuation inside quotes

Do | Don't
:--| :-----
events are recorded with an associated "stage". | events are recorded with an associated "stage."
The copy is called a "fork". | The copy is called a "fork."

## Inline Code Formatting

For inline code in an HTML document, use the `<code>` tag. In a Markdown
document, use the backtick (`` ` ``).

### Use code style for inline code, commands, and API objects

Do | Don't
:--| :-----
The `flux bootstrap` command creates a `Pod`. | The "flux bootstrap" command creates a pod.
The Helm controller manages `HelmRelease` objects… | The Helm controller manages HelmRelease objects… 
A `Kustomization` represents … | A Kustomization represents …
Enclose code samples with triple backticks. (\`\`\`)| Enclose code samples with any other syntax.
Use single backticks to enclose inline code. For example, `var example = true`. | Use two asterisks (`**`) or an underscore (`_`) to enclose inline code. For example, **var example = true**.
Use triple backticks before and after a multi-line block of code for fenced code blocks. | Use multi-line blocks of code to create diagrams, flowcharts, or other illustrations.
Use meaningful variable names that have a context. | Use variable names such as 'foo','bar', and 'baz' that are not meaningful and lack context.
Remove trailing spaces in the code. | Add trailing spaces in the code, where these are important, because the screen reader will read out the spaces as well.

### Use code style for object field names

Do | Don't
:--| :-----
Set the value of the `interval` field in the configuration file. | Set the value of the "interval" field in the configuration file.
The value of the `chart` field is an HelmChartTemplate object. | The value of the "chart" field is an HelmChartTemplate object.

### Use code style for Flux command-line tool and component names

Do | Don't
:--| :-----
The Source controller preserves node stability. | The `source-controller` preserves node stability.
The `flux` tool handles installation. | The flux tool handles installation.
Run the command to get Kustomizations with the name, `flux get kustomization <name>`. | Run the command to get Kustomizations with the name, flux get kustomization \<name\>. |

### Starting a sentence with a component tool or component name

Do | Don't
:--| :-----
The `flux` tool bootstraps and provisions Flux controllers in a cluster. | `flux` tool bootstraps and provisions Flux controllers in a cluster.
The Source controller manages resources. | Source controller manages resources.

### Use a general descriptor over a component name

Do | Don't
:--| :-----
The Flux Source controller offers an OpenAPI spec. | The source-controller offers an OpenAPI spec.

### Use normal style for string and integer field values

For field values of type string or integer, use normal style without quotation marks.

Do | Don't
:--| :-----
Set the value of `imagePullPolicy` to Always. | Set the value of `imagePullPolicy` to "Always".
Set the value of `image` to nginx:1.16. | Set the value of `image` to `nginx:1.16`.
Set the value of the `replicas` field to 2. | Set the value of the `replicas` field to `2`.

## Code Snippet Formatting

### Don't include the command prompt

Do | Don't
:--| :-----
flux get kustomizations | $ flux get kustomizations

### Separate commands from output

Verify that your cluster satisfies the prerequisites with:

```shell
flux check --pre
```

The output is similar to this:

```console
► checking prerequisites
✔ kubectl 1.18.3 >=1.18.0
✔ kubernetes 1.18.2 >=1.16.0
✔ prerequisites checks passed
```

## Fluxcd.io Word List

A list of Flux-specific terms and words to be used consistently across the site.

Term | Usage
:--- | :----
Flux | Flux should always be capitalized.
On-premises | On-premises or On-prem rather than On-premise or other variations.
Multi-tenancy | Multi-tenancy or Multi-tenant rather than Multitenancy or other variations.

## Shortcodes

Hugo [Shortcodes](https://gohugo.io/content-management/shortcodes) help create different rhetorical appeal levels.

1. Surround the text with an opening and closing shortcode.

2. Use the following syntax to apply a style:

   ```go-html-template
   {{</* note */>}}
   No need to include a prefix; the shortcode automatically provides one. (Note:, Caution:, etc.)
   {{</* /note */>}}
   ```

   The output is:

   {{< note >}}
   The prefix you choose is the same text for the tag.
   {{< /note >}}

### Note

Use `{{</* note */>}}` to highlight a tip or a piece of information that may be helpful to know.

For example:

```go-html-template
{{</* note */>}}
You can _still_ use Markdown inside these callouts.
{{</* /note */>}}
```

The output is:

{{< note >}}
You can _still_ use Markdown inside these callouts.
{{< /note >}}

You can use a `{{</* note */>}}` in a list:

```go-html-template
1. Use the note shortcode in a list

1. A second item with an embedded note

   {{</* note */>}}
   Warning, Caution, and Note shortcodes, embedded in lists, need to be indented four spaces. See [Common Shortcode Issues](#common-shortcode-issues).
   {{</* /note */>}}

1. A third item in a list

1. A fourth item in a list
```

The output is:

1. Use the note shortcode in a list

1. A second item with an embedded note

    {{< note >}}
    Warning, Caution, and Note shortcodes, embedded in lists, need to be indented four spaces. See [Common Shortcode Issues](#common-shortcode-issues).
    {{< /note >}}

1. A third item in a list

1. A fourth item in a list

### Caution

Use `{{</* caution */>}}` to call attention to an important piece of information to avoid pitfalls.

For example:

```go-html-template
{{</* caution */>}}
The callout style only applies to the line directly above the tag.
{{</* /caution */>}}
```

The output is:

{{< caution >}}
The callout style only applies to the line directly above the tag.
{{< /caution >}}

### Warning

Use `{{</* warning */>}}` to indicate danger or a piece of information that is crucial to follow.

For example:

```go-html-template
{{</* warning */>}}
Beware.
{{</* /warning */>}}
```

The output is:

{{< warning >}}
Beware.
{{< /warning >}}

## Markdown elements

### Line breaks

Use a single newline to separate block-level content like headings, lists, images, code blocks, and others. The exception is second-level headings, where it should be two newlines. Second-level headings follow the first-level (or the title) without any preceding paragraphs or texts. A two line spacing helps visualize the overall structure of content in a code editor better.

### Headings

People accessing this documentation may use a screen reader or other assistive technology (AT). [Screen readers](https://en.wikipedia.org/wiki/Screen_reader) are linear output devices, they output items on a page one at a time. If there is a lot of content on a page, you can use headings to give the page an internal structure. A good page structure helps all readers to easily navigate the page or filter topics of interest.

Do | Don't
:--| :-----
Update the title in the front matter of the page or blog post. | Use first level heading, as Hugo automatically converts the title in the front matter of the page into a first-level heading.
Use ordered headings to provide a meaningful high-level outline of your content. | Use headings level 4 through 6, unless it is absolutely necessary. If your content is that detailed, it may need to be broken into separate articles.
Use pound or hash signs (`#`) for non-blog post content. | Use underlines (`---` or `===`) to designate first-level headings.
Use sentence case for headings. For example, **Clone the git repository** | Use title case for headings. For example, **Clone the Git Repository**

### Paragraphs

Do | Don't
:--| :-----
Try to keep paragraphs under 6 sentences. | Indent the first paragraph with space characters. For example, ⋅⋅⋅Three spaces before a paragraph will indent it.
Use three hyphens (`---`) to create a horizontal rule. Use horizontal rules for breaks in paragraph content. For example, a change of scene in a story, or a shift of topic within a section. | Use horizontal rules for decoration.

### Links

Do | Don't
:--| :-----
Write hyperlinks that give you context for the content they link to. For example: Certain ports are open on your machines. See <a href="#check-required-ports">Check required ports</a> for more details. | Use ambiguous terms such as "click here". For example: Certain ports are open on your machines. See <a href="#check-required-ports">here</a> for more details.
Write Markdown-style links: `[link text](URL)`. For example: `[Docs from the ground up](/contributing/docs/writing-docs.md)` and the output is [Docs from the ground up](/contributing/docs/writing-docs). | Write HTML-style links: `<a href="/contributing/docs/writing-docs" target="_blank">Docs from the ground up</a>`, or create links that open in new tabs or windows. For example: `[Docs from the ground up](/contributing/docs/writing-docs){target="_blank"}`

### Lists

Group items in a list that are related to each other and need to appear in a specific order or to indicate a correlation between multiple items. When a screen reader comes across a list—whether it is an ordered or unordered list—it will be announced to the user that there is a group of list items. The user can then use the arrow keys to move up and down between the various items in the list.
Website navigation links can also be marked up as list items; after all they are nothing but a group of related links.

- End each item in a list with a period if one or more items in the list are complete sentences. For the sake of consistency, normally either all items or none should be complete sentences.

  {{< note >}}
  Ordered lists that are part of an incomplete introductory sentence can be in lowercase and punctuated as if each item was a part of the introductory sentence.
  {{< /note >}}


- Use the number one (`1.`) for ordered lists.

- Use (`+`), (`*`), or (`-`) for unordered lists.

- Leave a blank line after each list.

- Indent nested lists with four spaces (for example, ⋅⋅⋅⋅).

- List items may consist of multiple paragraphs. Each subsequent paragraph in a list item must be indented by either four spaces or one tab.

### Tables

The semantic purpose of a data table is to present tabular data. Sighted users can quickly scan the table but a screen reader goes through line by line. A table caption is used to create a descriptive title for a data table. Assistive technologies (AT) use the HTML table caption element to identify the table contents to the user within the page structure.

- Add table captions.

## Content best practices

### Use present tense

Do | Don't
:--| :-----
This command starts a proxy. | This command will start a proxy.

### Use active voice

Exception: Use passive voice if active voice leads to an awkward construction.

Do | Don't
:--| :-----
You can explore the API using a browser. | The API can be explored using a browser.
The YAML file specifies the replica count. | The replica count is specified in the YAML file.

### Use simple and direct language

Use simple and direct language. Avoid using unnecessary phrases, such as saying "please."

Do | Don't
:--| :-----
To create a ReplicaSet, ... | In order to create a ReplicaSet, ...
See the configuration file. | Please see the configuration file.
View the pods. | With this next command, we'll view the pods.

### Address the reader as "you"

Do | Don't
:--| :-----
You can create a Kustomization by ... | We'll create a Kustomization by ...
In the preceding output, you can see... | In the preceding output, we can see ...

### Avoid Latin phrases

Prefer English terms over Latin abbreviations.

| Do          | Don't |
|-------------|-------|
| That is     | i.e   |
| For example | e.g.  |

Exception: Use "etc." for et cetera.

## Patterns to avoid

### Avoid using we

Using "we" in a sentence can be confusing, because the reader might not know whether they're part of the "we" you're describing.

Do | Don't
:--| :-----
Version 2 includes ... | In version 2, we have added ...
Flux provides a new feature for ... | We provide a new feature ...
This page teaches you how to use Kustomizations. | In this page, we are going to learn about Kustomizations.

### Avoid jargon and idioms

Some readers speak English as a second language. Avoid jargon and idioms to help them understand better.

Do | Don't
:--| :-----
Internally, ... | Under the hood, ...
Create a new cluster. | Turn up a new cluster.

### Avoid statements about the future

Avoid making promises or giving hints about the future. If you need to talk about an alpha feature, put the text under a heading that identifies it as alpha information.

An exception to this rule is documentation about announced deprecations targeting removal in future versions.

### Avoid statements that will soon be out of date

Avoid words like "currently" and "new." A feature that is new today might not be considered new in a few months.

Do | Don't
:--| :-----
In version 2, ... | In the current version, ...
The Image Update Automation feature provides ... | The new Image Update Automation provides ...

### Avoid statements that assume a specific level of understanding

Avoid words such as "just", "simply", "easy", "easily", "basically" or "simple". These words do not add value.

Do | Don't
:--| :-----
Include one command in ... | Include just one command in ...
Commit the Kustomization ... | Simply commit the Kustomization ...
You can remove ... | You can easily remove ...
These steps ... | These simple steps ...
