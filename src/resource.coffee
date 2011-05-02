
schemeRegistry = require 'scheme'
Utils = require 'utils'
{ expand, joinToFuture } = Utils

class Resource
  constructor: (@manifest, @uri, @options) ->
    scheme = schemeRegistry[@uri.protocol.replace ':', '']
    @scheme = new scheme @, @uri, @options

  decompose: ->
    return expand @uri.href

  verify: ->
    return @scheme.verify()

  amend: ->
    return @scheme.amend()


module.exports = Resource

