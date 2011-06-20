
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

  conflicts = _.any resourceMap, (res, uri) -> return res == null

  if conflicts
    # For each of those conflicts, deliver an error.
    for key, resource of resourceMap
      continue unless resource == null
      future = Futures.future()

      # Maybe we could print the manifests which provided those resources?
      future.deliver new Error "#{key} provided by multiple different resources"

      join.add future
  else
    # No conflict, yay!
    join.add Futures.future().deliver null

  return joinToFuture join, "Integrity check failed"


amendResource = (dispatchTable, resource) ->
  return if resource.amending
  resource.amending = true
  resource.amend().when (err) ->
    dispatchTable[resource.uri.href].future.deliver err

registerCompletionHandler = (dispatchTable, res) ->
  dispatchTable[res.uri.href].join.when (err) ->
    amendResource dispatchTable, res

# Generate a dispatch table where keys are resource URIs and values are
# future objects which can be delivered to.
futureDispatchTable = (resources) ->
  ret = {}
  for res in resources
    join = Futures.join()
    join.add Futures.future().deliver null
    ret[res.uri.href] = { future: Futures.future(), join: join }
  return ret


topologyDispatch = (resources) ->
  dispatchTable = futureDispatchTable resources

  ret = Futures.join()
  addRet = (res, dep) ->
    future = dispatchTable[dep].future
    dispatchTable[res].join.add future
    ret.add future

  for res in resources
    for dep in res.deps()
      addRet res.uri.href, dep

  for res in resources
    registerCompletionHandler dispatchTable, res

  return joinToFuture ret, "topologyDispatch failed"


class Node
  constructor: (@name, @spec)->
    @manifests = (loadModule name for name in spec.manifests)


  # Initialize the node, make sure the resources in this node are consistent
  # and not in conflict.
  init: ->
    @resources = {}
    for manifest in @manifests
      expandResources @resources, _.values(manifest.resources)

    return checkIntegrity @resources


  # The verify stage iterates over all resources and and checks if they are
  # in their desired state. If not, an error is returned through the future.
  verify: ->
    @resources = _.values @resources
    return joinMethods.call @, @resources, 'verify'


  # Fix any incomplete resources.
  amend: ->
    return topologyDispatch @resources


module.exports = Node

