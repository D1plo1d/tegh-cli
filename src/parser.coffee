# Array Format: test a b c
# Hash Format: test a: 3 b: 10 c: 3
# Hash (with an @) Format: test a: 1 b: 34 @ 10
sugar = require 'sugar'

setKeys =
  fan: 'f'
  conveyor: 'c'
  motors: 'motors'

preprocessArgument = (arg) ->
  arg = arg.trim()
  arg = parseFloat(arg) if arg.match /^\-?[\d\.]+$/
  arg = true if arg == 'on'
  arg = false if arg == 'off'
  return arg

# Parses a set command and returns a object that can be sent to a tegh
# server.
parseSetArguments = (args) ->
  args[1] = args[1].remove(':') if typeof args[1] == 'string'
  args[0] = 'e0' if args[0] == 'e'
  args[0] = setKeys[args[0]] unless args[0][0] == 'e' or args[0][0] == 'b'
  switch args[1]
    when 'temp'
      attrName = 'target_temp'
      value = args[2]
    when true, false
      throw "Error: Invalid command" if args.length > 2
      attrName = 'enabled'
      value = args[1]
    else
      throw "Error: Invalid command"
  # Creating the data
  ( ( data = {} )[args[0]] = {} )[attrName] = value
  return data

postProcess = (msg) -> switch msg.action
  when "extrude"
    msg.action = "move"
  when "rm_job"
    msg.action = "rm"
    msg.data = "jobs[#{msg.data.id}]"
  when "home"
    msg.data = ['x', 'y', 'z'] if msg.data == null
  when "change_job"
    msg.action = "set"
    data = {}
    data["jobs[#{msg.data.id}]"] = Object.reject msg.data, "id"
    msg.data = data

toJSON = (msg) ->
  action = msg.toLowerCase().words()[0]
  msg = msg.replace "@", "at:" if action == "move" or action == "extrude"
  msg = msg.replace(/\:/g, ": ").replace(/\s+/g, " ") if action != "add_job"
  words = msg.words()
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
      key = args[i].remove(':').replace(/e$/, 'e0')
      val = args[i+1]
      data[key] = val
  else
    data = args
  if data?.at? and ( action == "move" or action == "extrude" )
    data.at = parseFloat(data.at.replace?("%", "")||""+data.at)/100
  outputMsg = action: action, data: data
  postProcess outputMsg
  console.log outputMsg
  return JSON.stringify outputMsg

module.exports = toJSON: toJSON
