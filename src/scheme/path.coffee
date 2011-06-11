
{ _ } = require 'underscore'
fs = require 'fs'
{ statSync } = require 'fs'
path = require 'path'
existsSync = path.existsSync
dirname = path.dirname
{ exec } = require 'child_process'
Futures = require 'futures'
{ expand, joinToFuture } = require 'utils'
url = require 'url'

# Find the UID of the given login and invoken the callback with it.
resolveUserID = (login, callback) ->
  console.log "Resolvind UID of #{ login }"
  exec "id -u #{ login }", (err, stdout, stderr) ->
    if err
      return callback err, null

    callback null, parseInt stdout


# Check if the file exists and has the correct mode and uid. Checking the gid
# is a bit more difficult as there is no easy way to translate a group name to
# its gid. Suggestions are welcome.
checkFile = (file, mode, uid) ->
  try
    stat = statSync file
    return false unless (stat.mode & 0777) == mode
    return false unless stat.uid == uid
  catch error
    return false

  return true

# Run the given command, return a future which will be delivered the err,
# stdout and stderr.
runCommand = (cmd) ->
  future = Futures.future()
  exec cmd, (err, stdout, stderr) ->
    if err
      err.message = err.message.replace '\n', ''
    future.deliver err, stdout, stderr
  return future

chmod = (path, mode) ->
  future = Futures.future()
  fs.chmod path, mode, (err) ->
    if err
      return future.deliver new Error "chmod: #{err.message}"
    future.deliver null
  return future

chown = (path, owner, group) ->
  return runCommand "chown #{ owner }:#{ group } #{ path }"

typeMap =
  file: 'isFile'
  dire: 'isDirectory'

checkType = (path, type) ->
  future = Futures.future()
  try
    stat = statSync path
    if stat[typeMap[type]]()
      future.deliver null
    else
      future.deliver new Error "#{path} has wrong type"
  catch err
    future.deliver err
  return future

verifyPath = (path, options) ->
  future = Futures.future()
  unless existsSync path
    return future.deliver new Error "#{path} does not exist"

  join = Futures.join()
  join.add chmod path, options.mode
  join.add chown path, options.user, options.group
  join.add checkType path, options.type

  return joinToFuture join, "path #{path}"


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
    join = Futures.join()

    join.add chmod path, options.mode
    join.add chown path, options.user, options.group

    tmp = joinToFuture join, "path #{path}"
    tmp.when (err) ->
      future.deliver err

  return future


Resource = null
pathResource = (path) ->
  Resource = require 'resource'
  uri = url.parse "path:#{dirname(path)}"
  return new Resource null, uri,
    type: 'dire', mode: 0755, user: 'root', group: 'root'


class Path
  constructor: (@resource, @uri, @options) ->
    @paths = expand @uri.pathname


  deps: ->
    paths = _.select @paths, (path) -> path != '/'
    paths = _.map paths, pathResource
    paths.push new Resource null, url.parse("group:#{@options.group}")
    paths.push new Resource null, url.parse("user:#{@options.user}")
    return paths

  post: ->
    return []

  weak: ->
    return false

  verify: ->
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
        future = amendDirectory path, @options for path in @paths

      when 'file'
        func = @options.action.call @resource.manifest
        future = func.call @resource.manifest, @paths

      else
        future.deliver new Error "Unknown type: #{@options.type}"

    return future

  cmp: (other) ->
    return _.isEqual @options, other.options


module.exports = Path

