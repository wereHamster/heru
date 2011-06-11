
{ _ } = require 'underscore'
{ exec } = require 'child_process'
Futures = require 'futures'


system = Futures.future()
exec 'uname -s', (err, stdout, stderr) ->
  system.deliver err, stdout.toLowerCase().replace('\n', '')


run = (method, name) ->
  future = Futures.future()
  system.whenever (err, system) ->
    cmd = "#{__dirname}/spkg/#{system} '#{method}' '#{name}'"
    exec cmd, (err, stdout, stderr) ->
      if err
        future.deliver new Error "spkg #{method} #{name} failed"
      else
        future.deliver null

  return future


class spkg

  constructor: (@resource, uri, options) ->
    _.extend @, options
    @name = uri.host

  deps: ->
    return []

  post: ->
    return []

  weak: ->
    return false

  verify: ->
    return run 'verify', @name

  amend: ->
    return run 'amend', @name

module.exports = spkg

