Jackson = require('jackson')

class $APPLICATION_NAME$ extends Jackson.Application
  templateRoot: __dirname + '/templates'

  @route '/', ->
    @render 'index.html'

app = new $APPLICATION_NAME$()

if require.main is module
  app.startCli()
else
  module.exports = app

