
Futures = require 'futures'
schemeRegistry = require 'scheme'
{ expand, joinToFuture } = require 'utils'

class Resource
  constructor: (@manifest, @uri, @options) ->
    scheme = schemeRegistry[@uri.protocol.replace ':', '']
    @scheme = new scheme @, @uri, @options


  # Methods forwarded to the scheme.
  deps: ->
    return @scheme.deps()

  verify: ->
    future = Futures.future()
    @scheme.verify().when (err) =>
      @incomplete = !!err
      future.deliver err
    return future


  amend: ->
    return @scheme.amend()


  # Helper methods which the resource can use.
  decompose: ->
    return expand @uri.href

  # Compare two resources, return a boolean indicating whether the two
  # resources are compatible.
  cmp: (other) ->
    return false if @scheme.constructor != other.scheme.constructor
    return @scheme.cmp other

module.exports = Resource

