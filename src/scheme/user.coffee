
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


class User

  constructor: (@resource, uri, options) ->
    _.extend @, options

    @login = uri.host
    @uid = 9000 + hash(@login)
    @home ||= "/home/#{@login}"

  deps: ->
    Resource = require 'resource'

    return [
      new Resource null, url.parse("path:#{@home}"),
        type: 'dire', mode: 0755, user: 'root', group: 'wheel'
    ]

  verify: ->
    future = Futures.future()
    exec "id -u #{@login}", (err, stdout, stderr) =>
      if err
        future.deliver err
      else if @uid isnt parseInt stdout
        console.log "#{@uid} - #{stdout}"
        future.deliver new Error "User has incorrect UID"
      else
        future.deliver null
    return future

  amend: ->
    future = Futures.future()
    exec render(cmd, @), (err, stdout, stderr) =>
      future.deliver err
    return future

module.exports = User

