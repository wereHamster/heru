
{ _ } = require 'underscore'
Futures = require 'futures'
{ joinToFuture, joinMethods, expandResources, topoSort } = require 'utils'


# Load the module and instanciate it. Pass it the base path so the module
# knows where to load the assets from.
loadModule = (name) ->
  path = require.resolve name + '/manifest'
  return new (require path)(path.replace '/manifest.coffee', '')


# Check the integrity of the given manifsts. That is, deliver an error if
# two or more manifests provide the same resource.
checkIntegrity = (resourceMap) ->
  join = Futures.join()

  # If an URI is priveded by more than one resource, it's a potential
  # conflict. Select those URIs.
  conflicts = _.select resourceMap, (v) -> v.length > 1

  # For each of those potential conflicts, check if the resources are
  # compatible. If not, it's a real conflict.
  if conflicts.length > 0
    for key, resources of conflicts
      future = Futures.future()

      # Select the really distinct, incompatible resources.
      distinct = _.filter resources, (res) -> !resources[0].cmp res
      if distinct.length > 0
        href = resources[0].uri.href
        count = distinct.length + 1
        future.deliver new Error "#{href} provided by #{count} different resources"
      else
        future.deliver null

      join.add future
  else
    join.add Futures.future().deliver null

  return joinToFuture join, "Integrity check failed"


class Node
  constructor: (@name, @spec)->
    @manifests = (loadModule name for name in spec.manifests)


  # Initialize the node, make sure the resources in this node are consistent
  # and not in conflict.
  #
  # @return future
  init: ->
    @resources = {}
    for manifest in @manifests
      expandResources @resources, _.values(manifest.resources)

    return checkIntegrity @resources


  # Verify the state of this node. If any resource fails to verify, deliver
  # an error.
  #
  # @return future
  verify: ->
    @resources = _.map @resources, (v) -> v[0]
    return joinMethods.call @, @resources, 'verify'


  # Fix any incomplete resources.
  #
  # @return future
  amend: ->
    @resources = topoSort @resources

    resources = {}
    for res in @resources
      continue unless res.incomplete
      console.log res.uri.href
      resources[res.uri.href] = res

    return joinMethods.call @, _.values(resources), 'amend'


module.exports = Node

