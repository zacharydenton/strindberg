require = __meteor_bootstrap__.require
exec = require('child_process').exec
fs = require('fs')
fibers = require("fibers")
connect = require('connect')
app = __meteor_bootstrap__.app

TEXT_FORMATS = ['html', 'latex', 'markdown', 'plain', 'rst', 'org', 'mediawiki']
BINARY_FORMATS = ['pdf', 'odt', 'epub', 'docx', 'rtf']

router = connect.middleware.router (route) ->
  route.get '/render', (req, res) ->
    file = Files.findOne({_id: req.query.file})
    if file?
      format = req.query.format or 'html'
      if format == 'pdf'
        res.writeHead 200,
          'Content-Type': 'application/pdf'
      else if format in ['html']
        res.writeHead 200
      else if format in TEXT_FORMATS
        res.writeHead 200,
          'Content-Type': 'text/plain'
          'Content-Disposition': "attachment; filename=#{file.filename}.#{format}"
      else
        res.writeHead 200,
          'Content-Type': 'application/octet-stream'
          'Content-Disposition': "attachment; filename=#{file.filename}.#{format}"
      res.end(Meteor.call('pandoc', file.filename, format, file.contents))
    else
      res.writeHead(404)
      res.end('here')
app.use(router)

Meteor.publish "projects", () ->
  Projects.find
    owner: this.userId

Meteor.publish "files", (project_id) ->
  Files.find {project: project_id}, {sort: filename: 1}

Meteor.methods
  pandoc: (filename, to, text) ->
    exts = {
      'beamer': 'pdf'
    }
    fut = new Future()
    exec "mktemp", (e, tempfile, o) ->
      tempfile = tempfile.trim()
      input = "#{tempfile}.#{filename.split('.').pop()}"
      output = "#{tempfile}.#{exts[to] or to}"
      if to == 'pdf'
        to = 'latex'
      fs.writeFile input, text, (err, res) ->
        exec "pandoc -t #{to} --webtex -o #{output} #{input}", (error, stdout, stderr) ->
          fs.readFile output, (error, data) ->
            fut.ret data
  
    fut.wait()
    fut.value.toString()

