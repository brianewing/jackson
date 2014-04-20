{extend} = require('./util')

class Controller
  status: 200

  constructor: (@app, @req, @res) ->
    @view = {}
    @headers = {}

  header: (name, value) ->
    @headers[name.toLowerCase()] = value

  render: (tpl, context) ->
    context = extend({}, @view, context)
    body = @app.renderTemplate tpl, context

    headers = extend {'content-length': body.length, 'content-type': 'text/html'}, @headers
    @res.writeHead(@status, headers)
    @res.end(body)

  dispatch: (action, segments=[]) ->
    if typeof action is 'string'
      action = @[action]

    action.apply(@, segments)

module.exports = Controller
