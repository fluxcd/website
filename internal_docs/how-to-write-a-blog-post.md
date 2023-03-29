# Writing blog posts here

Here are some tips and tricks on how to do add blog posts to <https://fluxcd.io>.

## Tips

### Coming from Google Docs

Often we draft posts in Google Docs. To transform them into Markdown, you might want to

1. Save as Microsoft Word document (`.docx`).
1. Transform into Markdown by running

   ```cli
   pandoc -i blog-post.docx -f docx -t markdown -o blog-post.md
   ```

1. You will need to tidy this up, but it should be a good start.

### Adding your post

1. Add your post to this directory. If you don't intend to add images or other media to it (see below), you might want to go with naming the file `<date>-<post-slug>.md`, e.g. `2022-02-22-security-fuzzing.md`.
1. Add [Front Matter](https://gohugo.io/content-management/front-matter/) to your post file.
   - **Must haves:** Make sure to define `author`, `date`, `url`, `title`, `description`.
   - **Date:** Make sure `date` is not in the future, or it won't show up. :-D
   - **Optional:** Fields like `aliases` (if you mistyped a URL), `tags`, `resources` are optional.
   - **Tags:** Common `tags` we use are `monthly-update` and `security`.
   - **Aging well:** Posts are automatically marked as 'outdated' and receive a warning at the top advising the reader to check if information hasn't changed in the meantime. If your post is special and will stay accurate over a long time, use `evergreen: true` in the Front Matter.

### Adding images

1. Create a directory for the post where you have images
1. Call the markdown file `<date>-<post-slug>/index.md`
1. Copy your images into `<date>-<post-slug>` as well
1. Add

   ```yaml
   resources:
   - src: "**.png"
     title: "Image #:counter"
   ```

   to the Front Matter.
1. Make sure the image you want to be featured (on the blog list and in socials), is called `featured-<something>.jpg` - should have `featured` in its name.
  