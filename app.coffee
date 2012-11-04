express = require 'express'
http = require 'http'
app = express()
server = http.createServer app
sio = require('socket.io').listen server

app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use require('stylus').middleware(
    src: __dirname + '/public'
  )
  app.use app.router
  `app.use(express.static(__dirname + '/public'))`

app.configure 'development', ->
  app.use express.errorHandler 
    dumpExceptions : true
    showStack : true
app.configure 'production', ->
  app.use express.errorHandler()

server.listen process.env.PORT || 3000

#routing
routes = require './routes'
app.get '/', routes.index

routes2 = require './routes/enter'
app.post '/enter', routes2.enter

io = sio
routes3 = require './routes/chat'
routes3.io = io

# for client connection
io.sockets.on 'connection', routes3.chat

