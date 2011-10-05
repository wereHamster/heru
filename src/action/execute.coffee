
child = require 'child_process'

module.exports = (cmd) ->
  return (targets) ->
    future = Futures.future()
    child.exec cmd, (err, stdout, stderr) -> future.deliver err
    return future

