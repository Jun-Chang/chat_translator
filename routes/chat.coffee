#require modules
cheerio = require 'cheerio'
http = require 'http'
https = require 'https'
querystring = require 'querystring'

#properties?
exports.users = {}
exports.messages = []
exports.login = [
  {lang:'ja', value: 'がログインしました'}
  {lang:'en', value: ' is logged in'}
  {lang:'zh-CHS', value: '登录'}
]
exports.logout = [
  {lang:'ja', value: 'がログアウトしました'}
  {lang:'en', value: ' is logged out'}
  {lang:'zh-CHS', value: '注销'}
]
exports.accessToken = null

#action
exports.chat = (client) ->
  users = exports.users
  messages = exports.messages
  io = exports.io
  console.log client.sessionId + ' is connected.'

  # for log in
  client.on 'login', (user) ->
    console.log users
    users[user] = user
    client.user = user
    io.sockets.emit 'updateLoginUsers', users

    msgs = []
    login = exports.login
    for l of login
      msgs.push {lang: login[l]['lang'], value: client.user + login[l]['value']}
    console.log 'login. past messages => '
    for key of messages
      console.log messages[key]
      client.emit 'res', messages[key]['user'], messages[key]['msgs']
    messages.push
      'user' : 'system',
      'msgs' : msgs
    io.sockets.emit 'res', 'system', msgs

  # for receive message
  client.on 'chat', (from, msg, from_lang) ->
    console.log "message received. (from = #{from}, msg = #{msg}, from_lang=#{from_lang})"
    translationManager = new TranslationManager msg, from_lang, (results) ->
      #push original message
      results.push({lang:from_lang, value:msg})
      console.log results
      messages.push
      'user' : from,
      'msgs' : results
      # broadcast
      io.sockets.emit 'res', from, results

    translationManager.run()

  # for disconnect
  client.on 'disconnect', ->
    console.log "#{client.sessionId} is disconnected."
    delete users[client.user]
    io.sockets.emit 'updateLoginUsers', users

    msgs = []
    logout = exports.logout
    for l of logout
      msgs.push {lang: logout[l]['lang'], value: client.user + logout[l]['value']}

    io.sockets.emit 'res', 'system', msgs
    messages.push
      'user' : 'system',
      'msg' : msgs

#classes for translation
class TranslationManager
  constructor: (@orgMsg, @from ,@callerCallback) ->

  to: []
  results: []

  run: =>
    @to = ['ja', 'en', 'zh-CHS']
    _to = []
    for t in @to
      console.log 't => ' + t + '@from =>' + @from
      _to.push t if t != @from
    @to = _to

    @results = []

    httpRequester =  new HttpRequester @orgMsg, @from, @callback
    httpRequester.run @to[0]

  callback: (result) =>
    @results.push result

    #console.log '@to =>' + @to
    #console.log '@results' + @results
    if @results.length >= @to.length
      @callerCallback @results
    else
      httpRequester =  new HttpRequester @orgMsg, @from, @callback
      httpRequester.run @to[@results.length]

class HttpRequester
  constructor: (@orgMsg, @from ,@callerCallback) ->

  host: "api.microsofttranslator.com"
  path: "/v2/Http.svc/Translate"
  to: null

  run: (to) =>
    @to = to
    tokenManager = new TokenManager @callback
    tokenManager.run()

  callback: (token) =>
    param = querystring.stringify
      text: @orgMsg
      to: @to
      from: @from

    options =
      host: @host
      path: @path + "?#{param}"
      port: 80
      method: 'GET'
      headers:
        "Authorization": "Bearer #{token}"
        "Content-Type": "text/xml"

    that = @
    req = http.request options, (res) ->
      res.setEncoding 'utf8'
      res.on 'data', (data) ->
        #console.log data
        obj = cheerio.load data,
          ignoreWhitespace: true
          xmlMode: true
        result = {lang: that.to, value: obj._root.children[0].children[0].data}

        that.callerCallback result
    req.end()

class TokenManager
  constructor: (@callerCallback) ->

  clientId: process.env.clientId
  clientSecret: process.env.clientSecret
  host: "datamarket.accesscontrol.windows.net"
  path: "/v2/OAuth2-13/"
  scope: "http://api.microsofttranslator.com"
  grantType: "client_credentials"

  run: =>
    token = exports.accessToken
    if token && token.expires >  parseInt new Date() / 1000
      return @callerCallback token.value

    # get access token from API.
    param = querystring.stringify
      grant_type: @grantType
      scope: @scope
      client_id: @clientId
      client_secret: @clientSecret

    options =
      host: @host
      path: @path
      port: 443
      method: 'POST'

    that = @
    req = https.request options, (res) ->
      #console.log "statusCode: ", res.statusCode
      #console.log "headers: ", res.headers
      res.setEncoding 'utf8'
      res.on 'data', (data) ->
        #console.log data
        obj = JSON.parse data
        exports.accessToken = 
          value: obj.access_token
          expires : parseInt(new Date() / 1000) + parseInt obj.expires_in
        #console.log 'time:' + parseInt new Date() / 1000
        #console.log 'expires:' + exports.access_token.expires
        that.callerCallback exports.accessToken.value
    req.write param
    req.end()

