# fluxcd.io

This repo houses the assets used to build the Flux project's landing page at <https://fluxcd.io>.

> **Note**: The sources for some of Flux's documentation are housed in the other Flux repositories within <https://github.com/fluxcd>. Issues and pull requests for this documentation should be registered at that repos.
>
> Project       | Docs Site                                        | Github Source
> ------------- | ------------------------------------------------ | -------------
> Flux v1       | <https://docs.fluxcd.io>                         | <https://github.com/fluxcd/flux>
> Helm Operator | <https://docs.fluxcd.io/projects/helm-operator/> | <https://github.com/fluxcd/helm-operator>
> Flux v2       | <https://fluxcd.io/docs>                         | <https://github.com/fluxcd/website>
>
> We are in the process of moving everything into this repository: `/fluxcd/website`. The work can be tracked here: <https://github.com/fluxcd/website/issues/76>.

## How to modify this website

The main landing page of this website can be modified in `config.toml`.

All other content lives in the `content` directory:

- `./content/en/blog` contains all blog posts - make sure you update the front-matter for posts to show up correctly.
- `./external-sources/` defines how files from other repositories are pulled in. We currently do this for Markdown files from the `/fluxcd/community` and `/fluxcd/.github` repositories. (`make gen-content` pulls these in.)
- Flux CLI docs (`cmd`) and `components` docs: under `./content/en/docs` but pulled in through in `make gen-content` as well.

## Running the site locally

In order to run the Flux site locally, you need to install:

- [Node.js](https://www.npmjs.com/get-npm)
- The [Hugo](https://gohugo.io) static site generator. Make sure to [install](https://gohugo.io/getting-started/installing/) the "extended" variant of Hugo with support for the [Hugo Pipes](https://gohugo.io/hugo-pipes/introduction/) feature and to check the [`netlify.toml`](./netlify.toml) configuration file for which version of Hugo you should install.

Once those tools are installed, fetch the assets necessary to run the site:

```cli
npm install
make theme
```

Then run the site in "server" mode:

```cli
make serve
```

Navigate to <http://localhost:1313> to see the site running in your browser. As you make updates to the site, the browser will immediately update to reflect those changes.

## Publishing the site

The Flux website is published automatically by [Netlify](https://netlify.com) when changes are pushed to the `main` branch. The site does not need to be published manually.

### Preview builds

When you submit a pull request to this repository, Netlify builds a "deploy preview" of your changes. You can see that preview by clicking on the **deploy/netlify** link in the pull request window.
