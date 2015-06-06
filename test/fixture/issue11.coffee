# Dependencies
expect= require('chai').expect

# Fixture
fixtureFixture= require './test004'

# Specs
describe 'cover to code',->
  it '(#issue11 fixture)',->
    expect(fixtureFixture('Hello')).to.equal "Hello Path"