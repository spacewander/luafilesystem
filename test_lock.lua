#!/usr/bin/env luajit

io.popen('luajit lock_unlock.lua')
os.execute('luajit lock_unlock.lua')
