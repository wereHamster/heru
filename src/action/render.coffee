
fs = require 'fs'
{ to_html: render} = require('mustache')
{ join, existsSync } = require 'path'


module.exports = (template) ->
  return (targets, callback) ->
    contents = fs.readFileSync @base + '/assets/' + template
    renderedData = render contents + '', @constructor
    for file in targets
      fs.writeFileSync file, render('' + contents, @constructor)

    future = Futures.future()
    future.deliver null
    return future

