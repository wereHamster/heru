
{ _ } = require 'underscore'
{ exec } = require 'child_process'
Futures = require 'futures'

class spkg

  constructor: (@resource, uri, options) ->
    _.extend @, options
    @name = uri.host

  verify: ->
    future = Futures.future()
    exec "brew info #{@name} | grep -q 'Not installed'", (err, stdout, stderr) =>
      if err
        future.deliver null
      else
        future.deliver new Error "Package #{@name} not installed"
    return future

  amend: ->
    future = Futures.future()
    exec "brew install #{@name}", (err, stdout, stderr) =>
      if err
        error = new Error "Package #{@name} failed to install"
        error.children = [ err ]
        future.deliver error
      else
        future.deliver null
    return future

module.exports = spkg

