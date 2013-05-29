os = require "os"
exec = require("child_process").exec

console.log os.platform()
console.log os.platform()
console.log os.platform()
console.log os.platform()
console.log os.platform()
if os.platform().indexOf("linux") > -1
  exec "npm install git://github.com/izaakschroeder/node-avahi.git"
else
  exec "npm install mdns"
