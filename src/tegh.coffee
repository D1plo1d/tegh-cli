EventEmitter = require('events').EventEmitter
util = require 'util'
require 'sugar'
glob = require 'glob'
ansi = require 'ansi'
readline = require 'readline'
ConstructClient = require './construct/client'
ServiceSelector = require './service_selector'
fs = require "fs-extra"
touch = require "touch"
path = require ("flavored-path")

stdout = process.stdout
stdin = process.stdin

clear = -> `util.print("\u001b[2J\u001b[0;0f")`

getUserHome = ->
  process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE

longestPrefix = (a, b) ->
  for i in [1..a.length]
    return a[0..-i] if b.startsWith(a[0..-i])

class CliConsole
  historyPath: "#{getUserHome()}/.construct_history"

  constructor: (@src) ->
    @cursor = ansi(stdout)

    @rl = readline.createInterface
      input: stdin
      output: stdout
      completer: @src._autocomplete
      terminal: true

    # loading the user's readline history
    touch.sync @historyPath
    @rl.history = (fs.readFileSync(@historyPath)).toString().split("\n")

    clear()
    @render(false)
    @rl.setPrompt("> ", 2)
    @rl.prompt()

    @rl.on "line", @_onLine
    @rl.on 'SIGINT', @_onSIGINT
    process.on 'exit', @_onExit
    stdout.on 'resize', @render
    stdin.on 'data', @_onData

  _onLine: (line) =>
    @src._parseLine(line)
    @render(false)
    @rl.prompt()

  _onSIGINT: =>
    if @rl.line == ""
      process.exit()
    else
      stdout.write("\n")
      @rl.line = ""
      @rl.prompt()

  _onData: (char) =>
    process.exit() if char == `'\4'`

  _onExit: =>
    fs.writeFileSync @historyPath, @rl.history.join("\n")
    stdout.write("\n")

  updateSize: ->
    @width = stdout.columns
    @height = stdout.rows-2

  render: (restore = true) =>
    stdin.pause()
    @updateSize()

    header = @src._header()
    c = @cursor

    c.savePosition().goto(0, 0)
    c.black().bg.white()
    c.write(header.padRight(" ", @width - header.length))
    c.reset().bg.reset()

    c.goto(0, @height+2).show()
    c.restorePosition() if restore
    stdin.resume()


