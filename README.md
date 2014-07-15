Jackson
=======

Jackson is a web application framework for Node with a focus on simplicity, composability and ease of use, including the batteries you need to build everyday web applications.

**Jackson is a new project under early development.**

Quick-and-dirty example
-----------------------

Jackson is currently undocumented and you shouldn't use it yet for non-trivial/production sites.

Here is an example which outlines how routes, controllers and applications work in Jackson:

```coffeescript
class Blog extends Jackson.Application
  @route '/', 'Posts#index'

  @route '/posts', 'Posts#index'
  @route '/posts/:id', 'Posts#show'

  # or use shorthand to create a whole resource à la Rails
  # @resource('/posts', 'Posts')

  templateRoot: __dirname + '/templates'

class Blog.Posts extends Jackson.Controller
  templateDir: 'posts'

  index: -> @render('index.html', posts: Post.all())
  show: (id) -> @render('show.html', post: Post.find(id))

class Blog.Api extends Jackson.Application
  @resource '/posts', 'Posts'

  class @Posts extends Jackson.Controller
    index: ->
      @respond(Post.all())

    show: (id) ->
      if post = Post.find(id)
        @respond(post)
      else
        @respond(404)

class Admin extends Jackson.Application
  @route '/', 'Dashboard#overview'
  templateRoot: __dirname + '/admin_templates'

  class @Dashboard extends Jackson.Controller
    @beforeAll 'authenticate'

    # contrived example, demonstrates before filters
    authenticate: ->
      if @req.ip isnt '127.0.0.1'
        @respond(403, 'Local only.')
        true

    overview: -> @render 'overview.html'

blog = new Blog
blog.mount '/api', new Blog.Api
blog.mount '/admin', new Admin

blog.listen(1234)
```

Command-line interface
----------------------

Jackson has a neat command line interface, with the `jack` command.

#### Create a new application:

`$ jack new MyApp`

`$ cd my_app/`

Pass `--js` to `jack new` if you would prefer not to use CoffeeScript.

#### Start the application:

`$ jack server`

This is the default command, so you can just use:
`$ jack`.

The default Jackson port is **1234**. Pass another like `jack --port 5858`

You can also listen on a Unix socket with `jack --socket /tmp/myapp.socket`

#### Application REPL!

You can drop into a REPL with your application loaded:

`$ jack repl` ('r' for short)

Your app is available as `app`. You'll also have `Jackson` and your application class defined.

If you want to expose more to the REPL, add stuff too app.repl like:

`app.repl.greet = -> 'hello'`

When in the REPL, you'll be able to use `greet()`.

