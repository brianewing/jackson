path = require('path')

urlPattern = require('url-pattern')
{extend} = require('./util')

class Router
  constructor: ->
    @routes = []

  resource: (pattern, controller, options) ->
    dest = (action) -> [controller, action].join '#'

    @route('GET', pattern, dest('index'), options)
    @route('GET', path.join(pattern, ":id"), dest('show'), options)
    @route('POST', pattern, dest('create'), options)
    @route(['POST', 'PUT', 'PATCH'], path.join(pattern, ":id"), dest('update'), options)
    @route('DELETE', pattern, dest('delete'), options)

  route: (method, pattern, dest, options) ->
    if method instanceof Array
      for m in method
        @route.call(@, m, Array::slice.call(arguments, 1)...)
      return

    if not dest or typeof dest is 'object' # called like route('/pattern', dest, [options])
      [method, pattern, dest, options] = ['GET', method, pattern, dest]

    options ||= {}
    options.method = (options.method || method).toUpperCase()
    options.pattern = urlPattern.newPattern(pattern)

    if typeof dest is 'string' and dest.indexOf('#') isnt -1
      [controller, action] = dest.split('#')
      options.controller = controller
      options.action = action
    else if typeof dest is 'function'
      options.fn = dest
    else
      throw new Error("Bad destination: #{dest}. Must be a function or a string like 'Controller#action'")

    @routes.push(options)

  match: (method, url) ->
    for route in @routes when route.method is method
      if match = route.pattern.match(url)
        return extend(params: match, route)

    false

module.exports = Router
