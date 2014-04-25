Jackson
=======

Jackson is a web application framework for Node with a focus on simplicity, ease of use and composability, including the batteries you need to build everyday web applications.

**Jackson is a new project under early development.**

Blog example
------------

```coffeescript
posts = [
  {name: 'Post One'},
  {name: 'Post Two'},
  {name: 'Post Three'},
]

class Blog extends Jackson.Application
  @route '/', 'Posts#index'
  @route '/posts/:id', 'Posts#show'

class Blog.Posts extends Jackson.Controller
  templateDir: 'posts'

  index: -> @render('index.html', posts: posts)
  show: (id) -> @render('show.html', post: posts[id])

class Blog.Api extends Jackson.Application
  @resource '/posts', 'Posts'

  class @Posts extends Jackson.Controller
    index: ->
      @respond(posts)

    show: (id) ->
      if posts[id]
        @respond(posts[id])
      else
        @respond(404)

class Admin extends Jackson.Application
  @route '/', 'Dashboard#overview'
  templateRoot: 'admin'

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
