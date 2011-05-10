
{ _ } = require 'underscore'
fs = require 'fs'
{ statSync } = require 'fs'
path = require 'path'
existsSync = path.existsSync
{ exec } = require 'child_process'
Futures = require 'futures'
{ joinToFuture } = require 'utils'

expand = (path) ->
  tokens = _.compact path.split /({|}|,)/

  merge = (array, element) ->
    (el + element) for el in array

  collect = (tokens) ->
    ret = []

    current = [ '' ]
    while token = tokens.shift()
      if token == ','
        ret.push current
        current = [ '' ]
      else if token == '{'
        current = _.flatten(merge current, t for t in collect tokens)
      else if token == '}'
        break
      else
        current = merge current, token

    ret.push current
    return _.flatten(ret)

  return collect tokens


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

verifyPath = (path, options) ->
  future = Futures.future()
  unless existsSync path
    return future.deliver new Error "#{path} does not exist"

  join = Futures.join()
  join.add chmod path, options.mode
  join.add chown path, options.user, options.group

  return joinToFuture join, "Verification of #{path} failed"

class Path
  constructor: (@resource, @uri, @options) ->
    @paths = expand @uri.pathname

  verify: ->
    join = Futures.join()
    join.add verifyPath path, @options for path in @paths
    return joinToFuture join, "Verification of #{@uri.pathname} failed"

  amend: ->
    if @options.type is 'dire'
      future = Futures.future()
      fs.mkdir @paths[0], @options.mode, (err) ->
        future.deliver err
      return future
    else
      func = @options.action.call @resource.manifest
      func.call @resource.manifest, @paths


module.exports = Path

