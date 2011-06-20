
{ _ } = require 'underscore'
{ exec } = require 'child_process'
url = require 'url'
{ to_html: render } = require 'mustache'
Futures = require 'futures'


# Command to create or update the group.
cmd = '''
  GID="$(grep "{{ name }}" /etc/group | cut -f3 -d: )"
  if test -z "$GID"; then
    groupadd -g "{{ gid }}" "{{ name }}"
  elif test "$GID" -ne "{{ gid }}"; then
    groupmod -g "{{ gid }}" "{{ name }}"
  fi
'''


class Group

  constructor: (@resource, @uri, @options) ->
    @options.name = uri.host


  deps: ->
    return []

  post: ->
    return []

  verify: ->
    future = Futures.future()
    exec "grep #{@options.name} /etc/group | cut -f3 -d:", (err, stdout, stderr) =>
      if err
        future.deliver err
      else if @options.gid and @options.gid isnt parseInt stdout
        future.deliver new Error "Group #{@options.name} has incorrect GID"
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


module.exports = Group

