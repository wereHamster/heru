
{ _ } = require 'underscore'
url = require 'url'
render = require('mustache').to_html

Resource = require 'resource'
class Manifest
  constructor: (@base) ->
    @name = @base.split('/').pop()
    console.log "Base directory for #{ @name }: #{ @base }"

    @resources = { }
    for uri, initializer of @constructor.prototype
      continue if uri == 'constructor' or uri in _.keys Manifest.prototype
      @resources[uri] = new Resource @, url.parse(uri), initializer()

  apply: ->
    for uri, res of @resources
      console.log "Validating #{ uri }"
      res.validate()

  # Expand the string in the context of the manifest.
  expand: (str) ->
    render str, @constructor


module.exports = Manifest

