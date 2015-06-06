# Dependencies
expect= require('chai').expect

exec= (require 'child_process').exec
Promise= require 'bluebird'

# Fixture
$ibrik= (command)->
  bin= require.resolve '../bin/ibrik'
  script= bin+command

  new Promise (resolve,reject)->
    exec script,(error,stdout,stderr)->
      return reject error if error?

      resolve stdout

# Specs
describe 'issue#11',->
  it 'Include test/**',(done)->
    command= ''
    command+= ' cover '+(require.resolve 'mocha/bin/_mocha')

    command+= ' --default-excludes ""'

    command+= ' -- '
    command+= ' test/fixture/issue11.coffee '
    command+= ' --reporter spec'
    command+= ' --recursive test'

    $ibrik command
    .then (stdout)->
      expect(stdout).to.match /Coverage summary/
      done()