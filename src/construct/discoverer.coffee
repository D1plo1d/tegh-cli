mdns = require './mdns'
# st = require 'mdns/lib/service_type'
EventEmitter = require('events').EventEmitter
os = require 'os'

module.exports = class ConstructDiscoverer extends EventEmitter
  constructor: ->
    @local_ips = []
    for phy, address_list of os.networkInterfaces()
      @local_ips.push(a.address) for a in address_list

    @mdns = new mdns('_construct._tcp.local')
      .on('serviceUp',   (service) => @emit "serviceUp", service)
      .on('serviceDown', (service) => @emit "serviceDown", service)
      .start()

    @__defineGetter__ 'list', => @mdns.services
  stop: =>
    @mdns.stop()
    @removeAllListeners()
