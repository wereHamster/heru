
{ exec } = require 'child_process'
{ joinToFuture } = require 'utils'

module.exports = (template) ->
  return (targets, callback) ->
    join = Futures.join()
    for file in targets
      future = Futures.future()
      exec "touch #{file}", (err) -> future.deliver err
      join.add future

    return joinToFuture join, "touch action"

