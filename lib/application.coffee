http = require('http')
fs = require('fs')
path = require('path')

ECT = require('ect')

Router = require('./router')
Controller = require('./controller')

class Application
  @route = ->
    (@router ||= new Router).route(arguments...)

  listen: ->
    @_server = http.createServer(@process)
    @_server.listen(arguments...)

  process: (req, res) =>
    if route = @constructor.router?.match(req)
      @dispatch(route, req, res)
    else
      res.end('404')

  dispatch: (route, req, res) ->
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

  lookup: (path) ->
    path.split('.').reduce ((obj, key) -> if key then obj[key] else obj), @constructor

  renderTemplate: (tpl, context) ->
    if not @_ect
      root = @templateRoot || path.join(process.cwd(), 'templates')
      @_ect = ECT(watch: true, root: root)

    @_ect.render(tpl, context)

  log: (msgs...) ->
    msgs = [new Date().toISOString(), "|", msgs...]
    console.log.apply(console, msgs)

module.exports = Application
