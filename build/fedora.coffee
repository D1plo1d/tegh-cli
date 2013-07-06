#!/usr/bin/env coffee
path = require('path')
sys = require('sys')
_exec = require('child_process').exec
stdout = process.stdout

fedoraRoot = path.resolve __dirname, "fedora-src"
specFile = path.resolve fedoraRoot, 'SPECS', 'tegh.spec'

console.log(fedoraRoot)

puts = (error, stdout, stderr) ->
  sys.puts(stdout)
  sys.puts(stderr)

exec = (s) -> _exec(s, puts)

# mv ./fedora-src/SOURCES/tegh-master.tar.gz ./fedora-src/SOURCES/master.tar.gz
exec """
  rpmbuild --define "_topdir #{fedoraRoot}" -ba #{specFile}
"""
