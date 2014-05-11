path = require('path')

async = require('async')

{extend, clone, ClassHelpers} = require('./util')

class Controller
  ClassHelpers(@)

  @bind = (event, callbacks...) ->
    # we clone @_callbacks, then set
    # @_callbacks[event] to a new array [existingCallbacks..., callbacks...]
    # this is a semi-hack to support inheritance of callbacks in controllers
    # designed to be extended

    @_callbacks = clone(@_callbacks)
    @_callbacks[event] = (@_callbacks[event] || []).concat(callbacks)

  @fire = (instance, events..., cb) ->
    if typeof cb isnt 'function'
      events.push(cb)
      cb = null

    async.forEachSeries events, @_fire.bind(@, instance), cb

  @_fire = (instance, event, cb) ->
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

  @helper = (name, fn) ->
    @helpers = clone(@helpers)
    @helpers[name] = fn

  status: 200

  constructor: (@app, @req, @res, @routeParams={}) ->
    @view = {}
    @headers = {}

    @initialize?()

  header: (name, value) ->
    @headers[name.toLowerCase()] = value

  viewContext: (context) ->
    clone(@app.constructor.helpers, @constructor.helpers, @view, context)

  render: (tpl, context) ->
    tpl = path.join(@templateDir || '', tpl)

    body = @app.renderTemplate @templateRoot, tpl, @viewContext(context)
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
