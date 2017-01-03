#!/usr/bin/env lua

local file = io.open('temp.txt', 'w')
file:write('0123456789')
file:close()

io.popen('lua lock_unlock.lua')
os.execute('lua lock_unlock.lua')

os.remove('temp.txt')
