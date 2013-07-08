path = require('path')
sys = require('sys')
spawn = require('./build/util.coffee').spawn
execSync = require('./build/util.coffee').execSync
glob = require('glob')
fs = require('fs-extra')
require("sugar")

packageHelp = "Package Tegh for ubuntu, fedora, brew (osx) and arch"
distroHelp = 'Package only the specific distro [arch|fedora|ubuntu]'
option '-d', '--distro [DISTRIBUTION]', distroHelp

task "package", packageHelp, (opts) ->
  console.log opts.distro
  distros = if opts.distro then [opts.distro] else ['fedora', 'ubuntu', 'arch']
  buildDir = path.resolve(__dirname, "build")
  packageDir =  path.resolve __dirname, "bin", "packages"
  fs.removeSync packageDir
  fs.mkdirSync packageDir

  # Fedora
  if distros.indexOf('fedora') != -1
    FedoraBuild = require "./build/fedora.coffee"
    new FedoraBuild().run()

  # Ubuntu
  if distros.indexOf('ubuntu') != -1
    spawn path.resolve(buildDir, "ubuntu.sh"), cwd: buildDir
    debFile = glob.sync(path.resolve buildDir, "tegh-*.deb")[0]
    fs.copy debFile, path.resolve(packageDir, path.basename debFile)

  # Arch
  if distros.indexOf('arch') != -1
    spawn "tar",
      args: ['-cvzf', path.resolve(packageDir, 'tegh.tar.gz'), 'tegh']
      cwd: path.resolve(buildDir, 'arch-src')
