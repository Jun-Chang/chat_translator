user = $("#username").val()
langs = ['ja', 'en', 'zh-CHS']
send = {ja: '送信', en:'send', 'zh-CHS': '传输'}

$(document).ready ->
  $('#tab').tabs()

  $('a.lang').click ->
    lang = $(this).attr "name"
    $("#from").val lang
    $("#send").val send[lang]
    false
  false

socket = null
$ ->
  socket = io.connect()
  socket.emit 'login', user

  socket.on 'res', (from, msgs) ->
    displayChat from, msgs

  socket.on 'updateLoginUsers', (users) ->
    console.log "updateLoginUsers users= #{users}"
    updateLoginUsers users
  $('form').submit (e) ->
    chat()
    false

  false

#update logged in user
updateLoginUsers = (users) ->
  console.log users
  for lang in langs
    $("div##{lang}.loginUsers p span").remove()

    for i in users
      $("div##{lang}.loginUsers p").append($('<span>').text(users[i]))

#send message
chat = ->
  msg = $('input.chatText').val()
  from_lang = $("#from").val()
  $('input.chatText').val('').focus()
  socket.emit 'chat', user, msg, from_lang

  $('div,chatDiv').animate scrollTop: 2000000, 'fast'

  false

#display message
displayChat = (from, msgs) ->
  for msg of msgs
    _id = msgs[msg]['lang']
    _val = msgs[msg]['value']

    nameDom = $('<p>').addClass('name').text "#{from} : "
    trDom = $ '<tr>'
    trDom.append $('<td>').addClass('nameTd').append nameDom
    chatDom = $('<p>').addClass('chat').text(_val)
    trDom.append $('<td>').addClass('chatTd').append chatDom

    $("table##{_id}_tbl").append trDom

