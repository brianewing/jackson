http = require('http')
fs = require('fs')
path = require('path')

ECT = require('ect')

Router = require('./router')
Controller = require('./controller')

class Application
  @route = ->
    (@router ||= new Router).route(arguments...)

  constructor: ->
    @_ect = {}

  listen: ->
    @_server = http.createServer(@process)
    @_server.listen(arguments...)

  process: (req, res) =>
    if route = @constructor.router?.match(req)
      @dispatch(req, res, route)
    else
      @dispatchDefault(req, res, 'notFound')

  dispatch: (req, res, route) ->
    {fn, controller, action, segments} = route

    if controller? and action
      controller = @lookup(controller)

      if controller.prototype instanceof Controller
        new controller(@, req, res).dispatch(action, segments)
      else
        fn = controller::[action] # dispatch below

    if fn
      # dispatch under generic controller
      controller = new Controller(@, req, res)
      controller.dispatch(fn, segments)

  dispatchDefault: (req, res, action) ->
    @dispatch(req, res, controller: 'DefaultHandlers', action: action)

  lookup: (path) ->
    path.split('.').reduce ((obj, key) -> if key then obj[key] else obj), @constructor

  renderTemplate: (templateRoot, tpl, context) ->
    templateRoot = templateRoot or @templateRoot or path.join(process.cwd(), 'templates')

    @_ect[templateRoot] ||= ECT(watch: true, root: templateRoot)
    @_ect[templateRoot].render(tpl, context)

  log: (msgs...) ->
    msgs = [new Date().toISOString(), "|", msgs...]
    console.log.apply(console, msgs)

class Application.DefaultHandlers extends Controller
  templateRoot: __dirname + '/../tpl'

  notFound: ->
    @render '404.html', {url: @req.url}

module.exports = Application
