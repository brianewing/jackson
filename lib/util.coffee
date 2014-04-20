exports.extend = (obj, rest...) ->
  for o in rest when o
    obj[key] = val for own key, val of o

  obj

exports.clone = (obj, rest...) -> extend({}, obj, rest...)
