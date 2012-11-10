require = __meteor_bootstrap__.require
spawn = require('child_process').spawn

Meteor.publish "projects", () ->
  Projects.find
    owner: this.userId

Meteor.publish "files", (project_id) ->
  Files.find
    project: project_id

Meteor.methods
  pandoc: (from, to, text) ->
    fut = new Future()
    p = spawn("pandoc", ['-f', from, '-t', to])
    p.stdout.on 'data', (data) ->
      fut.ret(data)
    p.stdin.write(text)
    p.stdin.end()
    fut.wait()
    fut.value.toString()
