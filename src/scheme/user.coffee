
{ _ } = require 'underscore'
{ exec } = require 'child_process'
{ to_html: render } = require 'mustache'


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

class userScheme

  constructor: (@resource, uri, options) ->
    _.extend @, options

    @login = uri.host
    @uid = 9000 + hash(@login)

  apply: (callback) ->
    console.log('Validating user ' + @login)

    exec render(cmd, @), (err, stdout, stderr) =>
      callback(err)


exports.Scheme = userScheme

