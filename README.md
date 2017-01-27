# luafilesystem

[![Build Status](https://travis-ci.org/spacewander/luafilesystem.svg?branch=master)](https://travis-ci.org/spacewander/luafilesystem)
[![Build status](https://ci.appveyor.com/api/projects/status/52d2x1frvksf4u1h/branch/master?svg=true)](https://ci.appveyor.com/project/spacewander/luafilesystem/branch/master)


Reimplement luafilesystem via LuaJIT FFI.

## Docs

It should be compatible with vanilla luafilesystem:
http://keplerproject.github.io/luafilesystem/manual.html#reference

What you only need is replacing `require('lfs')` to `require('lfs_ffi')`.`

## Installation

`[sudo] opm get spacewander/luafilesystem`

Run `resty -e "lfs = require('lfs_ffi') print(lfs.attributes('.', 'mode'))"` to validate the installation.
