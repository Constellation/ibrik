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
    "__cov_#{suffix}"

# TODO(Constellation)
# fix CoffeeScriptRedux compiler
# https://github.com/michaelficarra/CoffeeScriptRedux/issues/117
removeIndent = (code) ->
    code.replace /[\uEFEF\uEFFE\uEFFF]/g, ''

calculateColumn = (raw, offset) ->
    code = raw[...offset]
    lines = code.split /(?:\n|\r|[\r\n])/g
    (removeIndent lines[lines.length - 1]).length

class Instrumenter extends istanbul.Instrumenter
    constructor: (opt) ->
        istanbul.Instrumenter.call this, opt

    instrumentSync: (code, filename) ->
        filename = filename or "#{Date.now()}.js"
        @coverState =
            path: filename
            s: {}
            b: {}
            f: {}
            fnMap: {}
            statementMap: {}
            branchMap: {}

        @currentState =
            trackerVar: generateTrackerVar filename, @omitTrackerSuffix
            func: 0
            branch: 0
            variable: 0
            statement: 0

        throw new Error 'Code must be string' unless typeof code is 'string'

        csast = coffee.parse code, optimise: no, raw: yes
        program = coffee.compile csast, bare: yes
        @attachLocation program

        @walker.startWalk program
        codegenOptions = @opts.codeGenerationOptions or format: compact: not this.opts.noCompact
        "#{@getPreamble code}\n#{escodegen.generate program, codegenOptions}\n"

    attachLocation: (program)->
        # TODO(Constellation)
        # calculate precise offset or attach in
        # CoffeeScriptRedux compiler
        estraverse.traverse program,
            leave: (node, parent) ->
                if node.offset? and (node.raw? or node.value?)
                    value =
                        if node.raw?
                            node.raw
                        else if typeof node.value is 'string'
                            "\"#{node.value.replace /"/g, '\\"'}\""
                        else
                            "#{node.value}"

                    # calculate start line & column
                    node.loc =
                        start:
                            line: node.line
                            column: calculateColumn program.raw, node.offset
                        end:
                            line: node.line
                            column: 0
                    node.loc.end.column = node.loc.start.column + value.length
                    lines = value.split /(?:\n|\r|[\r\n])/g
                    unless lines.length in [0, 1]
                        node.loc.end.line += lines.length - 1
                        node.loc.end.column = removeIndent(lines[lines.length - 1]).length
                else
                    node.loc = switch node.type
                        when 'BlockStatement'
                            start: node.body[0].loc.start
                            end: node.body[node.body.length - 1].loc.end
                        when 'VariableDeclarator'
                            if node?.init?.loc?
                                start: node.id.loc.start
                                end: node.init.loc.end
                            else
                                node.id.loc
                        when 'ExpressionStatement'
                            node.expression.loc
                        when 'ReturnStatement'
                            if node.argument? then node.argument.loc else node.loc
                        when 'VariableDeclaration'
                            start: node.declarations[0].loc.start
                            end: node.declarations[node.declarations.length - 1].loc.end
                        else
                            start: {line: 0, column: 0}
                            end: {line: 0, column: 0}
                return

module.exports = Instrumenter

# vim: set sw=4 ts=4 et tw=80 :
