path = require('path')

async = require('async')

{extend, JSHelpers} = require('./util')

class Controller
  JSHelpers(@)

  @bind = (event, callbacks...) ->
    # we clone @_callbacks, then set
    # @_callbacks[event] to a new array [existingCallbacks..., callbacks...]
    # this is a semi-hack to support inheritance of callbacks in controllers
    # designed to be extended

    @_callbacks = extend {}, @_callbacks
    @_callbacks[event] = (@_callbacks[event] || []).concat(callbacks)

  @fire = (instance, event, cb) ->
    callbacks = @_callbacks?[event]
    return cb?() if not callbacks?.length

    iter = (callback, cb) ->
      callback = instance[callback] if typeof callback is 'string'

      try
        if callback.length is 1
          instance.apply(callback, cb)
        else
          cb(instance.apply(callback) is true)
      catch error
        instance.error(error)
        cb(true)

    async.forEachSeries(callbacks, iter, cb)

  @before = (action, callbacks...) -> @bind "before:#{action}", callbacks...
  @beforeAll = (callbacks...) -> @bind 'before', callbacks...

  @after = (action, callbacks...) -> @bind "after:#{action}", callbacks...
  @afterAll = (callbacks...) -> @bind 'after', callbacks...

  status: 200

  constructor: (@app, @req, @res, @routeParams={}) ->
    @view = {}
    @headers = {}

    @initialize?()

  header: (name, value) ->
    @headers[name.toLowerCase()] = value

  render: (tpl, context) ->
    tpl = path.join(@templateDir || '', tpl)
    context = extend({}, @view, context)

    body = @app.renderTemplate @templateRoot, tpl, context
    @respond(body)

  respond: (status, body) ->
    if not body
      [body, status] = [status, @status]

    if typeof body is 'object'
      @header('content-type', 'application/json')
      body = JSON.stringify(body)
    else if typeof body is 'string'
      @header('content-type', 'text/html')

    @header('content-length', body.length)

    @res.writeHead(status, @headers)
    @res.end(body)

  apply: (fn, args...) ->
    fn = if typeof fn is 'function' then fn else @[fn]

    try
      fn.apply(@, args)
    catch error
      @error(error)
      true

  applyAsAction: (action) ->
    @apply action, (value for own key, value of @routeParams)...

  callAction: (action, cb) ->
    @constructor.fire @, 'before', =>
      @constructor.fire @, "before:#{action}", =>
        @applyAsAction(action)

        @constructor.fire @, 'after', =>
          @constructor.fire @, "after:#{action}", cb

  error: (error) ->
    @app.render(@req, @res, 'error', error)

module.exports = Controller
