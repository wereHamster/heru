
schemeRegistry = require 'scheme'
Utils = require 'utils'
{ expand, joinToFuture } = Utils

class Resource
  constructor: (@manifest, @uri, @options) ->
    scheme = schemeRegistry[@uri.protocol.replace ':', '']
    @scheme = new scheme @, @uri, @options

  # Return the dependencies of this resource.
  deps: ->
    return @scheme.deps()

  # Return an array of URIs which this resource provides.
  decompose: ->
    return expand @uri.href

  verify: ->
    return @scheme.verify()

  amend: ->
    return @scheme.amend()


module.exports = Resource

