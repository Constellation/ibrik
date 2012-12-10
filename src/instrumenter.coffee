#  Copyright (C) 2012 Yusuke Suzuki <utatane.tea@gmail.com>
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

coffee = require 'CoffeeScriptRedux'
istanbul = require 'istanbul'
crypto = require 'crypto'
escodegen = require 'escodegen'
estraverse = require 'estraverse'

generateTrackerVar = (filename, omitSuffix) ->
    if omitSuffix
        return '__cov_'
    hash = crypto.createHash 'md5'
    hash.update filename
    suffix = hash.digest 'base64'
    suffix = suffix.replace(/\=/g, '').replace(/\+/g, '_').replace(/\//g, '$')
    '__cov_' + suffix

class Instrumenter extends istanbul.Instrumenter
    constructor: (opt) -> istanbul.Instrumenter.call(this, opt)

    instrumentSync: (code, filename) ->
        filename = filename || Date.now() + '.js'
        @coverState =
            path: filename
            s: {}
            b: {}
            f: {}
            fnMap: {}
            statementMap: {}
            branchMap: {}

        @currentState =
            trackerVar: generateTrackerVar(filename, @omitTrackerSuffix)
            func: 0
            branch: 0
            variable: 0
            statement: 0

        throw new Error 'Code must be string' if typeof code isnt 'string'

        code = '//' + code if code[0] is '#'

        csast = coffee.parse code, optimise:no
        program = coffee.compile csast, bare:yes
        @attachLocation program

        @walker.startWalk program
        codegenOptions = @opts.codeGenerationOptions || { format: { compact: !this.opts.noCompact }}
        @getPreamble(code) + '\n' + escodegen.generate(program, codegenOptions) + '\n'

    attachLocation: (tree)->
        estraverse.traverse tree,
            enter: (node, parent) ->
                if node.column? and node.line? and node.raw?
                    # TODO(Constellation)
                    # calculate precise offset or attach in
                    # CoffeeScriptRedux compiler
                    node.loc =
                        start: { line: node.line, column: node.column },
                        end: { line: node.line, column: node.column + node.raw.length }
                    lines = node.raw.split(/(?:\n|\r|[\r\n])/)
                    if lines.length isnt 0 and lines.length isnt 1
                        node.loc.end.line += lines.lines
                        node.loc.end.column = lines[lines.length - 1].length

module.exports = Instrumenter
# vim: set sw=4 ts=4 et tw=80 :
