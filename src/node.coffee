
{ _ } = require 'underscore'
Futures = require 'futures'
{ joinToFuture, joinMethods } = require 'utils'


# Load the module and instanciate it. Pass it the base path so the module
# knows where to load the assets from.
loadModule = (name) ->
  path = require.resolve name + '/manifest'
  return new (require path)(path.replace '/manifest.coffee', '')


# Expand the resources and store them in the map. This method is recursive.
expandResources = (map, resources) ->
  for resource in resources
    for key in resource.decompose()
      map[key] = (map[key] || [])
      unless _.any(map[key], (res) -> res.cmp resource)
        map[key].push resource

    expandResources map, resource.deps()

# Check the integrity of the given manifsts. That is, deliver an error if
# two or more manifests provide the same resource.
checkIntegrity = (resourceMap) ->
  # If a resource is priveded by more than one manifest, it's a conflict.
  conflicts = _.select resourceMap, (v) ->
    return v.length > 1

  # Deliver one error for each conflict.
  join = Futures.join()
  if conflicts.length > 0
    for key, resources of conflicts
      future = Futures.future()

      filtered = _.filter resources, (res) -> !resources[0].cmp res
      if filtered.length > 0
        href = resources[0].uri.href
        count = filtered.length + 1
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

  init: ->
    @resources = {}
    for manifest in @manifests
      expandResources @resources, _.values(manifest.resources)

    return checkIntegrity @resources

  verify: ->
    return joinMethods.call @, @manifests, 'verify'

  amend: ->
    return joinMethods.call @, @manifests, 'amend'


module.exports = Node

