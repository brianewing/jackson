http = require('http')
fs = require('fs')
path = require('path')
util = require('util')

require('colors')
ECT = require('ect')

Router = require('./router')
Controller = require('./controller')
{clone, ClassHelpers} = require('./util')
CLI = require('./cli')


class Application
  ClassHelpers(@)

  _mounts: null
  _ect: null

  @route = ->
    (@router ||= new Router).route(arguments...)

  @resource = ->
    (@router ||= new Router).resource(arguments...)

  @helper = (name, fn) ->
    @helpers = clone(@helpers)
    @helpers[name] = fn

  options:
    logRequests: true

  constructor: (options) ->
    @_ect = Object.create(null)
    @options = clone(@options, options)

    @initialize?()

  listen: ->
    [socketOrPort, args..., cb] = arguments
    if typeof cb isnt 'function'
      args.push(cb)
      cb = null

    if typeof socketOrPort is 'number'
      desc = "port #{socketOrPort.toString().green}"
    else
      desc = socketOrPort.white

    @_server = http.createServer(@dispatchReq)
    @_server.listen socketOrPort, args..., =>
      @log("Listening on #{desc}, pid #{process.pid.toString().red}")
      cb?()

  runCli: (args)->
    args ||= process.argv.slice(2)
    new CLI(@, args).run()

  mount: (urlPrefix, app) ->
    if urlPrefix[urlPrefix.length - 1] isnt '/'
      urlPrefix += '/'

    (@_mounts ||= Object.create(null))[urlPrefix] = app

  dispatchReq: (req, res) =>
    req._timestamp = +new Date
    @dispatchUrl(req, res, req.method, req.url)

  dispatchUrl: (req, res, method, url) ->
    if @_mounts?
      if url[url.length - 1] isnt '/'
        urlWithSlash = url + '/'
      else urlWithSlash = url

      for urlPrefix, app of @_mounts
        if urlWithSlash is urlPrefix or url[...urlPrefix.length] is urlPrefix
          url = url.slice(urlPrefix.length - 1) or '/'
          return app.dispatchUrl(req, res, method, url)

    route = @constructor.router?.match(method, url)
    res.on 'finish', @bind(@logRequest, req, res) if @options.logRequests

    if route
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
    msgs = [new Date().toISOString().green, '|', @constructor.name.yellow, '|', msgs...]
    console.log.apply(console, msgs)

  logRequest: (req, res) ->
    status = res.statusCode.toString()

    statusColor = switch status[0]
      when '2' then 'green'
      when '4' then 'yellow'
      when '5' then 'red'
      else 'blue'

    msTaken = (new Date) - req._timestamp
    @log status[statusColor], req.method.yellow, req.url.white
    @log "#{msTaken}ms".yellow, req.connection.remoteAddress

class Application.DefaultHandlers extends Controller
  templateRoot: __dirname + '/../tpl'

  initialize: ->
    @view.inspect = util.inspect
    @view.req = @req

  notFound: ->
    @status = 404
    @render '404.html'

  error: (error) ->
    @status = 500
    @render '500.html', {error}

module.exports = Application
