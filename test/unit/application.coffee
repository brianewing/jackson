describe 'Jackson.Application', ->
  it 'looks up things under its class as a namespace', ->
    class App extends Jackson.Application
      class @Foo
        class @Bar
          @baz = true

    app = new App
    expect(app.lookup('Foo')).to.equal(App.Foo)
    expect(app.lookup('Foo.Bar')).to.equal(App.Foo.Bar)
    expect(app.lookup('Foo.Bar.baz')).to.equal(true)

  it 'dispatches to a controller for a given route', ->
    called = false

    class App extends Jackson.Application
      class @Test extends Jackson.Controller
        foo: -> called = true

    route = {controller: 'Test', action: 'foo'}

    app = new App()
    app.dispatch({}, {}, route)

    expect(called).to.equal(true)

  it 'dispatches under an anonymous controller when the handler is not a controller action', ->
    constructor = null
    class App extends Jackson.Application
      class @Foo
        bar: -> constructor = @constructor

    new App().dispatch({}, {}, controller: 'Foo', action: 'bar')
    expect(constructor).to.equal(Jackson.Controller)

  describe 'Helpers', ->
    it 'adds helpers', ->
      class App extends Jackson.Application
        @helper 'foo', -> 'bar'

      expect(App.helpers.foo()).to.equal('bar')

    it 'works with a class hierarchy', ->
      class App extends Jackson.Application
        @helper 'one', -> 1

      class AppTwo extends App
        @helper 'two', -> 2
        @helper 'three', -> 3

      class AppThree extends AppTwo
        @helper 'four', -> 4

      expect(Object.keys(App.helpers)).to.eql(['one'])
      expect(Object.keys(AppTwo.helpers)).to.eql(['one', 'two', 'three'])
      expect(Object.keys(AppThree.helpers)).to.eql(['one', 'two', 'three', 'four'])

