fs = require "fs-extra"
path = require ("flavored-path")
glob = require 'glob'
os = require 'os'

longestPrefix = (a, b) ->
  longest = null
  longest ?= a[0..-i] for i in [1..a.length] when b.startsWith(a[0..-i])
  return longest

homeDir = ( ->
  drive = process.env.HOMEDRIVE || ""
  drive + (process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE)
)()

homeDir = homeDir.replace '\\', '/' if os.platform().startsWith 'win'

dirAutocomplete = (dir, fileTypes) ->
  # Resolving paths that start with tilds (~)
  if path.isHome dir
    dir = path.normalize path.get dir
    dir = dir.replace '~', homeDir if os.platform().startsWith 'win'

  # Creating a glob to find files that start with the path
  # the user is building.
  out = glob(dir + "*", sync: true).filter (p) =>
    p.endsWith(fileTypes, undefined, false) or fs.lstatSync(p).isDirectory()

  # Attempting to find a common prefix in all the matched paths and 
  # autocomplete that prefix.
  shortest = out.reduce longestPrefix, out[0]
  dir = shortest if shortest? and shortest.length > dir.length

  # dir = dir.replace(/^[A-Za-z]\:\/+/, "\\")
  isDirectory = fs.existsSync(dir) and fs.lstatSync(dir).isDirectory()
  dir += '/' if isDirectory and !dir.endsWith '/'

  return [dir, out]

module.exports = (dir, fileTypes) ->
  try
    dirAutocomplete dir, fileTypes
  catch e # Permissions Error
    # console.log e
    [dir, []]
