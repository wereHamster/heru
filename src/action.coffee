
# Actions are executed in the context of the manifest. This means you can
# use `this` to access properties and methods of the manifest.

for action in [ 'Touch', 'Render', 'Install', 'Execute', 'Fail' ]
  exports[action] = require "action/#{ action.toLowerCase() }"

