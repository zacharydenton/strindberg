wordCount = (str) ->
  if str?
    str.match(/\S+/g).length
  else
    0

