
{ _ } = require 'underscore'
Futures = require 'futures'
{ joinToFuture, joinMethods } = require 'utils'


# Load the module and instanciate it. Pass it the base path so the module
# knows where to load the assets from.
loadModule = (name) ->
  path = require.resolve name + '/manifest'
  return new (require path)(path.replace '/manifest.coffee', '')

checkIntegrity = (manifests) ->
  resourceMap = {}

  for manifest in manifests
    for unused, resource of manifest.resources
      for res in resource.decompose()
        if resourceMap[res]
          return new Error "Resource #{res} is already provided"

        resourceMap[res] = resource

  return null

class Node
  constructor: (@name, @spec)->
    @manifests = (loadModule name for name in spec.manifests)

  bootstrap: ->
    # Bootstrap all modules
    future = joinMethods.call @, @manifests, 'bootstrap'

    # If everything was successful, check the integrity 
    ret = Futures.future()
    future.when (err) =>
      if err
        ret.deliver err
      else
        err = checkIntegrity @manifests
        if err
          ret.deliver err
        else
          ret.deliver null

    return ret

  verify: ->
    return joinMethods.call @, @manifests, 'verify'

  amend: ->
    return joinMethods.call @, @manifests, 'amend'


module.exports = Node

