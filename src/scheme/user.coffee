
{ _ } = require 'underscore'
{ exec } = require 'child_process'
url = require 'url'
{ to_html: render } = require 'mustache'
Futures = require 'futures'


# Command to check, create and update the user. It is ugly, because it's
# nothing more than a shell script which we run. Unfortunately there is no
# native interface to the user or group databases in nodejs, so that's the
# only choice we have.
cmd = '''
  ( id {{ login }} 1>/dev/null 2>&1 || useradd {{ login }} ) &&
  usermod -L -u {{ uid }} -g {{ group }} -d {{ home }} {{ login }};

  test -d {{ home }} || mkdir -p {{ home }}
  chown {{ login }}:{{ group }} {{ home }} && chmod 0700 {{ home }}
'''


# Generate an UID for the given login.
hash = (login) ->
  _.reduce _.map(login.split(''), (c) ->
    c.charCodeAt(0) - 97
  ), (s, v) -> s + v

uidBase =
  'daemon': 9000

class User

  constructor: (@resource, @uri, @options = {}) ->
    @options.login = uri.host

    base = uidBase[@options.group || 'daemon']
    @options.uid  ||= base + hash(@options.login)
    @options.home ||= "/home/#{@options.login}"

  deps: ->
    Resource = require 'resource'

    return [
      new Resource null, url.parse("path:#{@options.home}"),
        type: 'dire', mode: 0755, user: @options.login, group: 'wheel'
    ]

  verify: ->
    future = Futures.future()
    exec "id -u #{@options.login}", (err, stdout, stderr) =>
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

