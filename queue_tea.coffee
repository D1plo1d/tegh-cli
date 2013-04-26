EventEmitter = require('events').EventEmitter
util = require 'util'
keypress = require 'keypress'
require 'sugar'
glob = require 'glob'
tty = require 'tty'
ansi = require 'ansi'
readline = require 'readline'
color = require 'colors'
ConstructClient = require './construct/client'
ServiceSelector = require './service_selector'

stdout = process.stdout
stdin = process.stdin

clear = -> `util.print("\u001b[2J\u001b[0;0f")`


class CliConsole
  constructor: (@src) ->
    @cursor = ansi(stdout)
    @render()
    @_line = ""
    stdout.on 'resize', @render
    stdin = process.stdin
    rl = readline.createInterface
      input: stdin,
      output: stdout
      completer: @src._autocomplete
    rl.setPrompt("\r> ".green, 2)
    rl.on("line", @src._parseLine)
    process.on 'exit', -> stdout.write("\n")

  updateSize: ->
    @width = stdout.columns
    @height = stdout.rows-2

  render: =>
    stdin.pause()
    @updateSize()
    clear()

    @cursor.black().bg.white()
    console.log "wut?"
    console.log @src._header()
    @cursor.write(@src._header())
    @cursor.reset().bg.reset()

    @cursor.write(@src._log(@height))

    @cursor.show().green().write("\r> ").reset()
    stdin.resume()


class QueueTea
  commands:
    help:
      description: """
        display help text
      """
    exit:
      description: """
        exit the console (note: this does *not* stop the printer)
      """
    move:
      description: """
        move the printer either a fixed distance (default) or 
        until stopped (via ++ or -- values).
      """
      optional_args: ["continuous", "x", "y", "z"]
      examples:
        "move the y axis forward until stopped": "move y: ++"
        "move the y axis backward until stopped": "move y: --"
        "move the x axis 10mm to the right": "move x: 10"
    stop_move:
      description: """
        stop all axes of the printer
      """
    set:
      description: """
        sets the target temperature(s) of the printer's extruder(s)
        or bed
      """
      optional_args: ["e", "e0", "e1", "e2", "b"]
      examples:
        "Start heating the primary (0th) extruder to 220 degrees celcius": "set e: 220"
        "Start heating the bed to 100 degrees celcius": "set b: 100"
        "Turn off the extruder's heater (unless it's bellow freezing)": "set e: 0"
    estop:
      description: """
        Emergency stop. Stop all dangerous printer activity
        immediately.
      """
    print:
      description: """
        Start or resume printing this printer's queued print jobs.
      """
    pause_print:
      description: """
        Pause the current print job (not necessarily immediately).
      """
    add_job:
      description: """
        Add a print job to the end of the printer's queue.
      """
      required_args: ["file"]
      optional_args: ["qty"]
    rm_job:
      description: """
        Remove a print job from the printer's queue by it's ID.
      """
      required_args: ["job_id"]
    change_job:
      description: """
        Change a print job's quantity or position in the queue.
      """
      required_args: ["job_id"]
      optional_args: ["qty", "position"]


  constructor: ->
    new ServiceSelector().on "select", @_onServiceSelect
    #@_onServiceSelect()
    @_logLines = []
    @_sensors = {}


  _onServiceSelect: (service) =>
    clear()
    stdout.write "Connecting to #{service.addresses.first()}:#{service.port}..."
    @client = new ConstructClient(service.addresses.first(), service.port)
      .on("connect", @_onConnect)
      .on("sensor_changed", @_onSensorChanged)
    # @client = new ConstructClient(service.host[0..-2], service.port)

  _onConnect: =>
    @cli = new CliConsole(@)

  _onSensorChanged: (data) =>
    @_sensors[data.name] = data.value
    console.log @_sensors
    @cli.render()

  _header: ->
    fields = []
    for k, v of @_sensors
      fields.push "#{k.capitalize()}: #{v}\u00B0C"
    fields.join("  ") + "\n"
    fields.join("  ") + "\n"

  _log: (height) =>
    log = ""
    blankLines = height - @_logLines.length - 1

    if blankLines < 0
      @_logLines = @_logLines[0..height-1]
    else
      log += "\n" for i in [0..blankLines]

    log += @_logLines.join("\n") + "\n" if @_logLines.length > 0
    return log

  _append: (s, prefix = "") ->
    for line in s.trim().split("\n")

      @_logLines.shift() if @_logLines.length >= @cli.height
      @_logLines.push(prefix + line)

  _parseLine: (line) =>
    line = line.toString()
    console.log line
    @_append(line, "> ")
    # ctrl-c ( end of text )
    #process.exit() if ( key == '\u0003' )
    words = line.split(/\s/)[0]
    cmd = words.shift()
    if cmd == "help" then @_appendHelp()
    else if cmd == "exit" then return process.exit()
    else if @commands[cmd]? then @client.send(line)
    else
      "Syntax Error: #{cmd} is not a valid command. Try typing 'help' for help."
    @cli.render()

  _appendHelp: ->
    help = """
      Help
      #{"".padLeft("-", 80)}
      The following commands are available on your printer:\n\n
    """
    # The following commands are available on your printer,
    # to learn more about a specific command type help <CMD>\n\n
    # """

    for cmd, data of @commands
      desc = data.description.split("\n")
      help += "- #{cmd.padRight(" ", 12 - cmd.length)} - #{desc.shift()}\n"
      help += "#{d.padLeft(" ", 12+5)}\n" for d in desc
    @_append("")
    @_append(help)
    @_append("")

  _autocomplete: (line) =>
    out = []
    words = line.split(" ")
    if words.length == 1
      for cmd, data of @commands
        out.push cmd if cmd.indexOf(line) == 0
      out[0] = out[0] + " " if out.length == 1

    if words[0] == "add_job"
      out = glob((words[1..]||[""]).join(" ")+"*", sync: true)
      out[0] = "add_job #{out[0]}" if out.length == 1

    return [out, line]

new QueueTea()