
{ _ } = require 'underscore'
{ statSync } = require 'fs'
path = require 'path'
{ exec } = require 'child_process'

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


class fileScheme
  constructor: (@resource, @uri, @options) ->
    @files = expand @uri.pathname

  apply: ->
    console.log('Validating file ' + @uri.pathname)
    resolveUserID @options.user, (err, uid) =>
      for file in @files
        res = checkFile file, @options.perm, uid
        continue if res

        console.log "File #{ file } failed the check. Running action"
        func = @options.action.call @resource.manifest
        func.call @resource.manifest, @files
        return

  install: (source, options) ->
    console.log options


exports.Scheme = fileScheme

