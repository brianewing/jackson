Jackson = require('jackson')

class $APPLICATION_NAME$ extends Jackson.Application
  templateRoot: __dirname + '/templates'

  @route '/', ->
    @render 'index.html'

app = new $APPLICATION_NAME$()

# ~
module.exports = app
app.startCli() if module is require.main
