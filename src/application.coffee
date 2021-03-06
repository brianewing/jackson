http = require('http')
fs = require('fs')
path = require('path')
util = require('util')

require('colors')
ECT = require('ect')

Router = require('./router')
Controller = require('./controller')
CLI = require('./cli')

{extend, clone, addClassHelpers, jacksonVersion} = require('./util')

class Application
  addClassHelpers(@)

  jacksonVersion: jacksonVersion

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
    @options = clone(@options, options)

    @name ||= @constructor.name
    @repl ||= {}
    @_ectCache ||= {}

    @initialize?()

  listen: (socketOrPort, args..., cb)->
    if typeof cb isnt 'function'
      args.push(cb)
      cb = null

    if typeof socketOrPort is 'number'
      host = args[0] or 'localhost'
      desc = "#{host.yellow}:#{socketOrPort.toString().green}"
    else # socket
      if fs.existsSync(socketOrPort) and fs.statSync(socketOrPort).isSocket()
        # unlink existing socket
        fs.unlinkSync(socketOrPort)

      desc = socketOrPort.white

    @_server = http.createServer(@dispatchReq)
    @_server.listen socketOrPort, args..., =>
      @log("Listening on #{desc}, pid #{process.pid.toString().red}")
      cb?(socketOrPort, args...)

  startRepl: ->
    Jackson = require('..')
    utils = require('./util')

    {context} = require('repl').start
      prompt: @name + "> "
      useGlobal: true
      useColors: true

    extend(context, Jackson, {Jackson, jacksonVersion}, utils, {app: @}, @repl)
    context[@constructor.name] = @constructor
    context[@name] = @constructor

  startCli: ->
    new CLI(@).run()

  mount: (urlPrefix, appOrFn) ->
    @_mounts ||= {}

    if urlPrefix[urlPrefix.length - 1] isnt '/'
      urlPrefix += '/'

    @_mounts[urlPrefix] = appOrFn

  dispatchReq: (req, res) =>
    req._timestamp = Date.now()
    @dispatchUrl(req, res, req.method, req.url)

  dispatchUrl: (req, res, method, url) ->
    if @_mounts?
      urlWithSlash = if url[url.length - 1] is '/' then url else url + '/'

      for mountPrefix, appOrFn of @_mounts
        if urlWithSlash is mountPrefix or url[...mountPrefix.length] is mountPrefix
          url = url.slice(mountPrefix.length - 1) || '/'

          if appOrFn instanceof Jackson.Application
            return appOrFn.dispatchUrl(req, res, method, url)
          else if typeof appOrFn is 'function'
            req.url = url # mask the URL
            appOrFn(req, res)

    route = @constructor.router?.match(method, url)
    res.on 'finish', @bind(@logRequest, req, res) if @options.logRequests

    if route
      @dispatch(req, res, route)
    else
      @render(req, res, 'notFound')

  dispatch: (req, res, route) ->
    {fn, controller, action} = route

    if controller? and action
      controller = @lookup(controller)

      if controller.prototype instanceof Controller
        new controller(@, req, res, route).callAction(action)
      else
        fn = controller::[action] # dispatch below

    if fn
      # dispatch under generic controller
      controller = new Controller(@, req, res, route)
      controller.applyAsAction(fn)

  render: (req, res, action, args...) ->
    new @constructor.DefaultHandlers(@, req, res).apply(action, args...)

  lookup: (path) ->
    path.split('.').reduce ((obj, key) -> if key then obj[key] else obj), @constructor

  renderTemplate: (templateRoot, tpl, context) ->
    templateRoot = templateRoot or @templateRoot or path.join(process.cwd(), 'templates')

    @_ectCache[templateRoot] ||= ECT(watch: true, root: templateRoot)
    @_ectCache[templateRoot].render(tpl, context)

  log: (msgs...) ->
    msgs = [new Date().toISOString().green, '|', @name.yellow, '|', msgs...]
    console.log.apply(console, msgs)

  logRequest: (req, res) ->
    status = res.statusCode.toString()

    statusColor = switch status[0]
      when '2' then 'green'
      when '4' then 'yellow'
      when '5' then 'red'
      else 'blue'

    msTaken = Date.now() - req._timestamp
    @log status[statusColor], req.method.yellow, req.url.white, "#{msTaken}ms".yellow, req.connection.remoteAddress

class Application.DefaultHandlers extends Controller
  templateRoot: __dirname + '/../tpl' # tpl dir from jackson module

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
