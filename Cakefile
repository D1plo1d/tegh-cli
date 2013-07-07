path = require('path')
sys = require('sys')
spawn = require('./build/util.coffee').spawn
execSync = require('./build/util.coffee').execSync
glob = require('glob')
fs = require('fs-extra')
require("sugar")


task "package", "Package Tegh for ubuntu, fedora, brew (osx) and arch", ->
  buildDir = path.resolve(__dirname, "build")
  packageDir =  path.resolve __dirname, "bin", "packages"
  fs.removeSync packageDir
  fs.mkdirSync packageDir

  # Fedora
  FedoraBuild = require "./build/fedora.coffee"
  new FedoraBuild().run()

  # Ubuntu
  spawn path.resolve(buildDir, "ubuntu.sh"), cwd: buildDir
  debFile = glob.sync(path.resolve buildDir, "tegh-*.deb")[0]
  fs.copy debFile, path.resolve(packageDir, path.basename debFile)

  # Arch
  spawn "tar",
    args: ['-cvzf', path.resolve(packageDir, 'tegh.tar.gz'), 'tegh/PKGBUILD.txt']
    cwd: path.resolve(buildDir, 'arch-src')