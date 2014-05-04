describe 'Routing', ->
  call = (app, url) ->
    app.dispatchUrl(stubReqRes()..., 'GET', url)

  it 'routes to a function', ->
    called = false

    class Test extends Jackson.Application
      @route '/', -> called = true

    call new Test, '/'
    expect(called).to.equal(true)

