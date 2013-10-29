fs = require "fs-extra"
path = require ("flavored-path")
glob = require 'glob'

longestPrefix = (a, b) ->
  longest = null
  longest ?= a[0..-i] for i in [1..a.length] when b.startsWith(a[0..-i])
  return longest


module.exports = (dir) ->
    # Creating a glob to find files that start with the path
    # the user is building.
    # words[1] = "~" if words[1] == "~/"
    # relative = (words[1]||"").indexOf("~") == 0

    dir = path.normalize path.get dir if path.isHome dir

    # console.log dir
    # dir = dir.remove(/^[A-Za-z]\:\/+/)
    out = glob(dir + "*", sync: true).filter (p) =>
      p.endsWith(@_fileTypes) or fs.lstatSync(p).isDirectory()

    # Attempting to find a common prefix in all the matched paths and 
    # autocomplete that prefix.
    shortest = out.reduce longestPrefix, out[0]
    dir = shortest if shortest? and shortest.length > dir.length

    # dir = dir.replace(/^[A-Za-z]\:\/+/, "\\")
    isDirectory = fs.existsSync(dir) and fs.lstatSync(dir).isDirectory()
    dir += path.sep if isDirectory and !dir.endsWith path.sep

    return [dir, out]