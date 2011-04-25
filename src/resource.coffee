
schemeRegistry = require 'scheme'

class Resource
  constructor: (@manifest, @uri, @options) ->
    scheme = schemeRegistry[@uri.protocol.replace ':', '']
    @scheme = new scheme @, @uri, @options

  verify: ->
    return @scheme.verify()

  amend: ->
    return @scheme.amend()


module.exports = Resource

