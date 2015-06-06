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
#
#  Based on istanbul command code
#  Copyright (c) 2012, Yahoo! Inc.  All rights reserved.
#  Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.

Module = require 'module'
fs = require 'fs'
path = require 'path'
ibrik = require './ibrik'
istanbul = require 'istanbul'
mkdirp = require 'mkdirp'
which = require 'which'
fileset = require 'fileset'

existsSync = fs.existsSync or path.existsSync

DEFAULT_REPORT_FORMAT = 'lcov'

module.exports = (opts, callback) ->
    [cmd, file, args...] = opts._

    return callback "Need a filename argument for the #{cmd} command!" unless file

    if not existsSync file
        try file = which.sync file
        catch e
            return callback "Unable to resolve file [#{file}]"
    else
        file = path.resolve file

    excludes = []
    if not opts['default-excludes']? or opts['default-excludes']
        excludes = ['**/node_modules/**', '**/test/**', '**/tests/**']

    reportingDir = '' + (opts.dir or path.resolve process.cwd(), 'coverage')

    mkdirp.sync reportingDir

    reportClassNames = opts.report or DEFAULT_REPORT_FORMAT
    reports =
        if Array.isArray reportClassNames
            reportClassNames.map (reportClassName) -> istanbul.Report.create(reportClassName, dir: reportingDir)
        else
            [ istanbul.Report.create(reportClassNames, dir: reportingDir) ]

    runFn = ->
        process.argv = ['node', file, args...]
        console.log "Running: #{process.argv.join ' '}" if opts.verbose
        process.env.running_under_istanbul = 1
        Module.runMain file, null, true

    unless opts.print is 'none'
        switch opts.print
            when 'detail' then reports.push istanbul.Report.create 'text'
            when 'both'
                reports.push istanbul.Report.create 'text'
                reports.push istanbul.Report.create 'text-summary'
            else
                reports.push istanbul.Report.create 'text-summary'

    istanbul.matcherFor {
        root: opts.root or process.cwd()
        includes: ['**/*.coffee']
        excludes
    }, (err, matchFn) ->
        return callback(err, null) if err

        coverageVar = "$$cov_#{Date.now()}$$"
        instrumenter = new ibrik.Instrumenter coverageVariable: coverageVar
        transformer = instrumenter.instrumentSync.bind(instrumenter)
        hookOpts = verbose: opts.verbose

        ibrik.hook.unloadRequireCache matchFn if opts['self-test']

        ibrik.hook.hookRequire matchFn, transformer, hookOpts

        process.once 'exit', (exitCode)->
            file = path.resolve reportingDir, 'coverage.json'
            if not global[coverageVar]?
                return callback('No coverage information was collected, exit without writing coverage information', null, exitCode)
            else
                cov = global[coverageVar]

            mkdirp.sync reportingDir
            console.log '============================================================================='
            console.log "Writing coverage object [#{file}]"
            fs.writeFileSync file, (JSON.stringify cov), 'utf8' unless opts.headless
            collector = new istanbul.Collector
            collector.add cov
            console.log "Writing coverage reports at [#{reportingDir}]"
            console.log '============================================================================='
            report.writeReport collector, yes for report in reports
            return callback(null, cov, exitCode)

        if opts?.files?.include
            if typeof opts.files.include is 'string'
                # Handle single value case
                opts.files.include = [opts.files.include]
            fileset opts.files.include.join(' '), excludes.join(' '), (err, files) ->
                if err
                    console.error 'Error including files: ', err
                else
                    instrumenter.include(filename) for filename in files
                    do runFn
        else
            do runFn

# vim: set sw=4 ts=4 et tw=80 :
