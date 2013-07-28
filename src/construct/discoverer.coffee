mdns = require './mdns'
# st = require 'mdns/lib/service_type'
EventEmitter = require('events').EventEmitter
os = require 'os'

module.exports = class ConstructDiscoverer extends EventEmitter
  constructor: ->
    @local_ips = []
    for phy, address_list of os.networkInterfaces()
      @local_ips.push(a.address) for a in address_list

    @list = []
    # Watch all construct servers on the network
    # @mdns = mdns.createBrowser( st.protocolHelper('_tcp')('_construct') )
    # @mdns
    #   .on('serviceUp', @_addServer)
    #   .on('serviceDown', @_rmServer)
    #   .start()
    @mdns = new mdns('_construct._tcp.local')
      .on('serviceUp', @_addServer)
      .on('serviceDown', @_rmServer)
      .start()

  _addServer: (service) =>
    service.name ?= "localhost" if @local_ips.indexOf(service.address) != 0
    @list.push service
    @emit "serviceUp", service

  _rmServer: (rm) =>
    console.log @mdns
    for service, i in @list
      console.log rm
      services.remove(service) if service.fullname == rm.fullname
    @emit "serviceDown", service