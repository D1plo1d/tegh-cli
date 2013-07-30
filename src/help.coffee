module.exports =
  help:
    description: """
      display help text
    """
  exit:
    description: """
      exit the console (note: this does *not* stop the printer)
    """
  home:
    description: """
      home the printer's axes. Specifing individual axes will only home those 
      axes.
    """
    optional_args: ["x", "y", "z"]
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
    optional_args: ["x", "y", "z", "e"]
    # optional_args: ["continuous", "x", "y", "z", "e"]
    examples:
      "move the x axis 10mm to the right": "move x: 10"
      "move the x axis 10mm and the y axis 10mm at 200% feedrate": "move x:10 y:10 @ 200%"
      # Proposed Additions:
      #   "move the y axis forward until stopped": "move y: ++"
      #   "move the y axis backward until stopped": "move y: --"
  # Proposed Additions:
  #   stop_move:
  #     description: """
  #       stop all axes of the printer that are moving continuously.
  #     """
  set:
    description: """
      set one or more settings on the printer. The printer's settings are
      grouped under temp, motors and fan namespaces:

      - temp: set the target temperature(s) of the printer's extruder(s) or bed
      - motors: enable/disable the printer's motors
      - fan: enable/disable the printer's fan
    """
    # optional_args: ["e", "b"]# Proposed Additions: ["e", "e0", "e1", "e2", "b"]
    examples:
      "Start heating the extruder to 220\u00B0C": "set temp e0: 220"
      "Set the extruder's target temp. to 0\u00B0C (off)": "set temp e0: 0"
      "Start heating the bed to 100\u00B0C": "set temp b: 100"
      "Enable the printer's motors": "set motors on"
      "Disable the printer's motors": "set motors off"
      "Enable the printer's fan": "set fan on"
      "Disable the printer's fan": "set fan off"
      "Enable the printer's conveyor or ABP": "set conveyor on"
      "Disable the printer's conveyor or ABP": "set conveyor off"
      # Proposed Additions:
      #   set temp e0:220 e1:0 b:100
      #   set feedrate xy: 100 z: 1
  estop:
    description: """
      Emergency stop. Stop all dangerous printer activity immediately.
    """
  print:
    description: """
      Start printing this printer's queued print jobs (see get_jobs and 
      add_job).
    """
  add_job:
    description: """
      Add a print job to the end of the printer's queue.
    """
    required_args: ["file"]
    # optional_args: ["qty"]
    examples:
      "add example.gcode to the print queue": "add_job ./example.gcode"
  rm_job:
    description: """
      Remove a print job from the printer's queue by it's ID.
    """
    required_args: ["job_id"]
    examples:
      "delete job #5": "rm_job 5"
  change_job:
    description: """
      Change a print job's position in the printer's queue.
    """
    # description: """
    #   Change a print job's quantity or position in the queue.
    # """
    required_args: ["id"]
    optional_args: ["position"] # ["qty", "position"]
    examples:
      "move job #3 to the top of the queue": "change_job id: 3 position: 0"
      "make job #12 the second next job in the queue": "change_job id: 12 position: 1"
  get_jobs:
    description: """
      Gets a list of the jobs in the printer's queue.
    """
