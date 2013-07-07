path = require('path')
sys = require('sys')
spawn = require('child_process').spawn
_execSync = require('exec-sync')
stdout = process.stdout
glob = require('glob')
fs = require('fs')
require("sugar")

module.exports =
  # verbose spawn (with callbacks as well)
  spawn: (cmd, options = {}, cb) ->
    args = options.args || []
    delete options.args
    console.log cmd
    console.log "#{cmd} #{args.map((s) -> "\"#{s}\"").join(' ')}"
    proc = spawn cmd, args, options

    printStream = (stream) ->
      proc[stream].on 'data', (data) -> stdout.write data

    printStream(stream) for stream in ['stdout', 'stderr']

    proc.on "exit", cb if cb?
    return proc

  # verbose execSync
  execSync: (cmd) -> console.log _execSync(cmd)
