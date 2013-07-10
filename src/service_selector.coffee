ConstructDiscoverer = require './construct/discoverer'
EventEmitter = require('events').EventEmitter
util = require 'util'
keypress = require 'keypress'
require 'sugar'
colors = require 'colors'
ansi = require 'ansi'
tty = require 'tty'

stdin = process.stdin

module.exports = class ServiceSelector extends EventEmitter

  constructor: () ->
    @services = new ConstructDiscoverer()
    @selected_index = 0
    @cursor = ansi(process.stdout)
    stdin.setRawMode(true)
    stdin.resume()
    stdin.setEncoding( 'utf8' )
    keypress(stdin)

    stdin.on 'data', @onKeyData
    stdin.on 'keypress', @onKeyPress

    for k in ["Up", "Down"]
      @services.on("service#{k}", @render)
    @render()


  render: =>
    # Update the services menu
    width = process.stdout.getWindowSize()[0]
    `util.print("\u001b[2J\u001b[0;0H")`
    @cursor
      .hide()
      .write("Select a Printer [ Press ENTER ]")
      .write(":\n\n")
    max = @services.list.length - 1
    @selected_index = max if @selected_index > max
    @selected_index = 0 if @selected_index < 0

    for service, i in @services.list
      selected = i == @selected_index

      @cursor.write " ["
      @cursor.write if selected then "*" else " "
      @cursor.write "] #{service.name} (#{service.address})\n"
      @cursor.reset().bg.reset()

    if @services.list.length == 0
      @cursor
        .yellow().underline()
        .write("\nNo construct servers were found\n")
        .reset().brightWhite()
        .write(" - check that your printer is connected to the network\n\n")
        .reset()

  onKeyPress: (ch, key) =>
    return unless key?
    isEnter = (key.name == "enter" or key.name == "return")
    if ["up", "down"].indexOf(key.name) > -1
      @selected_index += if key.name == "up" then -1 else +1
      @render()
    if isEnter and @services.list.length > 0
      @cursor.show()
      @stop()
      @emit("select", @services.list[@selected_index])
    if key.name == "escape"
      @cursor.show()
      process.exit()


  onKeyData: ( key ) =>
    # ctrl-c ( end of text )
    if ( key == '\u0003' or key == `'\4'` )
      @cursor.show()
      process.exit()

  stop: () =>
    stdin._emitKeypress = false
    stdin.removeListener 'keypress', @onKeyPress
    stdin.removeListener 'data', @onKeyData
    stdin.setRawMode(false)
    stdin.resume()
    for k in ["Up", "Down"]
      @services.removeListener("service#{k}", @render)

