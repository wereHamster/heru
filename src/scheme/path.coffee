
fs = require 'fs'
{ statSync } = require 'fs'
path = require 'path'
existsSync = path.existsSync
dirname = path.dirname
{ exec } = require 'child_process'
{ expand, joinToFuture, idHash } = require 'utils'

typeMap =
  file: 'isFile'
  dire: 'isDirectory'

verifyPath = (path, options) ->
  future = Futures.future()
  unless existsSync path
    return future.deliver new Error "#{path} does not exist"

  stat = statSync path
  if not stat[typeMap[options.type]]()
    return future.deliver new Error "#{path} has wrong type"
  if (stat.mode & 0777) isnt options.mode
    return future.deliver new Error "#{path} has wrong mode"
  if stat.uid isnt options.uid or stat.gid isnt options.gid
    return future.deliver new Error "#{path} has wrong uid/gid"

  return future.deliver null

# Take a function which takes arguments and a standard callback, and return
# a future which will be delivered the result.
callbackToFuture = (func, args...) ->
  future = Futures.future()
  args.push((err) -> future.deliver err); func args...
  return future

applyPathOptions = (path, options) ->
  join = Futures.join()

  # Preserve SUID, SGID and sticky bit
  mode = (statSync(path).mode & 07000) | (options.mode & 0777)
  join.add callbackToFuture fs.chmod, path, mode
  join.add callbackToFuture fs.chown, path, options.uid, options.gid

  return joinToFuture join, "applyPathOptions #{path}"

createDirectory = (path) ->
  future = Futures.future()
  if existsSync path
    future.deliver null
  else
    fs.mkdir path, 0700, (err) -> future.deliver err
  return future

amendDirectory = (path, options) ->
  future = Futures.future()

  createDirectory(path).when (err) ->
    return future.deliver err if err
    applyPathOptions(path, options).when (err) ->
      future.deliver err

  return future


pathResource = (node, path) ->
  Resource = require 'resource'
  return new Resource node, "path:#{path}",
    priority: 0, type: 'dire', mode: 0755, user: 'root', group: 'root'


# ---------------------------------------------------------------------------
class Path

  constructor: (@resource, @uri, @options) ->
    @node = resource.node
    @paths = expand @uri.pathname

  deps: ->
    paths = _.map @siblings(), (res) -> res.uri.href
    return paths.concat([ "user:#{@options.user}", "group:#{@options.group}" ])

  siblings: ->
    paths = _.select _.uniq(_.map(@paths, (path) -> dirname(path))), (path) -> path isnt '/'
    return _.map paths, (path) => pathResource @node, path

  verify: ->
    @options.uid = @node.getResource("user:#{@options.user}").options.uid
    @options.gid = @node.getResource("group:#{@options.group}").options.gid

    unless @options.type in ['dire', 'file']
      future = Futures.future()
      return future.deliver new Error "Unknown path type #{@options.type}"

    join = Futures.join()
    join.add verifyPath path, @options for path in @paths
    return joinToFuture join, "scheme #{@uri.href}"


  amend: ->
    future = Futures.future()

    switch @options.type
      when 'dire'
        if @options.action
          func = @options.action.call @resource.manifest
          func.call(@resource.manifest, @paths).when (err) =>
            return future.deliver err if err

            join = Futures.join()
            join.add applyPathOptions path, @options for path in @paths
            joinToFuture(join, "scheme #{@uri.href}").when (err) =>
              future.deliver err
        else
          join = Futures.join()
          join.add amendDirectory path, @options for path in @paths
          joinToFuture(join, "scheme #{@uri.href}").when (err) =>
            future.deliver err

      when 'file'
        func = @options.action.call @resource.manifest
        func.call(@resource.manifest, @paths).when (err) =>
          return future.deliver err if err

          join = Futures.join()
          join.add applyPathOptions path, @options for path in @paths
          joinToFuture(join, "scheme #{@uri.href}").when (err) =>
            future.deliver err

      else
        future.deliver new Error "Unknown type: #{@options.type}"

    return future

  cmp: (other) ->
    return _.isEqual @options, other.options


module.exports = Path

