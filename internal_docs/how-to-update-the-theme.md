# Updating the theme

Our website uses [Hugo modules](https://gohugo.io/hugo-modules/use-modules/)
to manage our themes and you can view what is currently being used in
[`go.mod`](https://github.com/fluxcd/website/blob/main/go.mod) in the main
directory.

To update all the themes, you need to run

```cli
hugo mod get -u ./...
```

Be careful though, it's always a good idea to consult the changelogs or
list of commits of our themes to be sure there are no breaking changes.

## Docsy

We use our [Docsy](https://github.com/google/docsy) and have a couple of
changes over it. They are all contained in the `layouts/partials` directory.
Right now they are all documented, so the diff over upstream (docsy) is
explained and clear why it needs to be there. Let's keep the diff as minimal
as possible.

A good way to understand our diff over upstream is to have a local
check out of docsy. With that you can run something along the lines of
this to inspect the diff and be sure we e.g. incorporate upstream
changes

```cli
diff -ru {../../docsy/,}layouts/partials/
```

The diff as of 2023-03-29 can be seen here:
<https://gist.github.com/dholbach/0c3d6dd05d7734539e3d986b77ab1976>

If you are lucky and the upstream change of a release of docsy is small,
you will either have to change nothing at all, or applying the upstream
diff between the releases is good enough.

## Gallery Theme

This theme is quite uncomplicated and hasn't seen big changes or
refactoring lately, but taking a look at the changes won't hurt.
We use it mostly in blog posts to show picture galleries.
