EventEmitter = require('events').EventEmitter
WebSocket = require('ws')
request = require 'request'
FormData = require 'form-data'
sugar = require 'sugar'
fs = require 'fs-extra'
parser = require '../parser'

stdout = process.stdout

module.exports = class TeghClient extends EventEmitter
  blocking: false

  constructor: (@host, @port, @path) ->
    url = "wss://#{@host}:#{@port}#{@path}socket"
    @.on "initialized", @_onInitialized
    @ws = new WebSocket url,
      webSocketVersion: 8
      rejectUnauthorized: false
    @ws
    .on('open', @_onOpen)
    .on('close', @_onClose)
    .on('message', @_onMessage)
    .on('error', @_onError)

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
    @ws.send json

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
      host: @host.split("@")[1] || @host
      port: @port
      path: "#{@path}jobs?session_uuid=#{@session_uuid}"
      auth: @host.split("@")[0]
    form.submit opts, (err, res) =>
      emitErr = (msg) => @emit "tegh_error", message: msg.toString()
      if err?
        emitErr err
      else if !(200 <= res.statusCode < 300 )
        res.once 'data', emitErr
      else
        @emit "ack", "Job added."
      @_unblock()

  _onOpen: =>
    @emit "connect", @ws

  _onInitialized: (data) =>
    console.log data
    @session_uuid = data.session.uuid

  _onMessage: (m) =>
    messages = JSON.parse m
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

  _onError: (e) =>
    unauthorized = e.toString().indexOf("unexpected server response (401)") > -1
    throw e unless unauthorized
    @emit "unauthorized"
