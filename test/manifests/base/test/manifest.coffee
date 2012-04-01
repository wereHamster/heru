
{ Manifest, Action } = require 'heru'
class module.exports extends Manifest

  'user:bob': ->
    uid: 42, group: 'staff', home: '/home/bob'
