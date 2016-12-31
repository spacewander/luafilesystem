#!/usr/bin/env luajit
local lfs = require('./lfs_ffi')

local start = os.clock()
local lock
while true do
    lock = lfs.lock('lfs_ffi.lua', 'w')
    if lock then
        print('get lock')
        break
    end
    if os.clock() - start > 5 then
        print('ERROR: timeout')
        return
    end
end

start = os.clock()
while os.clock() - start < 3  do
end

print('unlock')
local _, err = lfs.unlock(lock)
print(err)
