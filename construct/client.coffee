EventEmitter = require('events').EventEmitter
WebSocketClient = require('websocket').client

stdout = process.stdout

module.exports = class ConstructClient extends EventEmitter
  constructor: (@host, @port) ->
    @socket = new WebSocketClient(webSocketVersion: 8)
    @socket.on "connect", @_onConnect
    @socket.on 'connectFailed', @_onConnectionFailed
    #new WebSocketClient "ws://#{@host}:8000/#{@port}", "construct"
    url = "ws://#{@host}:#{@port}/socket?user=admin&password=admin"
    @socket.connect url, "construct.text.0.1"

  send: ->

  _onConnect: (connection) =>
    @emit "connect", connection
    connection.on 'message', @_onMessage

  _onConnectionFailed: (error) =>
    stdout.write 'Connect Error: ' + error.toString() + "\n"
    process.exit()

  _onMessage: (m) =>
    message = JSON.parse m.utf8Data
    @emit "message", message
    @emit k, v for k,v of message
    