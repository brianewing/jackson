global.Jackson = require('..')

global.assert = require('chai').assert
global.expect = require('chai').expect

global.async = require('async')

httpMocks = require('node-mocks-http')
global.stubReqRes = (reqOptions={}, resOptions={}) ->
  [httpMocks.createRequest(reqOptions), httpMocks.createResponse(resOptions)]
