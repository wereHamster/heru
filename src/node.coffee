
{ _ } = require 'underscore'
Futures = require 'futures'
{ joinToFuture } = require 'utils'

# Load the module and instanciate it. Pass it the base path so the module
# knows where to load the assets from.
loadModule = (name) ->
  path = require.resolve name + '/manifest'
  return new (require path)(path.replace '/manifest.coffee', '')

class Node
  constructor: (@name, @spec)->
    @manifests = (loadModule name for name in spec.manifests)

  verify: ->
    join = Futures.join()
    join.add manifest.verify() for manifest in @manifests
    return joinToFuture join, "Node '#{@name}' verify failed"

  amend: ->
    join = Futures.join()
    join.add manifest.amend() for manifest in @manifests
    return joinToFuture join, "Node '#{@name}' amend failed"


module.exports = Node

