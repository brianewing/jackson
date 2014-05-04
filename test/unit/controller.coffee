describe "Jackson.Controller", ->
  it 'calls #initialize() when constructed', ->
    controller = new class extends Jackson.Controller
      initialize: ->
        @initializeCalled = true

    expect(controller.initializeCalled).to.equal(true)

  it 'sets headers with #header(name, value)', ->
    controller = new Jackson.Controller
    controller.header('Foo-Bar', 'baz')

    expect(controller.headers['foo-bar']).to.equal('baz')

  describe '#apply()', ->
    it 'calls functions in the context of the controller', ->
      controller = new Jackson.Controller
      controller.apply -> expect(@).to.equal(controller)

  describe '#applyAsAction()', ->
    it 'calls functions with route segments as arguments', ->
      controller = new Jackson.Controller({}, stubReqRes()..., {foo: 'bar', bar: 'baz', id: 123})
      controller.applyAsAction (foo, bar, id) ->
        expect(@).to.equal(controller)

        expect(foo).to.equal('bar')
        expect(bar).to.equal('baz')
        expect(id).to.equal(123)

  describe 'Callbacks', ->
    it 'dispatches callbacks in the correct order', ->
      controller  = new class extends Jackson.Controller
        @beforeAll 'one', 'two'
        @beforeAll -> @three()

        @before 'test', 'four', 'five'
        @before 'test', -> @six()

        @afterAll 'seven', 'eight'
        @afterAll -> @nine()

        @after 'test', 'ten', 'eleven'
        @after 'test', -> @twelve()

        order: []

        initialize: ->
          @methods = ['one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven', 'twelve']
          @methods.forEach (method) =>
            @[method] = -> @order.push(method)

        test: -> @testCalled = true

      controller.callAction('test')

      expect(controller.order).to.deep.equal(controller.methods)
      expect(controller.testCalled).to.equal(true)

    it 'dispatches asynchronous callbacks sequentially', (done) ->
      controller = new class extends Jackson.Controller
        @beforeAll 'foo'
        @beforeAll 'bar'
        @before 'test', (cb) -> @baz(cb)

        order: []
        foo: (cb) -> @order.push('foo'); process.nextTick(cb)
        bar: (cb) -> @order.push('bar'); process.nextTick(cb)
        baz: (cb) -> @order.push('baz'); process.nextTick(cb)

        test: -> @testCalled = true

      controller.callAction 'test', ->
        expect(controller.order).to.deep.equal(['foo', 'bar', 'baz'])
        expect(controller.testCalled).to.equal(true)

        done()

  describe 'Responding', ->
    response = {status: null, headers: null, body: null}

    stubApp =
      renderTemplate: -> 'rendered template'

    [stubReq, stubRes] = stubReqRes()

    stubRes.writeHead = (status, headers) ->
      response.status = status
      response.headers = headers

    stubRes.end = (body) ->
      response.body = body

    it 'renders templates', ->
      controller = new Jackson.Controller(stubApp, stubReq, stubRes, {})
      controller.test = -> @render('unused')

      controller.callAction 'test'

      expect(response.status).to.equal(200)
      expect(response.headers['content-length']).to.equal(stubApp.renderTemplate().length)
      expect(response.headers['content-type']).to.equal('text/html')
      expect(response.body).to.equal(stubApp.renderTemplate())

    it 'responds with JSON', ->
      user = {name: 'Joe', email: 'joe@bloggs.dev'}

      controller = new Jackson.Controller(stubApp, stubReq, stubRes, {})
      controller.test = -> @respond(123, user)

      controller.callAction 'test'

      expect(response.status).to.equal(123)
      expect(response.headers['content-length']).to.equal(JSON.stringify(user).length)
      expect(response.headers['content-type']).to.equal('application/json')
      expect(response.body).to.equal(JSON.stringify user)

