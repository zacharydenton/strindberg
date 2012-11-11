require = __meteor_bootstrap__.require
exec = require('child_process').exec
fs = require('fs')
path = require('path')
app = __meteor_bootstrap__.app

TEXT_FORMATS = ['html', 'latex', 'markdown', 'plain', 'rst', 'org', 'mediawiki']
BINARY_FORMATS = ['pdf', 'odt', 'epub', 'docx', 'rtf']
BASE_PATH = path.resolve('.')
if process.env.WEB_ROOT
  WEB_ROOT = process.env.WEB_ROOT
else
  WEB_ROOT = BASE_PATH + '/' + 'public'

pandoc = (filename, to, text, next) ->
  exec "mktemp", (e, tempfile, o) ->
    tempfile = tempfile.trim()
    input = "#{tempfile}.#{filename.split('.').pop()}"
    output = "#{tempfile}.#{formatExtension to}"
    if to == 'pdf'
      to = 'latex'
    fs.writeFile input, text, (err, res) ->
      exec "pandoc -t #{to} --webtex --latex-engine=xelatex -s #{input} -o #{output}", (error, stdout, stderr) ->
        next(error, output)

filePath = (file) ->
  [WEB_ROOT, 'render', file.owner, file.project, file.filename].join '/'

Meteor.publish "projects", () ->
  Projects.find
    owner: this.userId

Meteor.publish "files", (project_id) ->
  Files.find {project: project_id}, {sort: filename: 1}

Meteor.publish "versions", (file_id) ->
  Versions.find {file: file_id}, {sort: version: 1}

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
      exec "mkdir -p `dirname #{filePath(file)}`", (err, stdout, stderr) ->
        exec "mv #{filename} #{filePath(file)}.#{formatExtension format}"

    "#{fileUrl(file)}.#{format}"

  saveFile: (blob, name, project, encoding) ->
    cleanPath = (str) ->
      if str
        str.replace(/\.\./g,'').replace(/^\/+/,'').replace(/\/+$/,'')

    cleanName = (str) ->
      str.replace(/\.\./g,'').replace(/\//g,'')

    path = cleanPath("render/#{project.owner}/#{project._id}")
    name = cleanName(name or 'file')
    encoding = encoding or 'binary'
    chroot = Meteor.chroot or 'public'
    path = chroot + (if path then '/' + path + '/' else '/')
    
    exec "mkdir -p `dirname #{path + name}`", (err, stdout, stderr) ->
      fs.writeFile path + name, blob, encoding

    true

