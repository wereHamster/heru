
{ _ } = require 'underscore'
fs = require 'fs'
path = require 'path'

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

class fileScheme
  constructor: (@resource, @uri, @options) ->
    @files = expand @uri.pathname

  apply: ->
    console.log __dirname
    console.log('Validating file ' + @uri.pathname)

    if true || _.any(@files, (file) -> !path.existsSync(file))
      console.log 'failed'
      func = @options.action.call @resource.manifest
      func.call @resource.manifest, @files

  install: (source, options) ->
    console.log options


exports.Scheme = fileScheme

