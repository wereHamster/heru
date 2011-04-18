
fs = require 'fs'
{ join, basename } = require 'path'
{ _ } = require 'underscore'


registry = { }

basedir = __dirname + '/scheme/'
fs.readdir basedir, (err, files) ->
  for file in files
    path = join basedir, file
    scheme = basename file, '.coffee'
    callbacks = registry[scheme] || []
    registry[scheme] = require(path).Scheme
    callback registry[scheme] for callback in callbacks


exports.get = (scheme, callback) ->
  if _.isFunction registry[scheme]
    callback registry[scheme]
  else
    registry[scheme] || registry[scheme] = []
    registry[scheme].push (scheme) ->
      callback scheme

