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
  drive = process.env.HOMEDRIVE || ""
  drive + (process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE)

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
    stdout.write "To see a list of commands, type help\n"
    @rl.setPrompt("> ", 2)
    @rl.prompt()

    @rl.on "line", @_onLine
    @rl.on 'SIGINT', @_onSIGINT
    process.on 'exit', @_onExit
    stdout.on 'resize', @render
    stdin.on 'data', @_onData

  _onLine: (line) =>
    return if @src.client.blocking
    @src._parseLine(line)
    @render(false)
    if @src.client.blocking
      @rl.pause()
    else
      @rl.prompt()

  _onSIGINT: =>
    if @rl.line == ""
      process.exit()
    else
      stdout.write("\n")
      @rl.line = ""
      @rl.prompt()
      stdin.resume()

  _onData: (key) =>
    process.exit() if key == '\u0003' or key == `'\4'`

  _onExit: =>
    fs.writeFileSync @historyPath, @rl.history.join("\n")
    stdout.write("\n")
    stdin.resume()

  updateSize: ->
    @width = stdout.columns
    @height = stdout.rows-2

  render: (restore = true) =>
    stdin.pause()
    @updateSize()

    lHeader = @src._lHeader()
    rHeader = @src._rHeader()
    c = @cursor

    c.savePosition().goto(0, 0)
    c.black().bg.white()

    # The 10 character padding is to offset against ascii color codes in the 
    # header.
    rHeaderLength = rHeader.length - Object.keys(@src._sensors).length*10
    c.write lHeader.padRight(" ", @width - lHeader.length - rHeaderLength)
    c.write(rHeader)
    c.reset().bg.reset()

    c.goto(0, @height+2).show()
    c.restorePosition() if restore
    stdin.resume()


class Tegh
  commands: require './help'
  _jobProgress: 0
  _sensorMap: {e: 'extruder', e0: 'extruder', b: 'bed'}

  constructor: ->
    new ServiceSelector().on "select", @_onServiceSelect
    @_sensors = {}
    @_targetTemp = {}
    @_targetTempEta = {}

  _onServiceSelect: (service) =>
    clear()
    port = 8888
    stdout.write "Connecting to #{service.address}:#{port}..."
    @client = new ConstructClient(service.address, port)
      .on("connect", @_onConnect)
      .on("job_upload_progress_changed", @_renderProgressBar)
      .on("sensor_changed", @_onSensorChanged)
      .on("target_temp_changed", @_onTargetTempChanged)
      .on("target_temp_progress_changed", @_onTargetTempProgressChanged)
      .on("job_progress_changed", @_onJobChanged)
      .on("ack", @_onAck)
      .on("construct_error", @_onError)
      .on("unblocked", @_onUnblocked)
      .on("close", @_onClose)
    # @client = new ConstructClient(service.host[0..-2], service.port)

  _onConnect: =>
    @cli = new CliConsole(@)

  _onTargetTempChanged: (data) =>
    @_targetTemp[@_sensorMap[k]] = v for k, v of data
    @cli.render()

  _onTargetTempProgressChanged: (data) =>
    @_targetTempEta[@_sensorMap[k]] = v for k, v of data
    @cli.render()

  _onSensorChanged: (data) =>
    @_sensors[data.name] = data.value
    @cli.render()

  _onJobChanged: (data) =>
    @_jobProgress = data
    @cli.render()

  _onClose: =>
    console.log("Server disconnected.")
    process.exit()

  _onAck: (data) =>
    @_onJobList(data.jobs) if data?.jobs?

  _onError: (data) =>
    @_append "Error: #{data.message}"

  _onUnblocked: =>
    if @_uploading = true
      @_uploading = null
      console.log ""
    delete @cli.rl._ttyWrite
    @cli.rl.resume()
    @cli.rl.prompt()
    @cli.render()

  _onJobList: (jobs) ->
    @cli.rl.pause()
    stdout.write("\r")
    console.log "Print Jobs:\n"
    @_printJob(job, i) for job, i in jobs
    @_append "  There are no jobs in the print queue." if jobs.length == 0

  _printJob: (job, i) =>
    name = job.file_name
    id = job.id.toString()
    prefix = "  #{i}) #{name} ";
    if job.printing
      suffix = "PRINTING    "
    else
      suffix = "job ##{job.id.pad(5)}  "
    padding = @cli.width - suffix.length - prefix.length - 1
    line = "#{prefix.padRight(".", padding)} #{suffix}"
    line = line.green if job.printing
    console.log line

  _lHeader: ->
    fields = []
    for k, v of @_sensors
      if v > 100
        color = "\x1b[41m"
      else if v > 60
        color = "\x1b[43m"
      else
        color = "\x1b[44m"

      vString = "#{v.round(1)}#{if v%1 > 0 then "" else ".0"}"
      vString = vString.padLeft(" ", 5 - vString.length)

      s = "#{k.capitalize()}: #{color} #{vString}"
      s += " / #{@_targetTemp[k]||0}\u00B0C \x1b[47m"

      if @_targetTempEta[k]? and @_targetTempEta[k].eta > 0
        s+= " (#{@_targetTempEta[k].eta.round(1)} seconds)"
      fields.push s
    fields.join("  ")

  _rHeader: ->
    "#{@_jobProgress.format(2)}% Complete "

  _append: (s, prefix = "") ->
    stdout.write(prefix + s + "\n")

  _renderProgressBar: (data) =>
    p = (if data? then data.uploaded / data.total * 100 else 0).round()
    bar = "#{''.pad "#", (p*2/10).round()}#{''.pad '.', (20-p*2/10).round()}"
    percent = "#{if p > 10 then "" else " "}#{p.round(1)}"
    stdout.write "\ruploading [#{bar}] #{percent}%"


  _parseLine: (line) =>
    line = line.toString().trim()
    return if line == ""
    words = line.split(/\s/)
    cmd = words.shift()
    if cmd == "add_job"
      @_renderProgressBar()
      @_uploading = true

    if cmd == "help" then @_appendHelp(words[0])
    else if cmd == "exit" then process.exit()
    else if @commands[cmd]?
      try
        @client.send(line)
        @cli.render()
        # Temporarily overriding readline's _ttyWrite to pause the CLI input.
        @cli.rl._ttyWrite = ( -> )
        return
      catch e
        @_append "Error: #{e}"
    else
      @_append """
        Error: '#{cmd}' is not a valid command.
        Try typing 'help' for more info.
      """
    @cli.render()

  _appendHelp: (cmd) ->
    return @_appendSpecificHelp(cmd) if cmd? and cmd.length > 0
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
      #{cmd_info.description.replace("\n", " ")}\n
    """

    for type in ['required', 'optional']
      section = "#{type}_args"
      title = "#{type.capitalize()} Arguments"
      continue unless cmd_info[section]?
      help += "\n#{title}:\n"
      help += (cmd_info[section]).map((arg) -> "  - #{arg}\n").join("")

    if cmd_info.examples?
      help += "\nExample Usage:\n"
      for desc, ex of cmd_info.examples
        help += "  - #{desc}:#{"".padRight(" ", 50-desc.length)}#{ex}\n"

    @_append("")
    @_append(help)


  _autocomplete: (line) =>
    out = []
    words = line.split(" ")
    setTimeout ( => @cli.render() ), 0
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
