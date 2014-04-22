require('coffee-script/register');

var repl = require('repl');
var context = repl.start({useGlobal: true}).context;

context.async = require('async');
context.Jackson = require('..');
