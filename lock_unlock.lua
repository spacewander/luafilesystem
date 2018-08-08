#!/usr/bin/env lua
local lfs = require('./lfs_ffi')

local fh = io.open('temp.txt', 'r+')

local start = os.clock()
while true do
    local ok = lfs.lock(fh, 'w', 2, 7)
    if ok then
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
local _, err = lfs.unlock(fh)
print(err)
