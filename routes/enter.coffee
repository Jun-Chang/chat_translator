exports.enter = (req, res) ->
  result =
    title : 'Chat Translator',
    username : req.body.username
  res.render 'room', result

