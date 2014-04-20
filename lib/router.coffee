urlPattern = require('url-pattern')
{extend} = require('./util')

class Router
  constructor: ->
    @_routes = []

  route: (method, pattern, dest, options) ->
    if method instanceof Array
      for m in method
        @route.call(@, m, Array::slice.call(arguments, 1)...)
      return

    if typeof dest isnt 'string' # called like route('/posts', 'Posts#index')
      [method, pattern, dest, options] = ['GET', method, pattern]

    options ||= {}
    options.method = (options.method || method).toUpperCase()
    options.pattern = urlPattern.newPattern(pattern)

    [controller, action] = dest.split('#')
    options.controller = controller
    options.action = action

    @_routes.push(options)

  match: (req) ->
    for route in @_routes
      if req.method is route.method and match = route.pattern.match(req.url)
        segments = (value for own key, value of match)
        return extend({segments}, route)

    false

module.exports = Router
