# Array Format: test a b c
# Hash Format: test a: 3 b: 10 c: 3
# Hash (with an @) Format: test a: 1 b: 34 @ 10
sugar = require 'sugar'

setKeys = (key) -> switch key
  when "fan" then 'f'
  when "conveyor" then 'c'
  else key

sufix =  " Try typing 'help'."

preprocessArgument = (arg) ->
  arg = arg.trim()
  arg = parseFloat(arg) if arg.match /^\-?[\d\.]+$/
  arg = true if arg == 'on'
  arg = false if arg == 'off'
  return arg

parseAddJob = (msg) ->
  action: "add_job"
  data: msg.replace(/^add_job/, "").trim()

parseRmJob = (msg) ->
  action: "rm"
  data: msg.words()[1].toLowerCase().trim()

# Parses a set command and returns a object that can be sent to a tegh
# server.
parseSetArgs = (args) ->
  args[0] = setKeys args[0]
  # Creating the data
  data = {}
  data[args[0]] = switch args[1]
    when 'temp'
      throw "Invalid command.#{sufix}" if args.length != 3
      enabled: true
      target_temp: args[2]
    when true, false
      throw "Invalid command.#{sufix}" if args.length != 2
      enabled: args[1]
    else
      (h = {})[args[1]] = args[2]
      h
  return data

parseObjArgs = (args) ->
  throw "Invalid arguments.#{sufix}" if args.length % 2 != 0
  data = {}
  for i in [0..args.length-1]
    continue if i.isOdd()
    key = args[i]
    val = args[i+1]
    data[key] = val
  return data

postProcess = (msg) -> switch msg.action
  when "home"
    msg.data = ['x', 'y', 'z'] if msg.data.length == 0
  when "move", "extrude"
    msg.action = "move"
    return unless msg.data.at?
    msg.data.at = parseFloat(msg.data.at.toString().replace?("%", ""))/100

module.exports = toJSON: (msg, commands) ->
  words = msg.toLowerCase().words()
  action = words[0]
  cmd = commands[action]
  needsArgs = cmd.argTree?
  # Parse add_job and rm_job first since they're the only non-space delimited 
  # actions.
  return parseAddJob msg if action == "add_job"
  return parseRmJob msg if action == "rm_job"
  # Fail fast
  if !cmd?
    throw "#{action} is not a valid command.#{sufix}"
  if words.length > 1 and !needsArgs
    throw "#{action} does not take any arguments.#{sufix}"
  if words.length < 3 and needsArgs and action != "home"
    throw "#{action} requires an argument.#{sufix}"
  # Sanatizing the string into an easily parsable form
  msg = msg.replace "@", "at " if action == "move" or action == "extrude"
  msg = msg.replace(/\:\s*|\s+/g, " ").replace(/\ e\ /g, ' e0 ')
  # Regenerating the words with the sanatized string
  words = msg.toLowerCase().words()
  # Extracting and preprocessing the arguments
  args = words[1..].compact().map preprocessArgument
  # Creating the output message object
  outputMsg = action: action
  if cmd.argTree? then outputMsg.data = switch action
    when 'home' then args
    when 'set' then parseSetArgs(args)
    else parseObjArgs(args)
  # Running command-specific post processing
  postProcess outputMsg
  return outputMsg
