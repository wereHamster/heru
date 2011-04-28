
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
exports.joinToFuture = (join, msg) ->
  future = Futures.future()

  join.when ->
    args = Array.prototype.slice.call arguments
    errors = _.select args, (e) -> e && e[0]
    if errors.length > 0
      future.deliver new Error(msg), errors
    else
      future.deliver null

  return future

