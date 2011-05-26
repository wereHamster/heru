
fs = require 'fs'
{ to_html: render} = require('mustache')
{ join, existsSync } = require 'path'
Futures = require 'futures'


module.exports = (template) ->
  return (targets, callback) ->
    if targets.length isnt 1
      throw new Error('Can only render a single file')

    contents = fs.readFileSync @base + '/assets/' + template
    renderedData = render contents + '', @constructor
    fs.writeFileSync targets[0], render('' + contents, @constructor)

    future = Futures.future()
    future.deliver null
    return future

