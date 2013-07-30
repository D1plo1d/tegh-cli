EventEmitter = require('events').EventEmitter
WebSocketClient = require('websocket').client
request = require 'request'
FormData = require 'form-data'
sugar = require 'sugar'
fs = require 'fs-extra'

stdout = process.stdout

module.exports = class ConstructClient extends EventEmitter
  blocking: false

  constructor: (@host, @port) ->
    @user = "admin"
    @password = "admin"

    @.on "initialized", @_onInitialized

    @socket = new WebSocketClient(webSocketVersion: 8)
    @socket.on "connect", @_onConnect
    @socket.on 'connectFailed', @_onConnectionFailed

    #new WebSocketClient "ws://#{@host}:8000/#{@port}", "construct"
    url = "ws://#{@host}:#{@port}/socket?user=#{@user}&password=#{@password}"
    @socket.connect url, "construct.text.0.2"

  send: (msg) =>
    @blocking = true
    try
      if msg.indexOf("add_job") == 0
        @_add_job(msg)
      else
        @connection.sendUTF msg
    catch e
      @emit "construct_error", {message: e}
      @_unblock()

  # sends the add_job command as a http post multipart form request
  _add_job: (msg) =>
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
      path: "/jobs?session_uuid=#{@session_uuid}"
      auth: "#{@user}:#{@password}"
    form.submit opts, (err, res) =>
      if err?
        @emit "construct_error", err
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
    @session_uuid = data.session_uuid

  _onMessage: (m) =>
    messages = JSON.parse m.utf8Data
    # console.log messages

    for msg in messages
      @emit "message", msg
      type = (if msg.type == "error" then "construct_error" else msg.type)
      @emit type, msg.data, msg.target
      # Unblocking if a synchronous error is thrown or the message was ack'd
      syncError = msg.type == "error" and msg.data.type.endsWith(".sync")
      @_unblock() if msg.type == "ack" or syncError

  _unblock: ->
    @blocking = false
    @emit "unblocked"

  _onClose: () =>
    @emit "close"
    