#  Copyright (C) 2012-2014 Yusuke Suzuki <utatane.tea@gmail.com>
#  Copyright (C) 2013-2014 Jeff Stamerjohn <jstamerj@gmail.com>
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

coffee = require 'coffee-script'
istanbul = require 'istanbul'
estraverse = require 'estraverse'
_ = require 'lodash'
esprima = require 'esprima'
path = require 'path'
fs = require 'fs'
clean = require './clean'

# Use ECMAScript 5.1th indirect call to eval instead of direct eval call.
globalEval = (source) ->
    geval = eval
    return geval source

class Instrumenter extends istanbul.Instrumenter
    constructor: (opt) ->
        istanbul.Instrumenter.call this, opt

    instrumentSync: (code, filename) ->
        filename = filename or "#{Date.now()}.js"

        throw new Error 'Code must be string' unless typeof code is 'string'

        try
            code = coffee.compile code, sourceMap: true
            code.js = clean code.js
            program = esprima.parse(code.js, {
                loc: true
                range: true
                raw: true
                tokens: true
                comment: true
            })
            @fixupLoc program, code.sourceMap
            @instrumentASTSync program, filename, code
        catch e
            e.message = "Error compiling #{filename}: #{e.message}"
            throw e

    # Used to ensure that a module is included in the code coverage report
    # (even if it is not loaded during the test)
    include: (filename) ->
        filename = path.resolve(filename)
        code = fs.readFileSync(filename, 'utf8')
        @instrumentSync(code, filename)

        # Setup istanbul's references for this module
        globalEval("#{@getPreamble null}")

        return

    fixupLoc: (program, sourceMap) ->
        estraverse.traverse program,
            leave: (node, parent) ->
                mappedLocation = (location) ->
                    locArray = sourceMap.sourceLocation([
                        location.line - 1
                        location.column
                    ])
                    line = 0
                    column = 0
                    if locArray
                        line = locArray[0] + 1
                        column = locArray[1]
                    return { line: line, column: column }

                if node.loc?.start
                    node.loc.start = mappedLocation(node.loc.start)
                if node.loc?.end
                    node.loc.end = mappedLocation(node.loc.end)
                return

module.exports = Instrumenter

# vim: set sw=4 ts=4 et tw=80 :
