
fs = require 'fs'
{ to_html: render} = require('mustache')
{ join, existsSync } = require 'path'

mkdirp = (path) ->
  parts = path.split('/')
  parts.pop()
  console.log parts
  cwd = '/'
  console.log 'mkdir: ' + path
  for part in parts
    cwd = join(cwd, part)
    console.log cwd
    unless existsSync cwd
      fs.mkdirSync cwd, 0755

module.exports = (template) ->
  return (targets, callback) ->
    if targets.length isnt 1
      throw new Error('Can only render a single file')

    file = targets[0]
    console.log 'Rendering ' + template

    console.log @base + '/assets/' + template
    contents = fs.readFileSync @base + '/assets/' + template
    console.log 'contents: '
    renderedData = render contents + '', @constructor
    console.log renderedData
    try
      mkdirp targets[0]
      fs.writeFileSync targets[0], render('' + contents, @constructor)
    catch error
      console.log error
      console.log 'error while writing ' + targets[0]

