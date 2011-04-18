
{ _ } = require 'underscore'
render = require('mustache').to_html
child = require 'child_process'


# Command to check, create and update the user
cmd = '''
  ( id {{ login }} 1>/dev/null 2>&1 || useradd {{ login }} ) &&
  usermod -L -u {{ uid }} -g {{ group }} -d {{ home }} {{ login }}
'''

# Generate an UID for the given login
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

    try
      child.exec render(cmd, @), (err, stdout, stderr) =>
        callback(err)
    catch error
      console.log error


exports.Scheme = userScheme

