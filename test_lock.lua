#!/usr/bin/env luajit

local file = io.open('temp.txt', 'w')
file:write('0123456789')
file:close()

io.popen('luajit lock_unlock.lua')
os.execute('luajit lock_unlock.lua')

os.remove('temp.txt')
