
schemeRegistry = require 'scheme'
{ expand, joinToFuture } = require 'utils'
url = require 'url'


class Resource
  constructor: (uri, @options = { }, @manifest) ->
    @uri = url.parse uri

    scheme = schemeRegistry[@uri.protocol.replace ':', '']
    @scheme = new scheme @, @uri, @options


  # Return the dependencies of this resource, as an array of URIs. These
  # resources must be created before this one. All dependencies must be listed
  # here, even if they are siblings. And not all sibling have to be
  # dependencies.
  deps: ->
    @deps = _.once -> @scheme.deps()
    return @deps()


  # Return resources (instances of the Resource class) which are related to
  # this resource. That can include resources on which this resource depends,
  # or resources which should be created independent of this resource.
  siblings: ->
    @siblings = _.once -> @scheme.siblings()
    return @siblings()


  # Run the verify step. Check whether this resource is correctly present and
  # configured. Return a future which will be delivered the result of this
  # step.
  verify: ->
    future = Futures.future()
    @scheme.verify().when (err) =>
      @incomplete = !!err
      future.deliver err
    return future


  # Run any steps necessary to bring this resource in order. Return a future
  # which will be delivered the result of this step.
  amend: ->
    return @scheme.amend()


  # A single definition in a manifest can describe multiple related resources.
  # This function decomposes the URI into its individual parts.
  decompose: ->
    @decompose = _.once -> expand @uri.href
    return @decompose()


  # Compare two resources, return a boolean indicating whether the two
  # resources are compatible. Resources are equal if they share the same
  # constructor and options.
  cmp: (other) ->
    return false if @scheme.constructor != other.scheme.constructor
    return @scheme.cmp other

module.exports = Resource

