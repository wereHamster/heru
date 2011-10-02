
fs = require 'fs'
{ parse } = require 'url'
http = require 'http'
sys = require 'sys'
child = require 'child_process'
path = require 'path'
{ basename } = require 'utils'

download = (url, callback) ->
  { hostname, pathname } = parse url
  filename = pathname.split("/").pop()

  client = http.createClient 80, hostname
  req = client.request 'GET', pathname, host: hostname

  req.on 'response', (res) ->
      res.setEncoding('binary')
      downloadfile = fs.createWriteStream filename, flags: 'w+', mode: 0600
      res.on 'data', (chunk) ->
        downloadfile.write(chunk, encoding='binary');
      res.on 'end', ->
        downloadfile.end();
        sys.puts("Finished downloading " + filename);
        callback null, filename

  req.on 'error', (err) ->
    callback err, null

  req.end()

unpack = (url, callback) ->
  download url, (err, filename) ->
    child.exec "tar -xf #{ filename }", (err, stdout, stderr) ->
      callback err, basename filename

install = (url, options, callback) ->
  unpack url, (err, dir) ->
    process.chdir dir
    child.exec options.command, (err, stdout, stderr) ->
      console.log 'done installing'
      callback err

module.exports = (source, options) ->
  console.log 'install action'
  console.log source

  return (targets) ->
    future = Futures.future()
    install source, options, (err) ->
      console.log err
      future.deliver err
    return future

