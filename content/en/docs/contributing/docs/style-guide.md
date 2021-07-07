---
title: Documentation Style Guide
linkTitle: Documentation Style Guide
weight: 20
description: >
    Style Guide for Flux Documentation
---

## Documentation Formatting Standards

### Use upper camel case for API objects

| Do                                                | Don't                                              |
|---------------------------------------------------|----------------------------------------------------|
| The GitRepository resource is responsible for ... | The Git Repository resource is responsible for ... |

### Use angle brackets for placeholders

Use angle brackets for placeholders. Tell the reader what a placeholder represents, for example

```bash
flux reconcile kustomization <name> --with-source
```

### Use bold for user interface elements

### Use italics to define or introduce new terms

### Use code style for filenames, directories, and paths

### Use the international standard for punctuation inside quotes

## Inline Code Formatting

### Use code style for inline code, commands, and API objects

### Use code style for object field names

### Use code style for fluxcd command tool and component names

### Starting a sentence with a component tool or component name

### Use a general descriptor over a component name

### Use normal style for string and integer field values

## Code Snippet Formatting

### Don't include the command prompt

### Separate commands from output

## Fluxcd.io Word List

## Shortcodes

## Markdown Elements

## Content best practices

### Use present tense

### Use active voice

Exception: Use passive voice if active voice leads to an awkward construction.

### Use simple and direct language

Use simple and direct language. Avoid using unnecessary phrases, such as saying "please."

### Address the reader as "you"

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

### Avoid jargon and idioms

Some readers speak English as a second language. Avoid jargon and idioms to help them understand better.

### Avoid statements about the future

Avoid making promises or giving hints about the future. If you need to talk about an alpha feature, put the text under a heading that identifies it as alpha information.

An exception to this rule is documentation about announced deprecations targeting removal in future versions.

### Avoid statements that will soon be out of date

Avoid words like "currently" and "new." A feature that is new today might not be considered new in a few months.

### Avoid statements that assume a specific level of understanding

Avoid words such as "just", "simply", "easy", "easily", "basically" or "simple". These words do not add value.
