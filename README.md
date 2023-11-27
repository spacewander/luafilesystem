# luafilesystem

[![Build Status](https://travis-ci.org/spacewander/luafilesystem.svg?branch=master)](https://travis-ci.org/spacewander/luafilesystem)
[![Build status](https://ci.appveyor.com/api/projects/status/52d2x1frvksf4u1h/branch/master?svg=true)](https://ci.appveyor.com/project/spacewander/luafilesystem/branch/master)


Reimplement luafilesystem via LuaJIT FFI.

## Docs

It should be compatible with vanilla luafilesystem but with unicode paths in windows:
http://keplerproject.github.io/luafilesystem/manual.html#reference

What you only need is replacing `require('lfs')` to `require('lfs_ffi')`.`

On windows `lfs.dir` iterator will provide an extra return that can be used to get `mode` and `size` attributes in a much more performant way.

This is the canonical way to iterate:

```Lua
    local sep = "/"
    for file,obj in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..sep..file
            -- obj wont be nil in windows only
            local attr = obj and obj:attr() or lfs.attributes (f)
            assert (type(attr) == "table",f)
            -- do something with f and attr
        end
    end
```

## Installation

````
cmake -DLUAJIT_DIR="path to luajit" ../luafilesystem
make install
````

or just copy `lfs_ffi.lua` to lua folder
