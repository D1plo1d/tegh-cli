dgram = require('dgram')
dns = require('native-dns')
UDPSocket = require('native-dns/lib/utils').UDPSocket
DnsPacket = require('native-dns/lib/packet')
consts = require('native-dns-packet/consts')
util = require('util')
net = require('net')
EventEmitter = require('events').EventEmitter

`var random_integer = function() {
  return Math.floor(Math.random() * 50000 + 1);
};`


module.exports = class DnsSdDiscoverer extends EventEmitter
  multicastAddresses:
    udp4: "224.0.0.251"
    # udp6: "FF02::FB"
  mdnsServer:
    port: 5353
    type: "udp"

  dnsSdOpts:
    name: "_tegh._tcp.local"
    type: "PTR"

  constructor: (@filter) ->
    @services = []

  start: ->
    @start = Date.now()

    @makeAllMdnsRequests()
    @mdnsInterval = setInterval(@makeAllMdnsRequests, 25)
    return @

  makeAllMdnsRequests: =>
    @_sockets = []
    for type, address of @multicastAddresses
      @_makeMdnsRequest type, address
    setTimeout(@_close.fill(@_sockets), 2000)

  _makeMdnsRequest: (type, address) =>
    server =
      port: @mdnsServer.port
      type: @mdnsServer.type
      address: address
    question = dns.Question @dnsSdOpts
    dg = dgram.createSocket(type)
    socket = new UDPSocket dg, server

    req = dns.Request
      question: question
      server: server
      timeout: 2000

    packet = new DnsPacket(socket)
    packet.timeout = 2000
    packet.header.id = random_integer()
    packet.header.rd = 1
    packet.answer = []
    packet.additional = []
    packet.authority = []
    packet.question = [req.question]

    dg.on "message", @_onMessage

    packet.send()
    dg.ref()
    @_sockets.push dg

  _close: (sockets) =>
    for socket in sockets
      socket.unref()
      socket.close()
    # console.log "Closing the MDNS discovery udp connections"

  stop: =>
    clearInterval @mdnsInterval
    @removeAllListeners

  _onMessage: (buffer, rinfo) =>
    return if net.isIPv6 rinfo.address
    packet = DnsPacket.parse(buffer)
    # console.log event

    for service in packet.answer
      # This would add ipv6 if we supported it:
      # event.address = service.address if service.type == 28
      continue unless service.class == 1 and service.type == 12
      continue unless service.data?
      serviceName = service.data.split(".")[0].replace /\s\(\d+\)/, ""
      @_updateService
        address: rinfo.address
        hostname: null
        serviceName: serviceName
        path: "/printers/#{serviceName}/"

  _updateService: (service) =>
    # console.log event
    preExistingService = @services.find @_isSameService.fill(service)
    return @_updateTimeout preExistingService if preExistingService?
    @services.push service
    @_updateTimeout service
    @emit "serviceUp", service

  _isSameService: (e1, e2) ->
    e2.serviceName == e1.serviceName and e2.address == e1.address

  _removeService: (service) =>
    # console.log service
    @services = @services.exclude @_isSameService.fill(service)
    @emit "serviceDown", service

  _updateTimeout: (service) ->
    clearTimeout service.staleTimeout if service.staleTimeout?
    service.staleTimeout = setTimeout(@_removeService.fill(service), 1000)


new DnsSdDiscoverer()
