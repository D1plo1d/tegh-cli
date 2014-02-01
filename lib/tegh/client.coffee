EventEmitter = require('events').EventEmitter
WebSocket = require('ws')
request = require 'request'
FormData = require 'form-data'
sugar = require 'sugar'
fs = require 'fs-extra'
flavoredPath = require ("flavored-path")
_ = require 'lodash'

stdout = process.stdout

module.exports = class TeghClient extends EventEmitter
  blocking: false

  constructor: (@host, @port, @path) ->
    @_knownHosts = require flavoredPath.resolve "~/.tegh/known_hosts.json"
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
    return @_addJob(msg) if msg.action == "add_job"
    # console.log json
    @ws.send JSON.stringify msg

  # sends the add_job command as a http post multipart form request
  _addJob: (msg) =>
    filePath = msg.data

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
    cert = @ws._sender._socket.getPeerCertificate()
    cert.printer = @path.split("/")[2]
    isKnownHost = _.find(@_knownHosts, cert)?
    if isKnownHost
      @emit "connect", @ws
    else
      @ws.close()
      @emit "badcert", @host, cert

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

TeghClient.addCert = (cert) ->
  file = flavoredPath.resolve "~/.tegh/known_hosts.json"
  knownHosts = require file
  knownHosts.push cert
  fs.writeFileSync file, JSON.stringify knownHosts
