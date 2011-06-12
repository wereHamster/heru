
{ _ } = require 'underscore'
{ exec } = require 'child_process'
url = require 'url'
{ to_html: render } = require 'mustache'
Futures = require 'futures'
{ idHash } = require 'utils'


# Command to create or update the user.
cmd = '''
  ( id "{{ name }}" 1>/dev/null 2>&1 || useradd "{{ name }}" ) &&
  usermod -L -u "{{ uid }}" -g "{{ group }}" -d "{{ home }}" "{{ name }}";
'''

uidBase =
  'staff' : 1000
  'daemon': 9000

class User

  constructor: (@resource, @uri, @options) ->
    @options.name = uri.host

    base = uidBase[@options.group || 'daemon']
    @options.uid = base + idHash(@options.name) unless @options.uid?
    @options.home = "/home/#{@options.name}" unless @options.home?


  deps: ->
    Resource = require 'resource'
    group = new Resource url.parse("group:#{@options.name}"),
      weak: @options.weak, gid: @options.uid

    return [ group ] unless @options.weak

  post: ->
    Resource = require 'resource'
    homeDir = new Resource url.parse("path:#{@options.home}"),
      weak: true, type: 'dire', mode: 2700, user: @options.name, group: @options.name

    return [ homeDir ] unless @options.weak

  weak: ->
    return @options.weak

  verify: ->
    future = Futures.future()
    exec "id -u #{@options.name}", (err, stdout, stderr) =>
      if err
        future.deliver err
      else if @options.uid isnt parseInt stdout
        future.deliver new Error "User #{@options.name} has incorrect UID"
      else
        future.deliver null
    return future

  amend: ->
    future = Futures.future()
    exec render(cmd, @options), (err, stdout, stderr) =>
      future.deliver err
    return future

  cmp: (other) ->
    return _.isEqual @options, other.options


module.exports = User

