
{ exec } = require 'child_process'
{ to_html: render } = require 'mustache'
{ idHash } = require 'utils'


# Command to create or update the user.
cmd = '''
  ( id "{{ name }}" 1>/dev/null 2>&1 || useradd -g "{{ name }}" "{{ name }}" ) &&
  usermod -L -u "{{ uid }}" -g "{{ name }}" -G "{{ group }}" -d "{{ home }}" "{{ name }}";
'''

class User

  constructor: (@resource, @uri, @options) ->
    @options.name = uri.host

    @options.uid = idHash(@options.name) unless @options.uid?
    @options.home = "/home/#{@options.name}" unless @options.home?


  deps: ->
    return [ "group:#{@options.name}" ]

  siblings: ->
    Resource = require 'resource'
    homeDir = new Resource @resource.node, "path:#{@options.home}",
      type: 'dire', mode: 0750, user: @options.name, group: @options.name

    group = new Resource @resource.node, "group:#{@options.name}",
      gid: @options.uid

    return [ homeDir, group ]

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

