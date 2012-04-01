// So that we can transparently require coffee-script.
require('coffee-script');

// Export often-used modules to the global namespace, so we don't have to
// include them each time.
global._       = require('underscore')._
global.Futures = require('futures');

module.exports = require('./src/heru');
