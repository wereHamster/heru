
{ _ } = require 'underscore'
Futures = require 'futures'
schemeRegistry = require 'scheme'
{ expand, joinToFuture } = require 'utils'


# Check whether the list includes the given resource. It uses Resource#cmp
# to compare the resources.
includesResource = (list, res) ->
  return _.any list, (r) -> return r.cmp res


# Return a list of unique resources.
uniqueResources = (resources) ->
  ret = []
  for res in resources
    ret.push(res) unless includesResource ret, res
  return ret


class Resource
  constructor: (@manifest, @uri, @options = {}) ->
    scheme = schemeRegistry[@uri.protocol.replace ':', '']
    @scheme = new scheme @, @uri, @options


  # Methods forwarded to the scheme. Result is cached.
  deps: ->
    @deps = _.once -> uniqueResources @scheme.deps()
    return @deps()

  # Resources to be created after this one is completed.
  post: ->
    @post = _.once -> uniqueResources @scheme.post()
    return @post()

  weak: ->
    @weak = _.once -> @scheme.weak()
    return @weak()

  verify: ->
    future = Futures.future()
    @scheme.verify().when (err) =>
      @incomplete = !!err
      future.deliver err
    return future


  amend: ->
    return @scheme.amend()


  # Helper methods which the resource can use.
  decompose: ->
    @decompose = _.once -> expand @uri.href
    return @decompose()


  # Compare two resources, return a boolean indicating whether the two
  # resources are compatible.
  cmp: (other) ->
    return false if @scheme.constructor != other.scheme.constructor
    return @scheme.cmp other

module.exports = Resource

