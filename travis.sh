#!/usr/bin/env bash


./test_lock.lua > /tmp/lfs
grep 'ERROR' /tmp/lfs && exit 1
if [ "$(uname)" = "Linux" ]; then
    sudo apt-get install valgrind
    valgrind --error-exitcode=42 --tool=memcheck \
        --gen-suppressions=all --suppressions=valgrind.suppress \
        luajit test_valgrind.lua .
fi
