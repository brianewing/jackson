fs = require('fs')
path = require('path')
{spawn} = require('child_process')

minimist = require('minimist')
pascalCase = require('pascal-case')
snakeCase = require('snake-case')
paramCase = require('param-case')

open = require('open')

{jacksonVersion, extend, clone} = require('./util')

class CLI
  constructor: (@app, argv) ->
    @argv = argv || process.argv.slice(2)
    @args = minimist(@argv)

    @commands = clone(@jacksonCommands)
    extend(@commands, @appCommands) if @app

  run: ->
    [command, params...] = @args._

    for own arg, value of @args when value is true and not command
      # flags without arguments may also be commands, eg '--version'
      if @commands[arg]
        command = arg

    command ||= 'default'
    handler = @handler(command)

    if handler
      handler.apply(@, params)
      return true
    else
      @handler('missing').apply(@, @args._)
      return false

  printUsage: (command, usage...) ->
    console.log "usage:", "jack".yellow, command.yellow, usage...

  handler: (command) ->
    handler = @commands[command]
    handler = @commands[handler] while typeof handler is 'string'
    handler

  # general commands
  jacksonCommands:
    default: 'help'
    missing: 'help'

    h: 'help'
    help: ->
      versionString = "Jackson v#{jacksonVersion}"

      console.log Array(versionString.length + 1).join("-")
      console.log versionString
      console.log Array(versionString.length + 1).join("-")
      console.log()

      jacksonHelp = """
        Jackson commands:
          #{'new'.yellow}: Create a new Jackson project
            usage: jack new MyApp
      """

      appHelp = """
        Application commands:
          #{'server'.yellow}: Start the web server (alias 's')
            --port=1234 - Listen on a port (default, alias '-p')
            --host=localhost - Bind to a specific host when listening on a port
            --socket=/path/to/socket - Listen on a socket

            --open - Open the URL in your default web browser after listening

          #{'repl'.yellow}: Start a REPL (alias 'r')
      """

      if @app
        console.log jacksonHelp
        console.log ""
        console.log appHelp
      else
        console.log jacksonHelp

    new: (applicationName, directory) ->
      if not applicationName
        @printUsage "new", "MyApp".white, "[directory]"
        return

      directory ||= path.join process.cwd(), snakeCase(applicationName)

      vars =
        APPLICATION_NAME: pascalCase(applicationName)
        PACKAGE_NAME: paramCase(applicationName)
        JACKSON_VERSION: jacksonVersion

      if not fs.existsSync(directory) or not fs.statSync(directory).isDirectory()
        fs.mkdirSync(directory)

      copyFiles = (source, dest) ->
        for fileName in fs.readdirSync(source)
          sourcePath = path.join(source, fileName)
          destPath = path.join(dest, fileName)

          if fs.statSync(sourcePath).isDirectory()
            fs.mkdirSync(destPath) unless fs.existsSync(destPath)
            copyFiles(sourcePath, destPath)
          else
            console.log "Copying".yellow, sourcePath.white, "=>".yellow, destPath.white
            contents = fs.readFileSync(sourcePath).toString()

            for own name, value of vars
              # replace all $name$ with value
              contents = contents.split("$#{name}$").join(value)

            fs.writeFileSync(destPath, contents.trim())

      skelDir = __dirname + '/../' + (if @args.js then 'skel.js' else 'skel')
      copyFiles(skelDir, directory)

      console.log()
      console.log "Running npm install..."

      install = spawn "npm", ["install"],
        cwd: directory
        stdio: ['ignore', 'ignore', 'ignore']

      install.on 'close', (status) ->
        console.log ""

        if status is 0
          console.log "New application #{vars.APPLICATION_NAME.yellow} created in #{directory.yellow}"
        else
          console.log "Error during npm install".red
          console.log "The new application has been left in #{directory} for you to investigate"

    v: 'version'
    version: ->
      console.log "Jackson v#{jacksonVersion}"

  # commands to run against a Jackson application
  appCommands:
    default: 'server'

    s: 'server'
    server: ->
      socketOrPort = @args.socket || parseInt(@args.port || @args.p) || 1234
      bindOn = @args.host

      @app.listen socketOrPort, bindOn, (port, host) =>
        if @args.open && typeof socketOrPort is 'number'
          host ||= "localhost"
          open("http://#{host}:#{port}/")

    c: 'repl'
    r: 'repl'
    repl: ->
      @app.startRepl()

module.exports = CLI
