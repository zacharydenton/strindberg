wordCount = (str) ->
  words = str.match(/\S+/g)
  if words?
    words.length
  else
    0

