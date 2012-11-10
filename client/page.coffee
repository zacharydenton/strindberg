RENDER_API = 'http://localhost:9000'

Template.editor.rendered = ->
  editor = new EpicEditor(
    parser: (text) ->
      Meteor.call 'pandoc', 'html', text, (err, res) ->
        editor.previewer.innerHTML = res
      null
    theme:
      preview: '/themes/preview/svbtle.css'
  ).load()
  window.editor = editor

Template.render.events
  'change .filetypes': (e) ->
    console.log $(e.srcElement).val()

