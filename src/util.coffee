_extend = (obj, rest) ->
  for o in rest when o
    obj[key] = val for own key, val of o

  obj

exports.extend = (obj, rest...) -> _extend(obj, rest)
exports.clone = (objs...) -> _extend({}, objs)

exports.addClassHelpers = (klass) ->
  klass.extend = (extensions...) ->
    cls = class extends @

    for objOrFn in extensions
      switch typeof objOrFn
        when "object"
          _extend(cls.prototype, [objOrFn])
        when "function"
          objOrFn.call(cls)

    cls

  klass::bind = (fn, curry...) -> fn.bind(@, curry...)

exports.jacksonVersion = require(__dirname + '/../package.json').version
