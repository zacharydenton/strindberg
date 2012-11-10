RENDER_API = 'http://localhost:9000'

Meteor.startup () ->
  unless Projects.findOne()
    Meteor.call 'createProject',
      name: 'Default'

Meteor.subscribe 'projects', () ->
  unless Session.get("selected_project")
    project = Projects.findOne()
    if (project)
      Session.set("selected_project", project._id)

Meteor.autosubscribe () ->
  project_id = Session.get("selected_project")
  if project_id
    Meteor.subscribe 'files', project_id

Meteor.saveFile = (blob, name, path, type, callback) ->
  fileReader = new FileReader()
  encoding = 'binary'
  type = type or 'binary'
  if type == 'text'
    method = 'readAsText'
    encoding = 'utf8'
  else if type == 'binary'
    method = 'readAsBinaryString'
    encoding = 'binary'
  else
    method = 'readAsBinaryString'
    encoding = 'binary'

  fileReader.onload = (file) ->
    Meteor.call('saveFile', file.srcElement.result, name, path, encoding, callback)

  fileReader[method](blob)

Template.editor.rendered = ->
  editor = new EpicEditor
    clientSideStorage: no
    focusOnLoad: yes
    file:
      autoSave: 5000
    parser: (text) ->
      file = Files.findOne({_id: Session.get('selected_file')})
      if file?
        Meteor.call 'pandoc', file.filename, 'html', text, (err, res) ->
          editor.previewer.innerHTML = res
    theme:
      preview: '/themes/preview/svbtle.css'
  editor.load()
  Template.editor.selectFile Session.get('selected_file')
  editor.on 'save', () ->
    file = Files.findOne({_id: Session.get('selected_file')})
    text = editor.exportFile()
    if text and file? and file.contents != text
      console.log text
      Files.update {_id: file._id},
        $set:
          contents: editor.exportFile()
  window.editor = editor

Template.editor.selectFile = (file_id) ->
  file = Files.findOne({_id: file_id})
  if file?
    Session.set("selected_file", file_id)
    editor.importFile file.filename, file.contents

Template.render.events
  'change .filetypes': (e) ->
    file = Files.findOne({_id: Session.get('selected_file')})
    Meteor.call 'render', file, $(e.srcElement).val(), (err, res) ->
      window.location = res

Template.files.events
  'keyup input': (e) ->
    if e.keyCode == 13
      Meteor.call 'createFile',
        filename: $(e.srcElement).val()
        project: Session.get('selected_project')
      , (err, res) ->
        if res?
          Template.editor.selectFile(res)
      $(e.srcElement).val('')

Template.files.files = ->
  Files.find()

Template.file.selected = ->
  if Session.get('selected_file') == this._id then 'active' else ''

Template.file.events
  'click': (e) ->
    Template.editor.selectFile(this._id)

Template.upload.events
  'change input': (ev) ->
    _.each ev.srcElement.files, (file) ->
      Meteor.saveFile(file, file.name, Projects.findOne {_id: Session.get('selected_project')})
      Meteor.call 'createFile',
        filename: file.name
        project: Session.get('selected_project')


