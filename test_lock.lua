#!/usr/bin/env lua

io.popen('lua lock_unlock.lua')
os.execute('lua lock_unlock.lua')
