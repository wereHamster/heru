
url = require 'url'
{ expand } = require './utils'

# ----------------------------------------------------------------------------
# A resource is a file, user or group (other types may follow in the future).
# The supplied options describe the particular resource in detail. The actual
# implementation of the resource logic (how to verify its presence, what to do
# if the resource does not exist etc) is defined in the scheme files.
# ----------------------------------------------------------------------------

class Resource
  constructor: (@node, uri, @options = { }, @manifest) ->
    @uri = url.parse uri

    scheme = require "./scheme/#{@uri.protocol.replace ':', ''}"
    @scheme = new scheme @, @uri, @options


  # Return the dependencies of this resource, as an array of URIs. These
  # resources must be created before this one. All dependencies must be listed
  # here, even if they are siblings. And not all sibling have to be
  # dependencies.
  deps: ->
    @deps = _.once -> @scheme.deps().concat(@options.deps ? [])
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
    return @scheme.verify().when (err) =>
      @incomplete = !!err


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
    return @scheme.cmp other.scheme


  # The priority is used when merging resources to figure out which one should
  # take precedence. Priority is a number between 0 and 9 (inclusive). If
  # unspecified, then the priority is 3.
  priority: ->
    return if @options.priority? then @options.priority else 3


  # Merge two resources based on their priority and the compare function.
  @merge: (r1, r2) ->
    return null if r1 is null or r2 is null

    if r1.priority() == r2.priority()
      return r1.cmp(r2) and r1 or null

    return r1.priority() > r2.priority() and r1 or r2


module.exports = Resource

