extend = (obj, rest...) ->
  for o in rest when o
    obj[key] = val for own key, val of o

  obj

clone = (obj, rest...) -> extend({}, obj, rest...)

ClassHelpers = (klass) ->
  klass.extend = (extensions...) ->
    cls = class extends @

    for objOrFn in extensions
      switch typeof objOrFn
        when "object"
          extend(cls.prototype, objOrFn)
        when "function"
          objOrFn.call(cls)

    cls

  klass::bind = (fn, curry...) -> fn.bind(@, curry...)

jacksonVersion = require(__dirname + '/../package.json').version

module.exports = {clone, extend, ClassHelpers, jacksonVersion}
