
What is it?
-----------

Heru, in its heart, is a DSL to describe the state of a UNIX system. You
specify which files, user accounts, groups etc. should exist. If the system
does not match the desired state, heru takes actions to correct that.

In that regard it's very similar to [puppet][puppet]. In fact, much of heru
was directly inspired by puppet. However, there are significant differences.
The most important is that heru aims to be standalone. The goal is to not have
any external dependencies. Just drop it into a folder and you're ready to go.
Also, heru does not provide you with any infrastructure. You are expected to
use whatever tools you are already using to distribute the configuration
files. These two things together make heru very small, lightweight and
hopefully easier to configure.


How does it work?
-----------------

First you have to describe your hosts (nodes). Each node has its own file,
and contains the network configuration and manifests which should be applied
to it. A manifest is a collection of one or more resources which should be
present.

Let's take a closer look. A node description might look something like this:

    exports.manifests = [
      'sshd', 'mysql'
    ]

The `sshd` manifest might describe that the file `/etc/ssh/sshd_config` needs
to exist, have certain permissions and contents:

    { Manifest, Action } = require 'heru'
    class module.exports extends Manifest

      'file:/etc/ssh/sshd_config': ->
        perm: 0644, user: 'root', group: 'root', action: ->
          Action.Render 'sshd_config'

If the file does not exist, heru will create it. The `Render` action takes the
`sshd_config` template file and writes it to its correct location. There are
other actions which you can use, and there are also cases where you don't have
to specify an action.

If the syntax seems familiar to you, it's maybe because heru and all its
configuration files are written in [Coffee-Script][coffee-script]. 


How do I install it?
--------------------

I recommend that you install heru into your `/root/.heru` folder, with the
following structure:

    runtime/  - The heru runtime (clone this repo here)
    library/  - Library with your manifests
    nodes/    - Node descriptions

Then you need to install [Node.js][nodejs] and [Coffee-Script][coffee-script].
Node.js is fairly easy to compile (`./configure --without-ssl && make`). You
can clone Coffee-Script into a directory and then add its `bin/` folder to
your path. In due time there will be a fully automated install script.


I like it, how do I help you?
-----------------------------

This project has its home on [GitHub][github]. You can create tickets, fork
the project and send me pull requests. 


[puppet]: http://projects.puppetlabs.com/projects/puppet
[coffee-script]: http://jashkenas.github.com/coffee-script
[nodejs]: http://nodejs.org/
[github]: https://github.com/wereHamster/heru

