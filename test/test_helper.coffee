global.Jackson = require('..')

global.assert = require('chai').assert
global.expect = require('chai').expect

global.async = require('async')

http = require('http')
global.stubReqRes = (reqOptions={}, resOptions={}) ->
  [req = new http.ClientRequest(reqOptions), new http.ServerResponse(req)]
