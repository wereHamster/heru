
fs = require 'fs'
{ to_html: render} = require('mustache')
{ join, existsSync } = require 'path'
Futures = require 'futures'

# Create directories leading up to `path`.
mkdirp = (path) ->
  console.log "Creating directory leading up to #{ path }"

  parts = path.split('/')
  parts.pop()

  cwd = '/'
  for part in parts
    cwd = join(cwd, part)
    fs.mkdirSync cwd, 0755 unless existsSync cwd


module.exports = (template) ->
  return (targets, callback) ->
    if targets.length isnt 1
      throw new Error('Can only render a single file')

    file = targets[0]
    mkdirp file

    contents = fs.readFileSync @base + '/assets/' + template
    renderedData = render contents + '', @constructor
    fs.writeFileSync file, render('' + contents, @constructor)

    future = Futures.future()
    future.deliver null
    return future

