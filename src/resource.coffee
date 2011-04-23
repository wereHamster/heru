
schemeRegistry = require 'scheme'

class Resource
  constructor: (@manifest, @uri, @options) ->

  validate: ->
    scheme = schemeRegistry[@uri.protocol.replace(':', '')]
    @scheme = new scheme @, @uri, @options
    @scheme.apply (err, exists) ->
      console.log err


module.exports = Resource

