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
semver = require 'semver'

ignoreString = '/* istanbul ignore next: coffeescript utility boilerplate */'

utilities =
    extends:
        '1.8.0':
            original: '__extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; }'
            replacement: "__extends = function(child, parent) { for (var key in parent) { #{ignoreString} if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; }"
        '1.9.0':
            original: 'extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; }'
            replacement: "extend = function(child, parent) { for (var key in parent) { #{ignoreString} if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; }"
        '1.10.0':
            original: 'extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; }'
            replacement: "extend = function(child, parent) { for (var key in parent) { #{ignoreString} if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; }"

    indexOf:
        '1.8.0':
            original: '__indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; }'
            replacement: "__indexOf = #{ignoreString} [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { #{ignoreString} if (i in this && this[i] === item) return i; } return -1; }"
        '1.9.0':
            original: 'indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; }'
            replacement: "indexOf = #{ignoreString} [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { #{ignoreString} if (i in this && this[i] === item) return i; } return -1; }"
        '1.10.0':
            original: 'indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; }'
            replacement: "indexOf = #{ignoreString} [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { #{ignoreString} if (i in this && this[i] === item) return i; } return -1; }"

clean = (compiledJS) ->
    switch semver.minor coffee.VERSION
        when 8 then version = '1.8.0'
        when 9 then version = '1.9.0'
        when 10 then version = '1.10.0'
        else return compiledJS

    newCompiledJS = compiledJS

    for utilityKey, utilityVersions of utilities when utility = utilityVersions[version]
        newCompiledJS = newCompiledJS.replace utility.original, utility.replacement

    return newCompiledJS

module.exports = clean
# vim: set sw=4 ts=4 et tw=80 :
