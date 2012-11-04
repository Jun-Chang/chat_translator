# GET home page.
exports.index = (req, res) ->
  res.render 'index', title: 'Chat Translator'

