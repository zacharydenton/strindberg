Files = new Meteor.Collection('files')

Meteor.methods
  createFile: (options) ->
    options = options or {}
    if options.filename
      Files.insert
        owner: this.userId
        filename: options.filename
        contents: options.contents or ""

