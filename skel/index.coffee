{Application, Controller, CLI} = require('jackson')

class $APPLICATION_NAME$ extends Application
  @route '/', ->
    @render 'index.html'

app = new $APPLICATION_NAME$()

if require.main is module
  new CLI(app).run()
else
  module.exports = app

