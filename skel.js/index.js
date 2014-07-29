var Jackson = require('jackson');

var $APPLICATION_NAME$ = Jackson.Application.extend({
  name: "$APPLICATION_NAME$",
  templateRoot: __dirname + '/templates'
});

$APPLICATION_NAME$.route('/', function() {
  this.render('index.html');
});

module.exports = new $APPLICATION_NAME$;
if(require.main === module) module.exports.startCli();

