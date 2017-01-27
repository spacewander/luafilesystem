#!/usr/bin/env bash


./test_lock.lua > /tmp/lfs
grep 'ERROR' /tmp/lfs && exit 1
if [ "$(uname)" = "Linux" ]; then
    sudo apt-get install valgrind
    LUA=luajit
    test -z "$(which $LUA)" && LUA=$PWD/lua_install/bin/lua
    valgrind --error-exitcode=42 --tool=memcheck \
        --gen-suppressions=all --suppressions=valgrind.suppress \
        "$LUA" test_valgrind.lua .
fi
