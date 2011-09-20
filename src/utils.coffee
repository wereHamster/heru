
# Perform a bash-like brace expansion on the given string.
exports.expand = (str) ->
  merge = (array, element) ->
    (el + element) for el in array

  collect = (tokens) ->
    ret = []

    current = [ '' ]
    while token = tokens.shift()
      if token == ','
        ret.push current
        current = [ '' ]
      else if token == '{'
        current = _.flatten(merge current, t for t in collect tokens)
      else if token == '}'
        break
      else
        current = merge current, token

    ret.push current
    return _.flatten(ret)

  return collect _.compact str.split /({|}|,)/

exports.propagateErrors = (join, future, msg) ->
  join.when ->
    args = Array.prototype.slice.call arguments
    errors = _.compact _.map args, (e) -> e[0]
    if msg and errors.length > 0
      error = new Error msg
      error.children = errors
      future.deliver error
    else
      args = _.map args, (e) -> e.slice(1)
      args.unshift null
      future.deliver.apply this, args

# Return a future which will be delivered the result of the join. If any
# of the tasks in the join fail, the future fails.
exports.joinToFuture = joinToFuture = (join, msg) ->
  future = Futures.future()
  exports.propagateErrors join, future, msg
  return future


exports.joinMethods = (collection, method) ->
  join = Futures.join()
  join.add member[method]() for member in collection
  return joinToFuture join, "#{@constructor.name} '#{@name}' :: #{method}"


# Expand the resources and store them in the map. This method is recursive.
exports.expandResources = (map, resources) ->
  for resource in resources
    n = 0
    for key in resource.decompose()
      continue if map[key] == null

      res = map[key]
      if _.isUndefined(res)
        map[key] = resource
        n = n + 1
      else if !resource.cmp(res)
        map[key] = null

    if (n > 0)
      exports.expandResources map, resource.siblings()


exports.idHash = (str) ->
  codes = _.map str.split(''), (c) -> c.charCodeAt(0) - 97
  return _.reduce codes, ((s, v) -> s + v), 0

