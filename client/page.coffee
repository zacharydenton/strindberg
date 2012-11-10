RENDER_API = 'http://localhost:9000'

Meteor.subscribe 'projects', () ->
  unless Session.get("selected_project")
    project = Projects.findOne()
    if (project)
      Session.set("selected_project", project._id)

Meteor.autosubscribe () ->
  project_id = Session.get("selected_project")
  if project_id
    Meteor.subscribe 'files', project_id
    unless Session.get("selected_file")
      file = Files.findOne()
      if (file)
        Template.editor.selectFile(file._id)

Template.editor.rendered = ->
  editor = new EpicEditor
    clientSideStorage: no
    parser: (text) ->
      file = Files.findOne({_id: Session.get('selected_file')})
      if file?
        ext = file.filename.split('.').pop()
        if ext == 'tex'
          from = 'latex'
        else
          from = 'markdown'
      else
        from = 'markdown'
      Meteor.call 'pandoc', from, 'html', text, (err, res) ->
        editor.previewer.innerHTML = res
    theme:
      preview: '/themes/preview/svbtle.css'
  window.editor = editor
  editor.on 'save', () ->
    file = Files.findOne({_id: Session.get('selected_file')})
    if file?
      Files.update {_id: file._id},
        $set:
          contents: editor.exportFile()
  editor.load()

Template.editor.selectFile = (file_id) ->
  file = Files.findOne({_id: file_id})
  if file?
    Session.set("selected_file", file_id)
    editor.importFile file.filename, file.contents

Template.render.events
  'change .filetypes': (e) ->
    console.log $(e.srcElement).val()

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

