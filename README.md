# luafilesystem

[![Build Status](https://travis-ci.org/spacewander/luafilesystem.svg?branch=master)](https://travis-ci.org/spacewander/luafilesystem)

Reimplement luafilesystem via LuaJIT FFI.

This project doesn't support Windows. If you need the Windows support, use
https://github.com/sonoro1234/luafilesystem instead.

## Docs

It should be compatible with vanilla luafilesystem:
http://keplerproject.github.io/luafilesystem/manual.html#reference

What you only need is replacing `require('lfs')` to `require('lfs_ffi')`.`

## Installation

`[sudo] opm get spacewander/luafilesystem`

Run `resty -e "lfs = require('lfs_ffi') print(lfs.attributes('.', 'mode'))"` to validate the installation.
