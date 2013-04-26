mdns = require 'mdns'
st = require '../node_modules/mdns/lib/service_type'
EventEmitter = require('events').EventEmitter

module.exports = class ConstructDiscoverer extends EventEmitter
  constructor: ->
    @list = []
    # Watch all construct servers on the network
    mdns.createBrowser( st.protocolHelper('_tcp')('_construct') )
      .on('serviceUp', @_addServer)
      .on('serviceDown', @_rmServer)
      .start()

  _addServer: (service) =>
    @list.push service
    @emit "serviceUp", service

  _rmServer: (service) =>
    @list.remove service
    @emit "serviceDown", service