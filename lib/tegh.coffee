EventEmitter = require('events').EventEmitter
util = require 'util'
require 'sugar'
glob = require 'glob'
ansi = require 'ansi'
readline = require 'readline'
TeghClient = require './tegh/client'
ServiceSelector = require './service_selector'
fs = require "fs-extra"
touch = require "touch"
path = require ("flavored-path")
Table = require 'cli-table'
prompt = require 'prompt'
parser = require './parser'

stdout = process.stdout
stdin = process.stdin

dirAutocomplete = require './dir_autocomplete'

clear = -> `util.print("\u001b[2J\u001b[0;0f")`

getUserHome = ->
  drive = process.env.HOMEDRIVE || ""
  drive + (process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE)

class CliConsole
  historyPath: "#{getUserHome()}/.tegh_history"

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
    rHeaderLength = rHeader.length - Object.keys(@src.tempDevices).length*10
    spaces = Math.max 0, @width - lHeader.length - rHeaderLength
    c.write lHeader + " ".repeat(spaces)
    c.write(rHeader)
    c.reset().bg.reset()

    c.goto(0, @height+2).show()
    c.restorePosition() if restore
    stdin.resume()


class Tegh
  tempDevices: {}

  constructor: ->
    new ServiceSelector().on "select", @_onServiceSelect

  _onServiceSelect: (@service) =>
    clear()
    @_connect()

  _connect: (user, pwd) =>
    @user = user if user?
    @pwd = pwd if pwd?
    host = @service.address
    host = "#{@user}:#{@pwd}@#{host}" if @user?
    port = 2540
    stdout.write "Connecting to #{@service.address}/#{@service.serviceName}..."
    @client = new TeghClient(host, port, @service.path)
      .on("initialized", @_onInit)
      .on("add", @_onAdd)
      .on("rm", @_onRm)
      .on("change", @_onChange)
      .on("ack", @_onAck)
      .on("tegh_error", @_onError)
      .on("unblocked", @_onUnblocked)
      .on("close", @_onClose)
      .on("unauthorized", @_onUnauthorized)
      .on("badcert", @_onBadCert)

  _onUnauthorized: =>
    clear()
    prompt.message = ""
    prompt.delimiter = ""
    prompt.colors = false
    schema = properties:
      username: {required: true, description: "Username:"}
      password: {required: true, description: "Password:", hidden: true}
    prompt.start()
    if @multipleLoginAttempts
      console.log "Bad username/password. Try again.\n"
    else
      console.log "Secure 3D Printer. Login Required.\n"
    @multipleLoginAttempts = true
    prompt.get schema, (err, result) =>
      throw err if err?
      console.log result
      @_connect result.username, result.password

  _onBadCert: (ip, cert) =>
    clear()
    console.log """
    The authenticity of host '#{cert.printer}(#{ip})' can't be established.
    DSA key fingerprint is #{cert.fingerprint}.
    Are you sure you want to continue connecting (yes/no)?
    """
    stdin.setRawMode true
    stdin.on 'keypress', (key) =>
      process.exit() if key == '\u0003' or key == `'\4'` or key == 'n'
      return unless key == 'y'
      stdin.setRawMode false
      TeghClient.addCert(cert)
      @_connect()

  _onInit: (data) =>
    @printer = data
    @commands = require('./commands')(data)
    # console.log @printer
    @tempDevices = Object.findAll @printer, (k, v) -> v.type == 'heater'
    @cli = new CliConsole(@)
    @cli.render()

  _onAdd: (data, target) =>
    @printer[target] = data

  _onRm: (data, target) =>
    delete @printer[target]

  _onChange: (data, target) =>
    @_renderProgressBar(data) if target == 'upload_progress'
    # Finding the target from it's path, updating it and re-rendering

    if Object.isObject data
      Object.merge @printer[target], data
    else
      @printer[target] = data
    if target.type == 'part' and data.status?
      @_onPartStatusChange @printer[target]
    @cli.render()

  _onClose: =>
    console.log("Server disconnected.")
    process.exit()

  _onAck: (data) =>

  _onError: (data) =>
    console.log "" if @_uploading == true
    @_append "Error: #{data.message}"

  _onUnblocked: =>
    if @_uploading?
      @_uploading = null
      console.log ""
    delete @cli.rl._ttyWrite
    @cli.rl.resume()
    @cli.rl.prompt()
    @cli.render()

  _onPartStatusChange: (part) =>
    msg = "#{part.status.capitalize()} #{part.file_name}"
    color = if part.status == "estopped" then "yellow" else "green"
    stdout.write "\r" + msg[color]
    console.log()
    @cli.rl.prompt()

  parts: =>
    parts = []
    parts = Object.findAll @printer, (k, v) ->
      return false unless v.type == 'part'
      v.id = k
      return true
    parts = Object.values(parts).sortBy 'position'
    return parts

  _listParts: =>
    parts = @parts()

    @cli.rl.pause()
    stdout.write("\r")
    console.log "Print Jobs:\n"

    cols = 12
    w = Math.round((@cli.width - cols) / cols)
    colWidths = [        8,     25,                11,       7,    10,      10    ]
    colWidths.unshift @cli.width - 8 - colWidths.sum()
    table = new Table
      head:     ['Part', 'Qty', 'Quality', 'Status', 'Id', 'Start', 'Elapsed']
      colWidths: colWidths
      style: { 'padding-left': 1, 'padding-right': 1 }

    i = 0
    for part in parts
      @_printPart table, part, (if part.status == 'printing' then i else i++)
    if parts.length == 0
      @_append "  There are no jobs in the print queue."
    else
      console.log table.toString()

  _partAttrStrings: (part, i) ->
    prefix: "#{i}) #{part.file_name} "
    id: part.id
    status: part.status?.capitalize?()
    quality:
      if part.file_name.endsWith(/\.ngc|\.gcode/)
        "N/A"
      else
        part.quality.titleize()
    start:
      if part.start_time?
        (new Date(part.start_time)).format('{12hr}:{mm} {TT}')
      else
        "N/A"
    elapsed:
      if part.status == 'printing'
        @_formatTime new Date() - new Date(part.start_time)
      else
        "N/A"
    qty: "#{part.qty_printed}/#{part.qty}"

  _printPart: (table, part, i) =>
    if part.status == 'printing' then i = "X"
    keys = ['prefix', 'qty', 'quality', 'status', 'id', 'start', 'elapsed']
    attrs = @_partAttrStrings(part, i)
    # color = if part.status == 'printing' then "\x1b[32m" else ""
    # table.push keys.map (k) -> v = "#{color}#{attrs[k]}\x1b[\x1b[0m"
    table.push keys.map (k) -> v = attrs[k]

  _formatTime: (millis) ->
    secs = millis / 1000
    ms = Math.floor(millis % 1000)
    minutes = secs / 60
    secs = Math.floor(secs % 60)
    hours = minutes / 60
    minutes = Math.floor(minutes % 60)
    hours = Math.floor(hours % 24)
    return hours.pad(2) + ":" + minutes.pad(2) + ":" + secs.pad(2)

  _lHeader: ->
    fields = []
    for k in Object.keys(@tempDevices).sort()
      data = @tempDevices[k]
      # console.log k
      # console.log data
      v = data.current_temp
      countdown = data.target_temp_countdown || 0
      if v > 100
        color = "\x1b[41m"
      else if v > 60
        color = "\x1b[43m"
      else
        color = "\x1b[44m"

      vString = "#{v.round(1)}#{if v%1 > 0 then "" else ".0"}"
      vString = vString.padLeft(" ", 5 - vString.length)

      s = "#{k.capitalize()}: #{color} #{vString}"
      s += " / #{data.target_temp||0}\u00B0C \x1b[47m"

      s+= " (#{(countdown/1000).round(1)} seconds)" if countdown > 0
      fields.push s
    fields.join("  ")

  _rHeader: ->
    status = "Status: #{@printer.state.status.capitalize()} "
    return status if @printer.state.status != "printing"
    total = 0
    current = 0
    startTime = Number.MAX_VALUE
    for part in @printer.parts()
      continue unless part.status == "printing"
      total += part.total_lines || 0
      current += part.current_line || 0
      startTime = new Date(part.start_time) if part.start_time < startTime
    status += "( #{((100*current / total) || 0).format(2)}% ) "

    if startTime < Number.MAX_VALUE
      elapsed = @_formatTime new Date() - new Date(startTime)
      status += " Elapsed: #{elapsed} "
    return status

  _append: (s, prefix = "") ->
    stdout.write(prefix + s + "\n")

  _renderProgressBar: (data = {uploaded: 0, total: 1}) =>
    # console.log data
    p = (data.uploaded / data.total * 100).round()
    return if p == @_previousUploadPercent
    @_previousUploadPercent = p
    bar = "#{"#".repeat (p*2/10).round()}#{".".repeat (20-p*2/10).round()}"
    percent = "#{if p > 10 then "" else " "}#{p.round(1)}"
    c = @cli.cursor
    c.hide().goto(0, @cli.height+1).write "Uploading [#{bar}] #{percent}%"
    @_renderUploadNotice() if p == 100

  _renderUploadNotice: =>
    partCount = @parts().length
    are = if partCount == 1 then "is" else "are"
    text = "Uploaded. There #{are} #{partCount||"no"} print jobs ahead of yours"
    console.log "\n#{text}"


  _parseLine: (line) =>
    line = line.toString().trim()
    return if line == ""
    words = line.split(/\s/)
    cmd = words.shift()
    if cmd == "add_job"
      console.log("")
      @_renderProgressBar()
      @cli.render()
      @_uploading = true

    if cmd == "help" then @_appendHelp(words[0])
    else if cmd == "get_jobs" then @_listParts()
    else if cmd == "exit" then process.exit()
    else
      try
        # Temporarily overriding readline's _ttyWrite to pause the CLI input.
        @cli.rl._ttyWrite = ( -> )
        # Sending the command
        @client.send parser.toJSON line, @commands
        @_lastCmd = cmd
        @cli.render()
        return
      catch e
        @_append "Error: #{e}"
        @_onUnblocked()
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
    # Command arg autocomplete
    if words.length > 1
      out = @_autocomplete_args (line)
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

  _autocomplete_args: (line) ->
    out = []
    words_tmp=line.replace("/\s+/g","").split(" ")
    words=[] # Ugly hack to remove intermediate spaces:
    for word in words_tmp
      words.push word if word

    # Find argTree from  command
    current_args_tree = {}
    for cmd,data of @commands
      if cmd == words[0] && data.argTree?
        # Recurse through existing word list to find base tree:
        current_args_tree = @_autocomplete_recurse_to(line,data.argTree())
        break

    if current_args_tree != {}

      # Resolve partial
      for arg, subargs of current_args_tree
        if arg.startsWith words[words.length-1]
          newline = words[0..words.length-2]
          newline.push arg+" "
          out.push newline.join(" ")
          return out

      # Print next options:
      nextopts=[]
      for arg, subargs of current_args_tree
        nextopts.push arg
    out.push nextopts.join(" ")
    out.push ""
    out

  # Returns the current level of argument tree of last word in array:
  _autocomplete_recurse_to: (line,argtree,idx=1) ->
    words = line.replace(/^\s+|\s+$/g, "").split(" ")
    # Null case: Cannot find location.
    if words.length < idx
      return {}
    if words.length == idx
      return argtree
    # Full match - recurse:
    for arg,subargs of argtree
      if words[idx] == arg
        return @_autocomplete_recurse_to(line,subargs,idx+1)
    # Partial match: Return base tree
    for arg,subargs of argtree
        return argtree if arg.startsWith words[idx]
    return {}

  _fileTypes: /\.(gcode|ngc|stl|amf|obj)/i

  _autocomplete_dir: (out, words, line) =>
    dir = words[1..].join(' ')
    dir = "./" if dir.length == 0
    [absPath, out] = dirAutocomplete dir, @_fileTypes

    # If there is only 1 result set the current REPL line to it's
    # value.
    if out.length < 2
      out[0] = ""
    @cli.rl.line = line = "add_job #{absPath}"
    @cli.rl.cursor = line.length

    return [out, line]


new Tegh()