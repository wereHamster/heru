
fs = require 'fs'
{ join, existsSync } = require 'path'


module.exports = (template) ->
  return (targets, callback) ->
    for file in targets
      fs.writeFileSync file, ''

    future = Futures.future()
    future.deliver null
    return future

