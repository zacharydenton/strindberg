#References = new Meteor.Collection('references')
Versions = new Meteor.Collection('versions')
Projects = new Meteor.Collection('projects')
Files = new Meteor.Collection('files')

fileUrl = (file) ->
  Meteor.absoluteUrl(['render', file.owner, file.project, file.filename].join '/')

projectUrl = (project) ->
  Meteor.absoluteUrl(['render', project.owner, project._id].join '/')

formatExtension = (format) ->
  exts =
    'beamer': 'pdf'
    'dzslides': 'html'
    's5': 'html'
    'slideous': 'html'
    'slidy': 'html'
  exts[format] or format

Meteor.methods
  createFile: (options) ->
    options = options or {}
    if options.filename and options.project
      Files.insert
        owner: this.userId
        project: options.project
        filename: options.filename
        version: 1

    return null

  createProject: (options) ->
    options = options or {}
    if options.name
      Projects.insert
        owner: this.userId
        name: options.name

    return null

  createVersion: (file, contents) ->
    if file? and contents?
      Versions.insert
        owner: this.userId
        file: file._id
        version: file.version + 1
        contents: contents
      Files.update {_id: file._id},
        $set:
          version: file.version + 1
          contents: contents

    return null
