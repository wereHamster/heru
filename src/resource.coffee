
{ _ } = require 'underscore'
Futures = require 'futures'
schemeRegistry = require 'scheme'
{ expand, joinToFuture } = require 'utils'
url = require 'url'


class Resource
  constructor: (uri, @options = { }, @manifest) ->
    @uri = url.parse uri

    scheme = schemeRegistry[@uri.protocol.replace ':', '']
    @scheme = new scheme @, @uri, @options


  # Methods forwarded to the scheme. Result is cached.
  deps: ->
    @deps = _.once -> @scheme.deps()
    return @deps()

  # Resources to be created after this one is completed.
  post: ->
    @post = _.once -> @scheme.post()
    return @post()

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
    @decompose = _.once -> expand @uri.href
    return @decompose()


  # Compare two resources, return a boolean indicating whether the two
  # resources are compatible.
  cmp: (other) ->
    return false if @scheme.constructor != other.scheme.constructor
    return @scheme.cmp other

module.exports = Resource

