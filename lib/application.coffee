http = require('http')
fs = require('fs')
path = require('path')
util = require('util')

ECT = require('ect')

Router = require('./router')
Controller = require('./controller')
{clone, ClassHelpers} = require('./util')

class Application
  ClassHelpers(@)

  @route = ->
    (@router ||= new Router).route(arguments...)

  @helper = (name, fn) ->
    @helpers = clone(@helpers)
    @helpers[name] = fn

  constructor: ->
    @_ect = {}

    @initialize?()

  listen: ->
    @_server = http.createServer(@process)
    @_server.listen(arguments...)

  process: (req, res) =>
    if route = @constructor.router?.match(req)
      @dispatch(req, res, route)
    else
      @render(req, res, 'notFound')

  dispatch: (req, res, route) ->
    {fn, controller, action, routeParams} = route

    if controller? and action
      controller = @lookup(controller)

      if controller.prototype instanceof Controller
        new controller(@, req, res, routeParams).callAction(action)
      else
        fn = controller::[action] # dispatch below

    if fn
      # dispatch under generic controller
      controller = new Controller(@, req, res, routeParams)
      controller.applyAsAction(fn)

  render: (req, res, action, args...) ->
    new @constructor.DefaultHandlers(@, req, res).apply(action, args...)

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

  initialize: ->
    @view.inspect = util.inspect
    @view.req = @req

  notFound: -> @render '404.html'
  error: (error) -> @render '500.html', {error}

module.exports = Application
