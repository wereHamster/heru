
path = require 'path'
child = require 'child_process'
{ to_html: render } = require 'mustache'
{ basename } = require 'utils'

scriptTemplate = '''
  mkdir -p /tmp/heru && cd /tmp/heru && curl -sLO {{ source }} &&
  tar -xf {{ file }} && cd /tmp/heru/{{ dir }}/ && {{ command }}
'''

module.exports = (source, options) ->
  console.log "Installing #{source}"

  return (targets) ->
    future = Futures.future()

    file = path.basename(source)
    ctx = { source: source, file: file, dir: basename(file), command: options.command }
    script = render scriptTemplate, ctx

    child.exec script, (err, stdout, stderr) ->
      console.log "Completed #{source}: #{err}"
      future.deliver err

    return future

