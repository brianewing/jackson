minimist = require('minimist')

{clone} = require('./util')

class CLI
  constructor: (@app, @argv) ->
    @args = minimist(@argv)

  run: ->
    [command, subcommands...] = @args._

    for own arg, value of @args when value is true and not command
      if @commands[arg]
        command = arg

    command ||= 'default'
    handler = @handler(command) # flags without arguments may also be commands, eg '--version'

    if handler
      handler.apply(@, subcommands)
      return true
    else
      @handler('missing').apply(@, @args._)
      return false

  handler: (command) ->
    handler = @commands[command]
    handler = @commands[handler] while typeof handler is 'string'
    handler

  commands:
    default: 'server'
    missing: 'help'

    s: 'server'
    server: ->
      port = @args.port || @args.p || 3000
      @app.listen(port)

    h: 'help'
    help: ->
      jacksonVersion = require(__dirname + '/../package.json').version
      versionString = "Jackson v#{jacksonVersion}"

      console.log Array(versionString.length + 1).join("-")
      console.log versionString
      console.log Array(versionString.length + 1).join("-")
      console.log()

      console.log """
        Server commands:
          server: Start the web server (alias 's')
            --port=1234 - Listen on a port (alias 'p')
            --socket=/path/to-socket - Listen on a socket
      """
module.exports = CLI
