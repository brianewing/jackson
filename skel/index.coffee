Jackson = require('jackson')

class $APPLICATION_NAME$ extends Jackson.Application
  templateRoot: __dirname + '/templates'

  @route '/', ->
    @render 'index.html'

app = new $APPLICATION_NAME$()

if require.main is module
  new Jackson.CLI(app).run()
else
  module.exports = app

