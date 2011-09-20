
{ joinToFuture, joinMethods, expandResources, topoSort } = require 'utils'


# Load the module and instanciate it. Pass it the base path so the module
# knows where to load the assets from.
loadModule = (name) ->
  path = require.resolve name + '/manifest'
  return new (require path)(path.replace '/manifest.coffee', '')

loadModules = (name) ->
  a = name.split '/'
  return (loadModule a.slice(0, i + 1).join '/' for unused, i in a)


# Check the integrity of the resources. That is, deliver an error if two or
# more manifests provide the same resource.
checkIntegrity = (resourceMap) ->
  join = Futures.join()
  join.add Futures.future().deliver null

  # For each conflict, deliver an error.
  for key, resource of resourceMap
    continue unless resource == null

    # Maybe we could print the manifests which provided those resources?
    future = Futures.future()
    join.add future.deliver new Error "#{key} provided by multiple resources"

  return joinToFuture join, "Integrity check failed"


# Run the amend() method on the resource, when it's done, deliver the result
# to its corresponding future, so dependent resources can run.
amendResource = (dispatchTable, resource) ->
  return if resource.amending
  resource.amending = true

  resource.amend().when (err) ->
    dispatchTable[resource.uri.href].future.deliver err


# Register a handler on the join for the given resource. When the join is
# delivered to, it means all dependencies for that resource have been
# completed, so we can continue with this resource.
registerCompletionHandler = (dispatchTable, res) ->
  dispatchTable[res.uri.href].join.when (err) ->
    amendResource dispatchTable, res


# Generate a dispatch table where keys are resource URIs and values are
# future/join objects. There is one dummy future in each join so that
# resources without dependencies can run right away.
futureDispatchTable = (resources) ->
  ret = {}
  for res in resources
    join = Futures.join()
    join.add Futures.future().deliver null
    ret[res.uri.href] = { future: Futures.future(), join: join }
  return ret


# This is the core of the logic, It makes sure that all resources are amended
# in the correct order.
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
    @manifests = []
    for name in spec.manifests
      for module in loadModules name
        @manifests.push module


  # Initialize the node, expand all resources and make sure that they are
  # consisten and there are no conflicts.
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

