
{ _ } = require 'underscore'
Futures = require 'futures'

# Load the module and instanciate it. Pass it the base path so the module
# knows where to load the assets from.
loadModule = (name) ->
  path = require.resolve name + '/manifest'
  return new (require path)(path.replace '/manifest.coffee', '')


joinToFuture = (join, msg) ->
  future = Futures.future()
  join.when ->
    if _.any arguments, ((arg) -> arg[0])
      future.deliver new Error msg
    else
      future.deliver null
  return future

class Node
  constructor: (spec)->
    @manifests = (loadModule name for name in spec.manifests)

  verify: ->
    console.log 'node verify'
    console.log @manifests
    join = Futures.join()
    @manifests[0].verify()
    join.add manifest.verify() for manifest in @manifests
    return joinToFuture join, "Node verify failed"

  amend: ->
    join = Futures.join()
    join.add manifest.amend() for manifest in @manifests
    return joinToFuture join, "Node amend failed"


module.exports = Node

