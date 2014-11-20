#  Copyright (C) 2014 Yusuke Suzuki <utatane.tea@gmail.com>
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
#  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
#  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

'use strict'

fs = require 'fs'
expect = require('chai').expect
Promise = require('bluebird')
PromisedFS = require('promised-io/fs')
child_process = require 'child_process'
path = require 'path'

adjustPath = (coverage) ->
    result = {}
    for key, value of coverage
        result[path.relative('.', key)] = value
        value.path = path.relative('.', value.path)
    return result

generateCoverage = (file) ->
    new Promise (resolve, reject) ->
        proc = child_process.spawn 'node', [
            'bin/ibrik'
            'cover'
            file
            '--dir'
            "tmp/#{file}"
            '--no-default-excludes'
            '--self-test'
        ]
        proc.stdout.on 'data', (data) -> process.stdout.write(data)
        proc.stderr.on 'data', (data) -> process.stdout.write(data)
        proc.on 'exit', (code) ->
            return reject code if code

            resolve(Promise.all([
                # actual
                PromisedFS.readFile("tmp/#{file}/coverage.json", 'utf-8')
                .then((text) ->
                    # Adjust absolute path in coverage.json file.
                    adjustPath JSON.parse text
                ),
                # expected
                PromisedFS.readFile("#{file}.json", 'utf-8')
                .then((text) ->
                    # Expected file should not contain absolute path.
                    return JSON.parse text
                )
            ]))

coverTest = (file) ->
    generateCoverage(file).then ([actual, expected]) ->
        expect(expected).to.deep.equal actual
        return null

describe 'coverage', ->
    it 'simple#1', (done) ->
        coverTest('test/fixture/test001.coffee').then(done, done)

    it 'simple#2', (done) ->
        coverTest('test/fixture/test002.coffee').then(done, done)

    it 'require#1', (done) ->
        coverTest('test/fixture/test003.coffee').then(done, done)

    it 'complicated', (done) ->
        coverTest('test/fixture/third_party/StringScannerWithTest.coffee').then(done, done)

