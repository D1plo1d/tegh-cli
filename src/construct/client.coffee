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

    @socket = new WebSocketClient(webSocketVersion: 8)
    @socket.on "connect", @_onConnect
    @socket.on 'connectFailed', @_onConnectionFailed

    #new WebSocketClient "ws://#{@host}:8000/#{@port}", "construct"
    url = "ws://#{@host}:#{@port}/socket?user=#{@user}&password=#{@password}"
    @socket.connect url, "construct.text.0.0.1"

  send: (msg) =>
    @blocking = true
    try
      if msg.indexOf("add_job") == 0
        @_add_job(msg)
      else
        @connection.sendUTF msg
    catch e
      @emit "construct_error", e
      @_unblock()

  # sends the add_job command as a http post multipart form request
  _add_job: (msg) ->
    filePath = msg.replace(/^add_job/, "").trim()

    throw "#{filePath} does not exist" unless fs.existsSync filePath

    throw "#{filePath} is not a file" if fs.lstatSync(filePath).isDirectory()

    form = new FormData()
    form.append('my_field', 'my_value')
    form.append('job', fs.createReadStream(filePath))

    opts = 
      host: @host
      port: @port
      path: '/jobs'
      auth: "#{@host}:#{@port}"
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

  _onMessage: (m) =>
    message = JSON.parse m.utf8Data
    @emit "message", message

    for k,v of message
      @emit (if k == "error" then "construct_#{k}" else k), v

    @_unblock() if Object.has(message, "ack") or Object.has(message, "error")

  _unblock: ->
    @blocking = false
    @emit "unblocked"

  _onClose: () =>
    @emit "close"
    