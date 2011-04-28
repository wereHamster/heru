
{ _ } = require 'underscore'
Futures = require 'futures'


/* Perform a bash-like brace expansion on the given string. */
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