class Tegh
  commands: require './help'

  constructor: ->
    new ServiceSelector().on "select", @_onServiceSelect
    @_sensors = {}

  _onServiceSelect: (service) =>
    clear()
    port = 8888
    stdout.write "Connecting to #{service.address}:#{port}..."
    @client = new ConstructClient(service.address, port)
      .on("connect", @_onConnect)
      .on("sensor_changed", @_onSensorChanged)
      .on("jobs", @_onJobsList)
      .on("job_upload_complete", @_onJobUploadComplete)
      .on("close", @_onClose)
    # @client = new ConstructClient(service.host[0..-2], service.port)

  _onConnect: =>
    @cli = new CliConsole(@)

  _onSensorChanged: (data) =>
    @_sensors[data.name] = data.value
    @cli.render()

  _onClose: =>
    console.log("Server disconnected.")
    process.exit()

  _onJobsList: (jobs) =>
    @cli.rl.pause()
    stdout.write("\r")
    console.log "Print Jobs:\n"
    for job, i in jobs
      name = job.file_name
      id = job.id.toString()
      prefix = "  #{i}) #{name} "
      suffix = "job ##{job.id.pad(5)}  "
      console.log "#{prefix.padRight(".", @cli.width - suffix.length - prefix.length - 1)} #{suffix}"
    console.log ""
    @cli.rl.prompt()
    @cli.rl.resume()

  _onJobUploadComplete: (statusCode) =>
      @cli.rl.pause()
      if statusCode = 200
        status = "Job added."
      else
        status = "Error adding job."
      process.stdout.write("\r" + status + "\n")
      @cli.rl.prompt()
      @cli.rl.resume()


  _header: ->
    fields = []
    for k, v of @_sensors
      fields.push "#{k.capitalize()}: #{v}\u00B0C"
    fields.join("  ")

  _append: (s, prefix = "") ->
    stdout.write(prefix + s + "\n")

  _parseLine: (line) =>
    line = line.toString()
    words = line.split(/\s/)
    cmd = words.shift()
    if cmd == "help" then @_appendHelp(words[0])
    else if cmd == "exit" then return process.exit()
    else if @commands[cmd]?
      try
        @client.send(line)
      catch e
        @_append "Error: #{e}"
    else
      @_append """
        Error: '#{cmd}' is not a valid command.
        Try typing 'help' for more info.
      """
    @cli.render()

  _appendHelp: (cmd) ->
    return @_appendSpecificHelp(cmd) if cmd?
    help = """
      Help
      #{"".padLeft("-", @cli.width)}
      The following commands are available on your printer,
      to learn more about a specific command type help <CMD>\n\n
    """

    for cmd, data of @commands
      desc = data.description.split("\n")
      help += "- #{cmd.padRight(" ", 12 - cmd.length)} - #{desc.shift()}\n"
      help += "#{d.padLeft(" ", 12+5)}\n" for d in desc

    @_append("")
    @_append(help)
    @_append("")

  _appendSpecificHelp: (cmd) ->
    cmd_info = @commands[cmd]
    return @_append("Invalid Command: #{cmd}") unless cmd_info?
    help = """
      Help: #{cmd}
      #{"".padLeft("-", @cli.width)}
      #{cmd_info.description}\n
    """

    for type in ["required", "optional"]
      continue unless cmd_info["#{type}_args"]
      help += "\n"
      help += "#{type.capitalize()} Arguments:\n"
      help += (cmd_info["#{type}_args"]).map((arg) -> "  - #{arg}\n").join("")

    if cmd_info.examples?
      help += "Example Useage:\n"
      help += "  - #{name}: #{ex}\n" for name, ex in cmd_info.examples

    @_append("")
    @_append(help)

  _autocomplete: (line) =>
    out = []
    words = line.split(" ")
    # Command Autocompletion
    if words.length == 1
      out = @_autocomplete_cmd(line)
    # Help Autocomplete
    if words[0] == "help"
      out = @_autocomplete_cmd words[1..].join(" "), "help "
      out[0] = out[0].trim()
    # Directory Autocompletion
    if words[0] == "add_job"
      return @_autocomplete_dir out, words, line
    else
      return [out, line]

  _autocomplete_cmd: (line, prefix = "") ->
    out = []
    for cmd, data of @commands
      out.push "#{prefix}#{cmd}" if cmd.startsWith(line)
    out[0] = out[0] + " " if out.length == 1
    out

  _autocomplete_dir: (out, words, line) ->
    # Creating a glob to find files that start with the path
    # the user is building.
    words[1] = "~" if words[1] == "~/"
    relative = (words[1]||"").indexOf("~") == 0
    absPath = path.get (words[1..]||[""]).join(" ")

    out = glob(absPath + "*", sync: true).filter (p) ->
      p.endsWith(/\.gcode|.ngc/) or fs.lstatSync(p).isDirectory()

    # Attempting to find a common prefix in all the matched paths and 
    # autocomplete that prefix.
    shortest = out.reduce longestPrefix, out[0]
    # console.log shortest
    # console.log shortest
    # console.log shortest
    absPath = shortest if shortest? and shortest.length > absPath.length

    # If there is only 1 result set the current REPL line to it's 
    # value.
    if out.length == 1
      absPath = out[0]
      out[0] = ""

    isDirectory = fs.existsSync(absPath) and fs.lstatSync(absPath).isDirectory()
    absPath += '/' if !absPath.endsWith("/") and isDirectory
    @cli.rl.line = line = "add_job #{absPath}"
    @cli.rl.cursor = line.length
    return [out, line]


new Tegh()