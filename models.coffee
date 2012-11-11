#References = new Meteor.Collection('references')
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
        contents: options.contents or ""

  createProject: (options) ->
    options = options or {}
    if options.name
      Projects.insert
        owner: this.userId
        name: options.name

        ###
  createReference: (options) ->
    options = options or {}
    if options.filename and options.bibtex
      References.insert
        owner: this.userId
        filename: options.filename
        bibtex: options.bibtex

        ###
