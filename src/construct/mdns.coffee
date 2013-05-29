dns = require('native-dns')
PendingRequests = require('./pending')
util = require('util')
EventEmitter = require('events').EventEmitter

module.exports = class DnsSdDiscoverer extends EventEmitter
  multicastAddresses: ["224.0.0.251", "FF02::FB"]
  mdnsServer: 
    port: 5353
    type: "udp"

  dnsSdOpts:
    name: "_services._dns-sd._udp.local"
    type: "PTR"

  constructor: (@filter) ->

  start: ->
    @start = Date.now()
    @_sockets = []

    @_makeMdnsRequest address for address in @multicastAddresses
    setTimeout(@close, 2000);

  _makeMdnsRequest: (address) ->
    question = dns.Question @dnsSdOpts
    server = port: @mdnsServer.port, type: @mdnsServer.type
    server.address = address
    req = dns.Request
      question: question
      server: server
      timeout: 2000

    _onMessage = @_onMessage
    mdns = @

    # req.done = -> console.log "doneish"
    req._send = ->
      self = this

      this.timer_ = setTimeout( ->
        self.handleTimeout()
      , this.timeout)

      socket = PendingRequests.send(self)
      mdns._sockets.push(socket)
      console.log "socket loaded"
      socket.on "mdnsMessage", _onMessage

    req
      # .on("end", @_onEnd)
      .send()

  close: =>
    socket.close() for socket in @_sockets
    # console.log "Closing the MDNS discovery udp connections"

  _onMessage: (data) =>
    # console.log data._socket.address
    data.answer.forEach (a) =>
      return unless a.data == @filter
      @emit "serviceUp",
        address: data._socket.address
        services: a.data
        name: @filter

  # _onEnd: =>
  #   delta = (Date.now()) - @start
  #   console.log "Finished processing request: " + delta.toString() + "ms"


new DnsSdDiscoverer()
