Projects = new Meteor.Collection('projects')
Files = new Meteor.Collection('files')

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
