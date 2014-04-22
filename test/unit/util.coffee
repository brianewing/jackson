{extend, clone, ClassHelpers} = require('../../lib/util')

describe 'Utils', ->
  describe 'extend', ->
    it 'shallow-copies a number of objects into an object', ->
      a = {foo: 1, bar: 2, deep: {one: 1}}
      b = {foo: 2, bar: 3}
      c = {foo: 3, deep: {}}

      extend a, b, c

      expect(a.foo).to.equal(3)
      expect(a.bar).to.equal(3)
      expect(a.deep).to.deep.equal({})

  describe 'clone', ->
    joe = {name: 'Joe', age: 20, likes: 'basketball'}
    mike = {name: 'Mike'}

    it 'shallow-clones an object', ->
      joeClone = clone(joe)
      expect(joeClone).to.deep.equal(joe)
      expect(joeClone).not.to.equal(joe)

    it 'copies properties of other objects onto the clone', ->
      moe = clone(joe, mike)
      expect(moe).not.to.equal(joe)
      expect(moe).to.deep.equal(name: 'Mike', age: 20, likes: 'basketball')

  describe 'Class helpers', ->
    class Animal
      ClassHelpers(@)

      eats: 'food'
      greet: -> 'animal'

    class Dog extends Animal
      eats: 'meat'
      greet: -> 'woof'

    describe 'provides .extend()', ->
      it 'makes a subclass', ->
        Terrier = Dog.extend()
        spot = new Terrier()

        expect(Terrier).not.to.equal(Dog)
        expect(spot.greet()).to.equal('woof')
        expect(spot).to.be.an.instanceOf(Dog)

      it 'takes an object with which to extend the prototype', ->
        Terrier = Dog.extend(breed: 'terrier')
        expect(Terrier.prototype.breed).to.equal('terrier')

      it 'takes a function to apply in the context of the new class', ->
        Terrier = Dog.extend ->
          @foo = 'bar'

        expect(Terrier.foo).to.equal('bar')

      it 'takes any number of functions and objects to extend', ->
        Terrier = Dog.extend(
          {breed: 'terrier'},
          (-> @foo = ['bar']),
          (-> @foo.push('baz')),
          {foo: 'bar'}
        )

        expect(Terrier.foo).to.eql(['bar', 'baz'])
        expect(Terrier.prototype.breed).to.equal('terrier')
        expect(Terrier.prototype.foo).to.equal('bar')

    describe 'provides #bind()', ->
      it 'binds a function to the context of the object', ->
        fn = -> @greet()
        bound = new Dog().bind(fn)

        expect(bound()).to.equal('woof')

      it 'curries arguments', ->
        fn = (one, two) -> [@greet(), one, two]
        bound = new Dog().bind(fn, 'foo', 'bar')

        expect(bound()).to.eql(['woof', 'foo', 'bar'])
