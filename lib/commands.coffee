_ = require "lodash"
module.exports = (data) ->


  # Non-websocket commands. These do not send a request to the server through 
  # the websocket.
  help:
    description: """
      display help text
    """
    websocket: false
  exit:
    description: """
      exit the console (note: this does *not* stop the printer)
    """
    websocket: false
  get_jobs:
    description: """
      Gets a list of the jobs in the printer's queue.
    """
    websocket: false
  add_job:
    description: """
      Add a print job to the end of the printer's queue.
    """
    examples:
      "add example.gcode to the print queue": "add_job ./example.gcode"
    argTree: ->
      value: null
    websocket: false


  # Websocket commands. These commands generate json data which is sent to the 
  # server via the websocket.
  home:
    description: """
      home the printer's axes. Specifing individual axes will only home those 
      axes.
    """
    argTree: ->
      x: null
      y: null
      z: null
    examples:
      "home all axes": "home"
      "home the y axis": "home y"
      "home the x and y axes": "home x y"
  move:
    description: """
      move the printer a fixed distance on one or more axis
    """
    # description: """
    #   move the printer either a fixed distance (default) or 
    #   until stopped (via ++ or -- values, if available).
    # """
    argTree: ->
      # Adding extruders
      tree = _(data).pick((c) -> c.type == 'heater').map -> {value: null}
      # Adding axes
      tree.merge
        x: {value:null}
        y: {value:null}
        z: {value:null}
      tree.value()

    # optional_args: ["continuous", "x", "y", "z", "e"]
    examples:
      "move the x axis 10mm to the right": "move x 10"
      "move the x axis 10mm and the y axis 10mm at 200% feedrate": "move x 10 y 10 @ 200%"
      # Proposed Additions:
      #   "move the y axis forward until stopped": "move y: ++"
      #   "move the y axis backward until stopped": "move y: --"
  # Proposed Additions:
  #   stop_move:
  #     description: """
  #       stop all axes of the printer that are moving continuously.
  #     """
  extrude:
    description: """
      extrude or reverse the printer's filament.
    """
    argTree: ->
      console.log _(data).pick((c) -> c.type == 'heater').value()
      tree = _(data).pick((c) -> c.type == 'heater').map -> {value: null}
      tree.value()
    examples:
      "push 10mm of filament through the primary extruder": "extrude e0 10"
  set:
    description: """
      set one or more settings on the printer. The printer's settings are
      grouped under temp, motors and fan namespaces:

      - temp: set the target temperature(s) of the printer's extruder(s) or bed
      - motors: enable/disable the printer's motors
      - fan: enable/disable the printer's fan
    """
    argTree: ->
      # Adding extruders and heated beds to the arg tree
      tree = _(data).pick((c) -> c.type == 'heater').map ->
        {temp: null, on: null, off: null}
      # Adding fans and conveyors to the arg tree
      tree.merge fan: {on: null, off: null} if data.f?
      tree.merge conveyor: {on: null, off: null} if data.c?
      # Returning the arg tree
      tree.value()

    examples:
      "Start heating the extruder": "set e0 on"
      "Stop heating the extruder": "set e0 off"
      "Start heating the extruder to 220\u00B0C": "set e0 temp: 220"
      "Set the extruder's target temp. to 0\u00B0C (off)": "set e0 temp: 0"
      "Start heating the bed to 100\u00B0C": "set b temp: 100"
      "move job #AH5H5 to the top of the queue": "set AH5H5 position: 0"
      "make job #AH5H5 the second next job in the queue": "set AH5H5 position: 1"
      "Enable the printer's motors": "set motors on"
      "Disable the printer's motors": "set motors off"
      "Enable the printer's fan": "set fan on"
      "Disable the printer's fan": "set fan off"
      "Enable the printer's conveyor or ABP": "set conveyor on"
      "Disable the printer's conveyor or ABP": "set conveyor off"
  estop:
    description: """
      Emergency stop. Stop all dangerous printer activity immediately.
    """
  print:
    description: """
      Start printing this printer's queued print jobs (see get_jobs and 
      add_job).
    """
  retry_print:
    description: """
      Reprint an estopped print job.
    """
  rm_job:
    description: """
      Remove a print job from the printer's queue by it's ID.
    """
    examples:
      "delete job #AH5H5": "rm_job AH5H5"
    argTree: ->
      value: null
