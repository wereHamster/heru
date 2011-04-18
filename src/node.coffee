
# Load the module and instanciate it. Pass it the base path so the module
# knows where to load the assets from.
loadModule = (name) ->
  path = require.resolve name + '/manifest'
  new (require path)(path.replace '/manifest.coffee', '')


class Node
  constructor: (@spec)->

  apply: ->
    for name in @spec.manifests
      console.log "Loading module #{ name }"
      loadModule(name).apply()


module.exports = Node

