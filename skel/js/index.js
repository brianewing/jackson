var Jackson = require('jackson');

var $APPLICATION_NAME$ = Jackson.Application.extend({
  name: "$APPLICATION_NAME$",
  templateRoot: __dirname + '/templates'
}, function() {
  this.route('/', function() {
    this.render('index.html');
  });
});

var app = new $APPLICATION_NAME$;

// ~
module.exports = app;
if(module == require.main)
  app.startCli();
