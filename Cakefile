path = require('path')
sys = require('sys')
spawn = require('./build/util.coffee').spawn
exec = require('child_process').exec
execSync = require('./build/util.coffee').execSync
glob = require('glob')
fs = require('fs-extra')
require("sugar")

VERSION = "0.3.1"

packageHelp = "Package Tegh for ubuntu, fedora, brew (osx) and arch"
distroHelp = 'Package only the specific distro [arch|fedora|ubuntu]'
option '-d', '--distro [DISTRIBUTION]', distroHelp

update = (f, opts) ->
  f = "./build/#{f}"
  opts.with ?= VERSION
  content = fs.readFileSync f, encoding: "utf8"
  content = content.replace opts.replace, "$1#{opts.with}"
  fs.writeFileSync f, content
  # Debug output
  msg = "Updating #{f}.."
  console.log "#{msg.padRight(' ', 50 - msg.length)} [ DONE ]"



updateAllPackageVersion = () ->
  update 'arch-src/tegh/PKGBUILD', replace: /(pkgver=)([^\n]*)/
  update 'arch-src/tegh/PKGBUILD', replace: /(pkgrel=)([^\n]*)/, with: 1
  update 'fedora-src/SPECS/tegh.spec', replace: /(Version:\s*)([^\n]*)/
  update 'ubuntu.sh', replace: /(TEGH_VERSION=)([^\n]*)/
  update 'windows.iss', replace: /(AppVersion=)([^\n\r]*)/

task "package", packageHelp, (opts) ->
  updateAllPackageVersion()

  console.log opts.distro
  if opts.distro
    distros = [opts.distro]
  else
    distros = ['osx','fedora', 'ubuntu', 'arch']

  buildDir = path.resolve(__dirname, "build")
  packageDir =  path.resolve __dirname, "bin", "packages"
  fs.removeSync packageDir
  fs.mkdirSync packageDir

  # OSX
  if distros.indexOf('osx') != -1
    brew_tar_path = path.resolve(packageDir, "tegh-#{VERSION}-brew.tar.gz")
    console.log brew_tar_path
    cmd = "tar -cvzf '#{brew_tar_path}'"
    cmd += " --include='doc' --include='bin' --include='src'"
    cmd += " --include='LICENSE' --include='node_modules'"
    cmd += " --exclude='bin/packages'"
    cmd += " ./*"
    console.log cmd
    sha1 = false
    _onData = (error, stdout, stderr) ->
      console.log('stdout: ' + stdout)
      console.log('stderr: ' + stderr)
      console.log('exec error: ' + error) if (error != null)
      if sha1 == false
        sha1 = true
        exec("openssl sha1 #{brew_tar_path}", _onData)
    proc = exec cmd, cwd: __dirname, maxBuffer: 10*1024*1024, _onData

  # Fedora
  if distros.indexOf('fedora') != -1
    FedoraBuild = require "./build/fedora.coffee"
    new FedoraBuild().run()

  # Ubuntu
  if distros.indexOf('ubuntu') != -1
    spawn path.resolve(buildDir, "ubuntu.sh"), cwd: buildDir, ->
      debFile = glob.sync(path.resolve buildDir, "tegh-*.deb")[0]
      fs.rename debFile, path.resolve(packageDir, path.basename debFile)

  # Arch
  if distros.indexOf('arch') != -1
    spawn "tar",
      args: ['-cvzf', path.resolve(packageDir, "tegh-#{VERSION}-arch.tar.gz"), 'tegh']
      cwd: path.resolve(buildDir, 'arch-src')
    spawn "tar",
      args: ['-cvzf', path.resolve(packageDir, 'tegh-git.tar.gz'), 'tegh-git']
      cwd: path.resolve(buildDir, 'arch-src')
