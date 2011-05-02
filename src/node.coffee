
{ _ } = require 'underscore'
Futures = require 'futures'
{ joinToFuture, joinMethods } = require 'utils'


# Load the module and instanciate it. Pass it the base path so the module
# knows where to load the assets from.
loadModule = (name) ->
  path = require.resolve name + '/manifest'
  return new (require path)(path.replace '/manifest.coffee', '')

# Check the integrity of the given manifsts. That is, deliver an error if
# two or more manifests provide the same resource.
checkIntegrity = (manifests) ->
  # Collect the resources which the manifests provide
  resourceMap = {}
  for manifest in manifests
    for unused, resource of manifest.resources
      for res in resource.decompose()
        if resourceMap[res]
          resourceMap[res].push res
        else
          resourceMap[res] = [ resource ]

  # If a resource is priveded by more than one manifest, it's a conflict.
  conflicts = _.select _.values(resourceMap), (e) ->
    return e.length > 1

  # Deliver one error for each conflict.
  future = Futures.future()
  if conflicts.length > 0
    for conflict in _.flatten conflicts
      future.deliver new Error "Conflict in #{conflict}"
  else
    future.deliver null

  return future


class Node
  constructor: (@name, @spec)->
    @manifests = (loadModule name for name in spec.manifests)

  bootstrap: ->
    return checkIntegrity @manifests

  verify: ->
    return joinMethods.call @, @manifests, 'verify'

  amend: ->
    return joinMethods.call @, @manifests, 'amend'


module.exports = Node

