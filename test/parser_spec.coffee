expect = require("chai").expect
_ = require 'lodash'
parser = require("../lib/parser.coffee")

scenarios = 
  # Set: Extruders, Beds, Fans and Conveyors
  "set e0 on":         e0: {enabled: true}
  "set e on":          e0: {enabled: true}
  "set b on":          b:  {enabled: true}
  "set fan on":        f:  {enabled: true}
  "set conveyor on":   c:  {enabled: true}
  "set e1 temp 220":   e1: {enabled: true, target_temp: 220}
  "set b temp 220":    b:  {enabled: true, target_temp: 220}
  # Set: Jobs
  "set AAFFB position 1":       aaffb:  {position: 1}
  "set AAFFB qty 15":           aaffb:  {qty: 15}
  # Move
  "move x  10":                 x: 10
  "move x:   10":               x: 10
  "move x: 10 @150%":           x: 10, at: 1.5
  "move x: 10 y: 20 z 1 @200%": x: 10, y: 20, z: 1, at: 2
  # Extrude
  "extrude e: 10 @150%":        e0: 10, at: 1.5
  "extrude e1: 10 @150%":       e1: 10, at: 1.5
  # Home
  "home":                       ['x', 'y', 'z']
  "home x":                     ['x']
  "home x y":                   ['x', 'y']
  # Add Job
  "add_job ~/my test job.stl":  "~/my test job.stl"
  # Rm Job
  "rm_job AAFFB":               "aaffb"
  # Other Commands
  "help": undefined
  "exit": undefined
  "get_jobs": undefined
  "estop": undefined
  "print": undefined
  "retry_print": undefined

errorScenarios =
  ["help a b", "move", "set", "set e", "set fan", "set on", "add_job", "lolwut"]

components =
  e0: {type: "heater"}
  e1: {type: "heater"}
  b: {type: "bed"}
  c: {type: "conveyor"}
  f: {type: "fan"}
  AAFFB: {type: "job"}

commands = require("../lib/commands.coffee")(components)

addEqualityTest = (string, obj) ->
  it "should parse \"#{string}\"", ->
    expect(parser.toJSON(string, commands).data).to.deep.equal obj

addErrorTest = (string) ->
  it "should error on parsing \"#{string}\"", ->
    expect(-> parser.toJSON(string, commands)).to.throw()

describe "Parser", ->
  describe "toJSON", ->
    addEqualityTest(string, obj) for string, obj of scenarios
    addErrorTest(string) for string in errorScenarios
