
{ joinToFuture, joinMethods, expandResources, topoSort } = require 'utils'



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
  if res.incomplete
    dispatchTable[res.uri.href].join.when (err) ->
      amendResource dispatchTable, res
  else
    dispatchTable[res.uri.href].future.deliver null


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


# ---------------------------------------------------------------------------
# Loading manifest and resources
# ---------------------------------------------------------------------------

# Expand the manifest list. Entries such as 'base/ubuntu/10.04' are expanded to
# [ 'base', 'base/ubuntu', 'base/ubuntu/10.04' ].
expandManifestList = (manifests) ->
  return _.flatten _.map manifests, (v) ->
    a = v.split '/'; a.slice(0, i + 1).join '/' for unused, i in a

# Load the manifest and instanciate it. Pass it the base path so the manifest
# knows where to load the assets from.
loadManifest = (node, name) ->
  path = require.resolve name + '/manifest'
  return new (require path)(node, path.replace '/manifest.coffee', '')

# Map manifests to the resources within it.
mapResources = (manifests, map = {}) ->
  expandResources map, _.values manifest.resources for manifest in manifests
  return map


# ---------------------------------------------------------------------------
# The Node class
# ---------------------------------------------------------------------------

class Node

  # Initialize the node with the spec and expand all resources.
  constructor: (@name, @spec)->
    manifests = _.map (expandManifestList spec.manifests), (m) => loadManifest @, m
    @resourceMap = mapResources manifests

  # Return the resource corresponding to the given key.
  getResource: (key) ->
    return @resourceMap[key]

  # The verify stage iterates over all resources and and checks if they are
  # in their desired state. If not, an error is returned through the future.
  verify: ->
    resources = _.values @resourceMap

    future = Futures.future()
    checkIntegrity(@resourceMap).when (err) =>
      return future.deliver err if err

      joinMethods.call(@, resources, 'verify').when (err) =>
        future.deliver err

    return future


  # Fix any incomplete resources.
  amend: ->
    return topologyDispatch _.values @resourceMap


module.exports = Node

