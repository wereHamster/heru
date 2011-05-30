
{ _ } = require 'underscore'
Futures = require 'futures'


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

# Return a future which will be delivered the result of the join. If any
# of the tasks in the join fail, the future fails.
exports.joinToFuture = joinToFuture = (join, msg) ->
  future = Futures.future()

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

  return future


exports.joinMethods = (collection, method) ->
  join = Futures.join()
  join.add member[method]() for member in collection
  return joinToFuture join, "#{@constructor.name} '#{@name}' :: #{method}"


# Expand the resources and store them in the map. This method is recursive.
exports.expandResources = (map, resources) ->
  for resource in resources
    for key in resource.decompose()
      map[key] = (map[key] || [])
      unless _.any(map[key], (res) -> res.cmp resource)
        map[key].push resource

    exports.expandResources map, resource.deps()


exports.topoSort = (resources) ->
  L = []

  visit = (res) ->
    return if res.visited

    res.visited = true
    ideps = _.select resources, (r1) ->
      return _.any r1.deps(), (r2) -> r2.uri.href == res.uri.href

    L.push res
    visit m for m in ideps

  S = _.select resources, (res) -> res.deps().length == 0
  visit(res) for res in S

  return L


exports.idHash = (str) ->
  return _.reduce _.map(str.split(''), (c) ->
    c.charCodeAt(0) - 97
  ), (s, v) -> s + v

