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

Meteor.autosubscribe () ->
  file_id = Session.get("selected_file")
  if file_id
    Meteor.subscribe 'versions', file_id

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
  $("#epiceditor").height($(window).height() - 20)
  editor = new EpicEditor
    clientSideStorage: no
    focusOnLoad: yes
    file:
      autoSave: 100
    parser: (text) ->
      file = Files.findOne({_id: Session.get('selected_file')})
      if file?
        Meteor.call 'pandoc', file.filename, 'html', text, (err, res) ->
          editor.previewer.innerHTML = res
    theme:
      preview: '/themes/preview/svbtle.css'
  editor.load()

  editor.on 'save', ->
    text = editor.exportFile()
    Session.set('wordcount', wordCount(text))

  Meteor.setInterval ->
    file = Files.findOne({_id: Session.get('selected_file')})
    if file?
      text = editor.exportFile()
      if text and file.contents != text
        Meteor.call 'createVersion', file, editor.exportFile()
        Session.set 'selected_version', file.version + 1
  , 30000

  window.editor = editor

  if Session.get('selected_file')
    Template.editor.selectFile Session.get('selected_file')
  else
    file = Files.findOne()
    if file
      Template.editor.selectFile file._id

Template.editor.selectFile = (file_id) ->
  file = Files.findOne({_id: file_id})
  if file?
    Session.set("selected_file", file_id)
    Session.set 'selected_version', file.version
    Session.set('wordcount', wordCount(file.contents))
    editor.importFile file.filename, file.contents

Template.editor.selectVersion = (version_number) ->
  version = Versions.findOne {version: version_number}
  if version?
    file = Files.findOne {_id: version.file}
    Session.set 'selected_version', version_number
    Session.set('wordcount', wordCount(version.contents))
    editor.importFile file.filename, version.contents

Template.render.events
  'click button': (e) ->
    file = Files.findOne({_id: Session.get('selected_file')})
    format = $(e.srcElement).val()
    Meteor.call 'render', file, format, (err, res) ->
      bar = Meteor.setInterval () ->
        progress = Session.get 'render_progress'
        if progress
          if progress >= 100
            Meteor.clearInterval bar
            Session.set 'render_progress', null
            window.location = "#{fileUrl file}.#{formatExtension format}"
          else
            Session.set "render_progress", progress + 1
        else
          Session.set "render_progress", 1
      , 30

Template.render.progress = ->
  Session.get 'render_progress'

Template.files.events
  'click .add': (e) ->
    $(e.srcElement).attr('contentEditable', true)
    $(e.srcElement).text('')
    $(e.srcElement).focus()
    $(e.srcElement).bind 'blur', () ->
      $(this).html '<a><i class="icon-plus"></i>Add new</a>'
  'keyup .add': (e) ->
    if e.keyCode == 13
      Meteor.call 'createFile',
        filename: $(e.srcElement).text().trim()
        project: Session.get('selected_project')
      , (err, res) ->
        if res?
          Template.editor.selectFile(res)
      $(e.srcElement).blur()

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

Template.footer.wordcount = () ->
  Session.get('wordcount') or 0

Template.footer.version = () ->
  Session.get('selected_version') or 1

Template.settings.events
  'click #settings': (ev) ->
    $("#settings-list").toggle()
  'click button.logout': (ev) ->
    Meteor.logout()
    $("#settings-list").toggle()

Template.versionselect.maxversion = () ->
  file = Files.findOne {_id: Session.get 'selected_file'}
  if file?
    file.version
  else
    1

Template.versionselect.currentversion = () ->
  Session.get 'selected_version'

Template.versionselect.events
  'mouseup': (ev) ->
    Template.editor.selectVersion parseInt($("#versionselect input").val())
