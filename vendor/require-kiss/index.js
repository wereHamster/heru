/*jslint onevar: true, undef: true, newcap: true, regexp: true, plusplus: true, bitwise: true, devel: true, maxerr: 50, indent: 2 */
/*global module: true, exports: true, provide: true */
var global = global || (function () { return this; }()),
  __dirname = __dirname || '';
(function () {
  "use strict";

  var thrownAlready = false;

  function ssjsProvide(exports) {
    //module.exports = exports || module.exports;
  }

  function resetModule() {
    global.module = {};
    global.exports = {};
    global.module.exports = exports;
  }

  function normalize(name) {
    if ('./' === name.substr(0,2)) {
      name = name.substr(2);
    }
    return name;
  }

  function browserRequire(name) {
    var mod,
      msg = "One of the included scripts requires '" + 
        name + "', which is not loaded. " +
        "\nTry including '<script src=\"" + name + ".js\"></script>'.\n";

    name = normalize(name);
    mod = global.__REQUIRE_KISS_EXPORTS[name] || global[name];

    if ('undefined' === typeof mod && !thrownAlready) {
      thrownAlready = true;
      alert(msg);
      throw new Error(msg);
    }

    return mod;
  }

  function browserProvide(name, new_exports) {
    name = normalize(name);
    global.__REQUIRE_KISS_EXPORTS[name] = new_exports || module.exports;
    resetModule();
  }

  function browserDefine(id, injects, factory) {
    var module = global.module;
    if (global.module && global.module.id)
    // stolen from https://gist.github.com/650000
    if (!factory) {
      // two or less arguments
      factory = injects;
      if (factory) {
        // two args
        if (typeof id === "string") {
          /*
          if (id !== module.id) {
            throw new Error("Can not assign module to a different id than the current file");
          }
          */
          // default injects
          injects = ["require", "exports", "module"];
        } else{
          // anonymous, deps included
          injects = id;
        }
      } else {
        // only one arg, just the factory
        factory = id;
        injects = ["require", "exports", "module"];
      }
    }
    id = module.id;
    if (typeof factory !== "function"){
      // we can just provide a plain object
      return module.exports = factory;
    }
    var returned = factory.apply(module.exports, injects.map(function (injection) {
      switch (injection) {
        // check for CommonJS injection variables
        case "require": return req;
        case "exports": return module.exports;
        case "module": return module;
        default:
          // a module dependency
          return req(injection);
      }
    }));
    if(returned){
      // since AMD encapsulates a function/callback, it can allow the factory to return the exports.
      module.exports = returned;
    }




    // handle name + factory
    if (undefined === deps) {
      if ('object' === typeof name) {
        factory = name;
      }
    }
    if (undefined === factory) {
      factory = deps;
      deps = name;
      name = undefined;
    }
    if (undefined === factory) {
      factory = deps;
      deps = undefined;
      name = undefined;
    }

    var mods = [];
    deps.forEach(function (dep) {
      mods.push(require(dep));
    });
    factory.apply(null, mods);
  }

  if (global.require) {
    if (global.provide) {
      return;
    }
    global.provide = ssjsProvide;
    global.define = ssjsProvide;
    return;
  }

  global.__REQUIRE_KISS_EXPORTS = global.__REQUIRE_KISS_EXPORTS || {};
  global.require = global.require || browserRequire;
  global.provide = global.provide || browserProvide;
  global.define= global.define || browserProvide;
  resetModule();

  provide('require-kiss');
  define('require-kiss');
}());

