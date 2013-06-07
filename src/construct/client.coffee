EventEmitter = require('events').EventEmitter
WebSocketClient = require('websocket').client
request = require 'request'
FormData = require 'form-data'
sugar = require 'sugar'
fs = require 'fs-extra'

stdout = process.stdout

module.exports = class ConstructClient extends EventEmitter
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
    if msg.indexOf("add_job") == 0
      @add_job(msg)
    else
      @connection.sendUTF msg

  # sends the add_job command as a http post multipart form request
  add_job: (msg) ->
    filePath = msg.replace(/^add_job/, "").trim()

    throw "File does not exist: #{filePath}" unless fs.existsSync filePath

    form = new FormData()
    form.append('my_field', 'my_value')
    form.append('job', fs.createReadStream(filePath))

    opts = 
      host: @host
      port: @port
      path: '/jobs'
      auth: "#{@host}:#{@port}"
    form.submit opts, (err, res) =>
      @emit "job_upload_complete", res.statusCode = 200

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
      k = "construct_#{k}" if k == "error"
      @emit k, v

  _onClose: () =>
    @emit "close"
    