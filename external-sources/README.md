# Instructions

`hack/gen-content.py` uses this directory. Here is how it works:

1. Create a file called `external-sources/<github-org>/<github-repo>`
1. Make it a CSV file of the following format:

   ```csv
   <file in repo>, <file in website>
   ```

1. Optionally add a title argument.
1. Optionally add a weight as fourth argument. If you do, you need to pass a third as well. To pass an empty argument, use "" or "-".

## Example

Here is a simple example:

`external-sources/fluxcd/flux2` contains:

```csv
"/CONTRIBUTING.md","/contributing/flux.md","Contributing to Flux"
```

This means that the script will do a shallow clone of `github.com/fluxcd/flux2` and copy the top-level `CONTRIBUTING.md` file into `/contributing/flux.md` (under `content/en`). It will also change the title to "Contributing to Flux".

Behind the scenes the script does quite a few other changes as well to make the front-matter look good.
