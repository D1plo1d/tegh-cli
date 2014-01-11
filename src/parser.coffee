# Array Format: test a b c
# Hash Format: test a: 3 b: 10 c: 3
# Hash (with an @) Format: test a: 1 b: 34 @ 10
sugar = require 'sugar'

setKeys =
  fan: 'f'
  conveyor: 'c'

preprocessArgument = (arg) ->
  arg = arg.trim()
  arg = parseFloat(arg) if arg.match /^[\d\.]+$/
  arg = true if arg == 'on'
  arg = false if arg == 'off'
  return arg

# Parses a set command and returns a object that can be sent to a tegh
# server.
parseSetArguments = (args) ->
  args[1] = args[1].remove(':')
  args[1] = 'e0' if args[1] == 'e'
  if args[0] == 'temp'
    [key1, key2] = [ args[1], 'target_temp' ]
  else
    [key1, key2] = [ setKeys[args[0]], args[1] ]
  # Creating the data
  ( ( data = {} )[key1] = {} )[key2] = args[2]
  return data

toJSON = (msg) ->
  words = msg.replace(":", ": ").words()
  args = words[1..].compact().map preprocessArgument

  # Figure out if the arguments are a hash
  isHash = true
  for i in [0..args.length-1]
    continue unless key = args[i]
    isHash &&= i.isOdd() or key.match(/[^:]+:|@/)?

  if words.length < 2
    data = null
  else if words[0] == 'set'
    data = parseSetArguments(args)
  else if isHash
    data = {}
    for i in [0..args.length-1]
      continue if i.isOdd()
      key = args[i].remove(':').replace('@', 'at').replace(/e$/, 'e0')
      val = args[i+1]
      data[key] = val
  else
    data = args
  # console.log data
  return JSON.stringify
    action: words[0]
    data: data

module.exports = toJSON: toJSON
