# Writing blog posts here

Here are some tips and tricks on how to do add blog posts to <https://fluxcd.io>.

- Often we draft posts in Google Docs. To transform them into Markdown, you might want to
  1. Save as Microsoft Word document (`.docx`).
  1. Transform into Markdown by running

     ```cli
     pandoc -i blogpost.docx -f docx -t markdown -o blogpost.md
     ```

  1. You will need to tidy this up, but it should be a good start.
- Add your post to this directory.
- Add [Front Matter](https://gohugo.io/content-management/front-matter/) to your post file. Make sure to define `author`, `date`, `url`, `title`, `description`.
- Make sure `date` is not in the future, or it won't show up. :-D
- Fields like `aliases` (if you mistyped a URL), `tags`, `resources` are optional.
- Common `tags` we use are `monthly-update` and `security`.
- Adding images:
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
  