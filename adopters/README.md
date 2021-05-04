# Flux Adopters

So you and your organisation are using Flux? That's great. We would love to hear from you! 💖

## Adding yourself

In this directory are a number of YAML files where you just need to add an entry for your company and upon merging it will automatically be added to our website.

Simply follow these steps:

1. (Optional) Add the logo of your organisation to `adopters/logos`. Good practice is for the logo to be called e.g. `<company>.png`.
1. Find the right `adopters/<project>.yaml` file. If you use e.g. Flux v2, this should be `adopters/flux-v2.yaml`.
1. Please add an entry to the file like this:

  ```yaml
      - name: Xenit
        url: https://xenit.se/
        logo: logos/xenit.png
  ```

1. It's really just the `name` of the organisation, `url` that links to its homepage, and the path to the `logo`. This can link off to `https` links too.
1. Save the file, `git add` the relevant files and commit.

Push this as a PR to `fluxcd/website` and a preview build will turn up.

To test this locally, at the very least run:

```cli
make theme
make gen-content
hugo server
```

Then point your browser to `http://localhost:1313`.

Thanks a lot for your being part of our community - we very much appreciate it!
