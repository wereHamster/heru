
{ get } = require __dirname + '/scheme'

class Resource
  constructor: (@manifest, @uri, @options) ->

  validate: ->
    get @uri.protocol.replace(':', ''), (scheme) =>
      @scheme = new scheme @, @uri, @options
      @scheme.apply (err, exists) ->
        console.log err


module.exports = Resource

