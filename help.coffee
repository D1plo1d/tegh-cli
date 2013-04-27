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
      home the printer's axes. Specifing individual axes will 
      only home those axes.
    """
    optional_args: ["x", "y", "z"]
    examples:
      "move the y axis forward until stopped": "move y: ++"
      "move the y axis backward until stopped": "move y: --"
      "move the x axis 10mm to the right": "move x: 10"
  move:
    description: """
      move the printer either a fixed distance (default) or 
      until stopped (via ++ or -- values).
    """
    optional_args: ["continuous", "x", "y", "z"]
    examples:
      "move the y axis forward until stopped": "move y: ++"
      "move the y axis backward until stopped": "move y: --"
      "move the x axis 10mm to the right": "move x: 10"
  stop_move:
    description: """
      stop all axes of the printer
    """
  set:
    description: """
      sets the target temperature(s) of the printer's extruder(s)
      or bed
    """
    optional_args: ["e", "e0", "e1", "e2", "b"]
    examples:
      "Start heating the primary (0th) extruder to 220 degrees celcius": "set e: 220"
      "Start heating the bed to 100 degrees celcius": "set b: 100"
      "Turn off the extruder's heater (unless it's bellow freezing)": "set e: 0"
  estop:
    description: """
      Emergency stop. Stop all dangerous printer activity
      immediately.
    """
  print:
    description: """
      Start or resume printing this printer's queued print jobs.
    """
  pause_print:
    description: """
      Pause the current print job (not necessarily immediately).
    """
  add_job:
    description: """
      Add a print job to the end of the printer's queue.
    """
    required_args: ["file"]
    optional_args: ["qty"]
  rm_job:
    description: """
      Remove a print job from the printer's queue by it's ID.
    """
    required_args: ["job_id"]
  change_job:
    description: """
      Change a print job's quantity or position in the queue.
    """
    required_args: ["job_id"]
    optional_args: ["qty", "position"]
  get_jobs:
    description: """
      Gets a list of the jobs in the printer's queue.
    """
