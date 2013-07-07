#!/usr/bin/env coffee
path = require('path')
sys = require('sys')
spawn = require('./util.coffee').spawn
execSync = require('./util.coffee').execSync
glob = require('glob')
fs = require('fs-extra')
require("sugar")

fedoraRoot = path.resolve __dirname, "fedora-src"

module.exports = class FedoraBuild
  args: [
    "-ba",
    "--define", "_topdir #{fedoraRoot}",
    "--define", "_datadir /usr/share",
    "--define", "_bindir /usr/bin",
    "--target",
    "noarch-redhat-linux",
    path.resolve(fedoraRoot, 'SPECS', 'tegh.spec')
  ]

  constructor: (@callback) ->

  run: =>
    console.log @args
    previousRpm = @_rpmPath()
    fs.unlinkSync previousRpm if previousRpm?
    spawn "rpmbuild", args: @args, @postBuild

  _rpmPath: -> glob.sync(path.resolve fedoraRoot, "RPMS/noarch/tegh-*.rpm")[0]

  postBuild: =>
    @package = @_rpmPath()
    throw "Fedora package not built" unless @package?
    basename = path.basename @package
    binPath = path.resolve(__dirname, '..', 'bin', 'packages', basename)
    fs.copy @package, binPath
    @callback?()


# new FedoraBuild().run()
