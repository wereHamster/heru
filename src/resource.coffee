
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
    return @scheme.verify()

  amend: ->
    return @scheme.amend()


  # Helper methods which the resource can use.
  decompose: ->
    return expand @uri.href


module.exports = Resource

