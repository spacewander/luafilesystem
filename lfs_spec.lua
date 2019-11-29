local ffi = require('ffi')
local vanilla_lfs = require('lfs')
local lfs = require('./lfs_ffi')


local eq = assert.are.same
local is_nil = assert.is_nil
local is_not_nil = assert.is_not_nil
local is_true = assert.is_true
local has_error = assert.has_error
local posix = ffi.os ~= 'Windows'
local linux = ffi.os == 'Linux'

local attr_names = {
    'access',
    'change',
    'dev',
    'gid',
    'ino',
    'mode',
    'modification',
    'nlink',
    'permissions',
    'rdev',
    'size',
    'uid'
}
if posix then
    local extra_attrs = {'blksize', 'blocks'}
    for i = 1, #extra_attrs do
        table.insert(attr_names, extra_attrs[i])
    end
end

describe('lfs', function()
    describe('#attributes', function()
        it('without argument', function()
            local info = lfs.attributes('.')
            eq(vanilla_lfs.attributes('.'), info)
        end)

        it('with attribute name', function()
            for i = 1, #attr_names do
                local attr = attr_names[i]
                local info = lfs.attributes('.', attr)
                eq(vanilla_lfs.attributes('.', attr), info,
                   attr..' is not equal')
            end
        end)

        it('with attributes table', function()
            local tab = {"table", "for", "attributes"}
            local info = lfs.attributes('.', tab)
            eq(vanilla_lfs.attributes('.', tab), info)
        end)

        it('with nonexisted file', function()
            local info, err = lfs.attributes('nonexisted')
            is_nil(info)
            eq("cannot obtain information from file 'nonexisted' : No such file or directory", err)
        end)

        it('with nonexisted attribute', function()
            has_error(function() lfs.attributes('.', 'nonexisted') end,
                "invalid attribute name 'nonexisted'")
            if not posix then
                has_error(function() lfs.attributes('.', 'blocks') end,
                    "invalid attribute name 'blocks'")
            end
        end)
    end)

    describe('#symlinkattributes', function()
        local symlink = 'lfs_ffi.lua.link'

        it('link failed', function()
            if posix then
                local res, err = lfs.link('xxx', symlink)
                is_nil(res)
                eq(err, 'No such file or directory')
            end
        end)

        it('hard link', function()
            local _, err = lfs.link('lfs_ffi.lua', symlink)
            is_nil(err)
            eq(vanilla_lfs.attributes(symlink, 'mode'), 'file')
            eq(vanilla_lfs.symlinkattributes(symlink, 'mode'), 'file')
        end)

        it('soft link', function()
            if posix then
                local _, err = lfs.link('lfs_ffi.lua', symlink, true)
                is_nil(err)
                eq(vanilla_lfs.attributes(symlink, 'mode'), 'file')
                eq(vanilla_lfs.symlinkattributes(symlink, 'mode'), 'link')
            end
        end)

        it('without argument', function()
            lfs.link('lfs_ffi.lua', symlink, true)
            local info = lfs.symlinkattributes(symlink)
            local expected_info = vanilla_lfs.symlinkattributes(symlink)
            for k, v in pairs(expected_info) do
                eq(v, info[k], k..'is not equal')
            end
        end)

        it('with attribute name', function()
            lfs.link('lfs_ffi.lua', symlink, true)
            for i = 1, #attr_names do
                local attr = attr_names[i]
                local info = lfs.symlinkattributes(symlink, attr)
                eq(vanilla_lfs.symlinkattributes(symlink, attr), info,
                   attr..' is not equal')
            end
        end)

        it('add target field', function()
            if posix then
                lfs.link('lfs_ffi.lua', symlink, true)
                eq('lfs_ffi.lua', lfs.symlinkattributes(symlink, 'target'))
                eq('lfs_ffi.lua', lfs.symlinkattributes(symlink).target)
            end
        end)

        it('link with pseudo file', function()
            if linux then
                local pseudo_filename =  '/proc/self'
                lfs.link(pseudo_filename, symlink, true)
                eq(pseudo_filename, lfs.symlinkattributes(symlink, 'target'))
                eq(pseudo_filename, lfs.symlinkattributes(symlink).target)
            end
        end)

        after_each(function()
            os.remove(symlink)
        end)
    end)

    describe('#setmode', function()
        local fh
        before_each(function()
            fh = io.open('lfs_ffi.lua')
        end)

        it('setmode', function()
            local ok, mode = lfs.setmode(fh, 'binary')
            is_true(ok)
            if posix then
                -- On posix platform, always return 'binary'
                eq('binary', mode)
            else
                eq( 'text', mode)
                local _
                _, mode = lfs.setmode(fh, 'text')
                eq('binary', mode)
            end
        end)

        if not posix then
            it('setmode incorrect mode', function()
                has_error(function() lfs.setmode(fh, 'bin') end, 'setmode: invalid mode')
            end)

            it('setmode incorrect file', function()
                has_error(function() lfs.setmode('file', 'binary') end, 'setmode: invalid file')
            end)
        end
    end)

    describe('#dir', function()
        it('mkdir', function()
            lfs.mkdir('test')
        end)

        it('return err if mkdir failed', function()
            local res, err = lfs.mkdir('test')
            is_nil(res)
            eq('File exists', err)
        end)

        it('raise error if open dir failed', function()
            if posix then
                has_error(function() lfs.dir('nonexisted') end,
                    "cannot open nonexisted : No such file or directory")
            else
                -- Like vanilla lfs, we only check path's length in Windows
                local ok, msg = pcall(function() lfs.dir(('12345'):rep(64)) end)
                is_true(not ok)
                is_not_nil(msg:find('path too long'))
            end
        end)

        if posix or os.getenv('CI') ~= 'True' then
            it('iterate dir', function()
                local _, dir_obj = lfs.dir('test')
                local names = {}
                while true do
                    local name = dir_obj:next()
                    if not name then break end
                    names[#names + 1] = name
                end
                table.sort(names)
                eq({'.', '..'}, names)
                is_true(dir_obj.closed)
            end)

            it('iterate dir via iterator', function()
                local iter, dir_obj = lfs.dir('test')
                local names = {}
                while true do
                    local name = iter(dir_obj)
                    if not name then break end
                    names[#names + 1] = name
                end
                table.sort(names)
                eq({'.', '..'}, names)
                is_true(dir_obj.closed)
            end)
        end

        it('close', function()
            local _, dir_obj = lfs.dir('.')
            dir_obj:close()
            has_error(function() dir_obj:next() end, "closed directory")
        end)

        it('chdir and currentdir', function()
            lfs.chdir('test')
            local cur_dir = lfs.currentdir()
            lfs.chdir('..')
            assert.is_not_nil(cur_dir:find('test$'))
        end)

        it('return err if chdir failed', function()
            local res, err = lfs.chdir('nonexisted')
            is_nil(res)
            eq('No such file or directory', err)
        end)

        it('rmdir', function()
            lfs.rmdir('test')
        end)

        it('return err if rmdir failed', function()
            local res, err = lfs.rmdir('test')
            is_nil(res)
            eq('No such file or directory', err)
        end)
    end)

    describe('#touch', function()
        local touched = 'temp'

        before_each(function()
            local f = io.open(touched, 'w')
            f:write('a')
            f:close()
        end)

        after_each(function()
            os.remove(touched)
        end)

        it('touch failed', function()
            local _, err = lfs.touch('nonexisted', 1)
            eq('No such file or directory', err)
        end)

        it('set atime', function()
            local _, err = lfs.touch(touched, 1)
            is_nil(err)
            eq(vanilla_lfs.attributes(touched, 'access'), 1)
        end)

        it('set both atime and mtime', function()
            local _, err = lfs.touch(touched, 1, 2)
            is_nil(err)
            eq(vanilla_lfs.attributes(touched, 'access'), 1)
            eq(vanilla_lfs.attributes(touched, 'modification'), 2)
        end)
    end)

    -- Just smoke testing
    describe('#lock', function()
        local fh
        setup(function()
            fh = io.open('temp.txt', 'w')
            fh:write('1234567890')
            fh:close()
        end)

        before_each(function()
            fh = io.open('temp.txt', 'r+')
        end)

        it('lock', function()
            local _, err = lfs.lock(fh, 'r', 2, 8)
            is_nil(err)
        end)

        it('lock exclusively', function()
            if posix then
                local _, err = lfs.lock(fh, 'w')
                is_nil(err)
            end
        end)

        it('lock: invalid mode', function()
            has_error(function() lfs.lock('temp.txt', 'u') end, 'lock: invalid mode')
        end)

        it('lock: invalid file', function()
            has_error(function() lfs.lock('temp.txt', 'w') end, 'lock: invalid file')
        end)

        it('unlock', function()
            local _, err = lfs.lock(fh, 'w', 4, 9)
            is_nil(err)
            if posix then
                _, err = lfs.unlock(fh, 3, 11)
                is_nil(err)
            else
                _, err = lfs.unlock(fh, 3, 11)
                eq('Permission denied', err)
                _, err = lfs.unlock(fh, 4, 9)
                is_nil(err)
            end
        end)

        it('unlock: invalid file', function()
            has_error(function() lfs.unlock('temp.txt') end, 'unlock: invalid file')
        end)

        after_each(function()
            fh:close()
        end)

        teardown(function()
            os.remove('temp.txt')
        end)
    end)

    describe('#lock_dir', function()
        it('lock_dir', function()
            local lock, err, _
            lock, err = lfs.lock_dir('.')
            is_nil(err)
            lock:free()
            -- lock again after unlock
            _, err = lfs.lock_dir('.')
            is_nil(err)
            -- lock again without unlock
            _, err = lfs.lock_dir('.')
            is_not_nil(err)
        end)
    end)
end)
