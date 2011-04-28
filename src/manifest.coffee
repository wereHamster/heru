
{ _ } = require 'underscore'
url = require 'url'
render = require('mustache').to_html
Futures = require 'futures'
{ joinToFuture } = require 'utils'

Resource = require 'resource'
class Manifest
  constructor: (@base) ->
    @name = @base.split('/').pop()
    console.log "Base directory for #{ @name }: #{ @base }"

    @resources = { }
    for uri, initializer of @constructor.prototype
      continue if uri == 'constructor' or uri in _.keys Manifest.prototype
      @resources[uri] = new Resource @, url.parse(uri), initializer()

  verify: ->
    console.log 'manifest verify'
    join = Futures.join()
    join.add res.verify() for uri, res of @resources
    return joinToFuture join, "Manifest verify failed"

  amend: ->
    join = Futures.join()
    join.add res.amend() for uri, res of @resources
    return joinToFuture join, "Manifest amend failed"

  # Expand the string in the context of the manifest.
  expand: (str) ->
    render str, @constructor


module.exports = Manifest

