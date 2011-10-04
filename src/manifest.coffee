
render = require('mustache').to_html
{ joinToFuture, joinMethods } = require 'utils'

Resource = require 'resource'
class Manifest
  constructor: (node, @base) ->
    @name = @base.split('/').pop()

    @resources = { }
    for uri, initializer of @constructor.prototype
      continue if uri == 'constructor' or uri in _.keys Manifest.prototype
      @resources[uri] = new Resource node, uri, initializer(), @

  verify: ->
    return joinMethods.call @, _.values(@resources), 'verify'

  amend: ->
    return joinMethods.call @, _.values(@resources), 'amend'

  # Expand the string in the context of the manifest.
  expand: (str) ->
    render str, @constructor


module.exports = Manifest

