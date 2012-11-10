require = __meteor_bootstrap__.require
exec = require('child_process').exec
fs = require('fs')
path = require('path')

TEXT_FORMATS = ['html', 'latex', 'markdown', 'plain', 'rst', 'org', 'mediawiki']
BINARY_FORMATS = ['pdf', 'odt', 'epub', 'docx', 'rtf']
BASE_PATH = path.resolve('.')

pandoc = (filename, to, text, next) ->
  exts =
    'beamer': 'pdf'
  exec "mktemp", (e, tempfile, o) ->
    tempfile = tempfile.trim()
    input = "#{tempfile}.#{filename.split('.').pop()}"
    output = "#{tempfile}.#{exts[to] or to}"
    if to == 'pdf'
      to = 'latex'
    fs.writeFile input, text, (err, res) ->
      exec "pandoc -t #{to} --webtex -o #{output} #{input}", (error, stdout, stderr) ->
        next(error, output)

publicPath = (file) ->
  [BASE_PATH, 'public', 'render', file.owner, file.project, file.filename].join '/'

publicUrl = (file) ->
  Meteor.absoluteUrl(['render', file.owner, file.project, file.filename].join '/')

Meteor.publish "projects", () ->
  Projects.find
    owner: this.userId

Meteor.publish "files", (project_id) ->
  Files.find {project: project_id}, {sort: filename: 1}

Meteor.methods
  pandoc: (filename, to, text) ->
    fut = new Future()
    pandoc filename, to, text, (err, res) ->
      fs.readFile res, (error, data) ->
        fut.ret data
  
    fut.wait()
    fut.value.toString()

  render: (file, format) ->
    pandoc file.filename, format, file.contents, (err, filename) ->
        exec "mkdir -p `dirname #{publicPath(file)}`", (err, stdout, stderr) ->
          exec "mv #{filename} #{publicPath(file)}.#{format}", (err, stdout, stderr) ->

    "#{publicUrl(file)}.#{format}"
