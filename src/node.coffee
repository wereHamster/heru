
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

  # If an URI is priveded by more than one resource, it's a conflict.
  conflicts = {}
  _.each resourceMap, (v, k) ->
    conflicts[k] = v if v.length > 1

  if _.values(conflicts).length > 0
    # For each of those conflicts, deliver an error.
    for key, resources of conflicts
      future = Futures.future()

      # Maybe we could print the manifests which provided those resources?
      count = resources.length
      future.deliver new Error "#{key} provided by #{count} different resources"

      join.add future
  else
    # No conflict, yay!
    join.add Futures.future().deliver null

  return joinToFuture join, "Integrity check failed"


uniqueResources = (resources) ->
  map = {}
  for res in resources
    map[res.uri.href] = res

  return _.values map

amendResource = (dispatchTable, resource) ->
  resource.amend().when (err) ->
    dispatchTable[resource.uri.href].deliver err
  return dispatchTable[resource.uri.href]


# Generate a dispatch table where keys are resource URIs and values are
# futere objects which can be delivered to.
futureDispatchTable = (resources) ->
  ret = {}
  for res in resources
    ret[res.uri.href] = { future: Futures.future(), join: Futures.join() }
  return ret


topologyDispatch = (resources) ->
  dispatchTable = futureDispatchTable()

  ret = Futures.join()
  addRet = (res, future) ->
    dispatchTable[res.uri.href].join.add future
    ret.add future

  for res in resources
    for dep in res.deps()
      addRet res, dispatchTable[dep.uri.href].future

    for post in res.post()
      addRet post, dispatchTable[res.uri.href].future

  for res in resources
    if res.deps().length == 0
      dispatchTable[res.uri.href].future.deliver null

    dispatchTable[res.uri.href].join.when (err) ->
      ((r) -> amendResource dispatchTable, r)(res)

  return joinToFuture ret, "topologyDispatch failed"

removeWeakResources = (resources) ->
  for res, index in resources
    if res.weak()
      resources.splice(index, index)


class Node
  constructor: (@name, @spec)->
    @manifests = (loadModule name for name in spec.manifests)


  # Initialize the node, make sure the resources in this node are consistent
  # and not in conflict.
  init: ->
    @resources = {}
    for manifest in @manifests
      expandResources @resources, _.values(manifest.resources)

      for resource in _.values(manifest.resources)
        expandResources @resources, resource.deps()
        expandResources @resources, resource.post()

    # Filter out weak resources
    for uri, resources of @resources
      console.log "#{uri}: #{resources.length}"
      removeWeakResources resources

    return checkIntegrity @resources


  # The verify stage iterates over all resources and and checks if they are
  # in their desired state. If not, an error is returned through the future.
  verify: ->
    @resources = uniqueResources _.map @resources, (v, k) -> v[0]
    return joinMethods.call @, @resources, 'verify'


  # Fix any incomplete resources.
  amend: ->
    return topologyDispatch @resources


module.exports = Node

