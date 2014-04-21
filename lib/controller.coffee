path = require('path')

async = require('async')

{extend} = require('./util')

class Controller
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

      if callback.length is 1
        callback.call(instance, cb)
      else
        cb(callback.call(instance) is true)

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

  apply: (fn) ->
    fn.apply(@, (value for own key, value of @routeParams))

  callAction: (action, cb) ->
    method = @[action]

    @constructor.fire @, 'before', =>
      @constructor.fire @, "before:#{action}", =>
        @apply(method)

        @constructor.fire @, 'after', =>
          @constructor.fire @, "after:#{action}", cb

module.exports = Controller
