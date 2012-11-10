RENDER_API = 'http://localhost:9000'

Meteor.subscribe('files')

Meteor.startup () ->
  Meteor.autorun () ->
    unless Session.get("selected")
      file = Files.findOne()
      if (file)
        Session.set("selected", file._id)

Template.editor.rendered = ->
  editor = new EpicEditor(
    parser: (text) ->
      file = Files.findOne({_id: Session.get('selected')})
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
  ).load()
  editor.on 'save', () ->
    file = Files.findOne({_id: Session.get('selected')})
    Files.update {_id: Session.get('selected')},
      $set:
        contents: editor.exportFile()
    Meteor.call('saveFile', file);

  window.editor = editor

Template.render.events
  'change .filetypes': (e) ->
    console.log $(e.srcElement).val()

Template.files.events
  'click .filename': (e) ->
    file = Files.findOne({_id: e.srcElement.id})
    Session.set("selected", file._id)
    editor.importFile file.filename, file.contents
  'keyup input': (e) ->
    if e.keyCode == 13
      Meteor.call 'createFile',
        filename: $(e.srcElement).val()

Template.files.files = ->
  Files.find()

