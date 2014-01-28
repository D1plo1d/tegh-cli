EventEmitter = require('events').EventEmitter
WebSocketClient = require('websocket').client
request = require 'request'
FormData = require 'form-data'
sugar = require 'sugar'
fs = require 'fs-extra'
parser = require '../parser'

stdout = process.stdout

module.exports = class TeghClient extends EventEmitter
  blocking: false

  constructor: (@host, @port, @path) ->
    @user = "admin"
    @password = "admin"

    @.on "initialized", @_onInitialized

    @socket = new WebSocketClient webSocketVersion: 8, tlsOptions:
      rejectUnauthorized: false
    @socket.on "connect", @_onConnect
    @socket.on 'connectFailed', @_onConnectionFailed

    url = "wss://#{@host}:#{@port}#{@path}socket?user=#{@user}&password=#{@password}"
    # console.log url
    @socket.connect url, "tegh.text.1.0"

  send: (msg) =>
    @blocking = true
    try
      @_attemptSend(msg)
    catch e
      @emit "tegh_error", {message: e}
      @_unblock()

  _attemptSend: (msg) =>
    return @_addJob(msg) if msg.indexOf("add_job") == 0
    json = parser.toJSON(msg)
    # console.log json
    @connection.sendUTF json

  # sends the add_job command as a http post multipart form request
  _addJob: (msg) =>
    filePath = msg.replace(/^add_job/, "").trim()

    if !filePath? or filePath.length == 0
      throw "add_job requires a file path (ex: add_job ~/myfile.gcode)"
    unless fs.existsSync filePath
      throw "No such file: #{filePath}"

    throw "#{filePath} is not a file" if fs.lstatSync(filePath).isDirectory()

    form = new FormData()

    form.append('job', fs.createReadStream(filePath))

    opts = 
      host: @host
      port: @port
      path: "#{@path}jobs?session_uuid=#{@session_uuid}"
      auth: "#{@user}:#{@password}"
    form.submit opts, (err, res) =>
      emitErr = (msg) => @emit "tegh_error", message: msg.toString()
      if err?
        emitErr err
      else if !(200 <= res.statusCode < 300 )
        res.once 'data', emitErr
      else
        @emit "ack", "Job added."
      @_unblock()

  _onConnect: (@connection) =>
    @emit "connect", @connection
    @connection.on 'message', @_onMessage
    @connection.on 'close', @_onClose

  _onConnectionFailed: (error) =>
    stdout.write 'Connect Error: ' + error.toString() + "\n"
    process.exit()

  _onInitialized: (data) =>
    console.log data
    @session_uuid = data.session.uuid

  _onMessage: (m) =>
    # console.log m.utf8Data
    messages = JSON.parse m.utf8Data
    # console.log messages

    for msg in messages
      @emit "message", msg
      type = (if msg.type == "error" then "tegh_error" else msg.type)
      @emit type, msg.data, msg.target
      # Unblocking if a synchronous error is thrown or the message was ack'd
      syncError = msg.type == "error" and msg.data.type.endsWith(".sync")
      @_unblock() if msg.type == "ack" or syncError

  _unblock: ->
    @blocking = false
    @emit "unblocked"

  _onClose: () =>
    @emit "close"
    