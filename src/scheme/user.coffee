
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

  constructor: (@resource, @uri, @options = {}) ->
    @options.name = uri.host

    base = uidBase[@options.group || 'daemon']
    @options.uid  ||= base + idHash(@options.name)
    @options.home ||= "/home/#{@options.name}"

  deps: ->
    Resource = require 'resource'

    return [
      new Resource null, url.parse("path:#{@options.home}"),
        type: 'dire', mode: 0755, user: @options.name, group: 'wheel'
    ]

  verify: ->
    future = Futures.future()
    exec "id -u #{@options.name}", (err, stdout, stderr) =>
      if err
        future.deliver err
      else if @options.uid isnt parseInt stdout
        future.deliver new Error "User has incorrect UID"
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

