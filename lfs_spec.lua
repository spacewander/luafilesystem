local vanilla_lfs = require('lfs')
local lfs = require('./lfs_ffi')


local eq = assert.are.same
local is_nil = assert.is_nil
local is_not_nil = assert.is_not_nil
local is_true = assert.is_true
local has_error = assert.has_error

describe('lfs', function()
    describe('attributes', function()
        it('without argument', function()
            local info = lfs.attributes('.')
            eq(vanilla_lfs.attributes('.'), info)
        end)

        it('with attribute name', function()
            local names = {
                'access',
                'blksize',
                'blocks',
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
            for i = 1, #names do
                local attr = names[i]
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
            eq('No such file or directory', err)
        end)
    end)

    describe('symlinkattributes', function()
        local symlink = 'lfs_ffi.lua.link'

        it('link failed', function()
            local res, err = lfs.link('xxx', symlink)
            is_nil(res)
            eq(err, 'No such file or directory')
        end)

        it('hard link', function()
            local _, err = lfs.link('lfs_ffi.lua', symlink)
            is_nil(err)
            eq(vanilla_lfs.attributes(symlink, 'mode'), 'file')
            eq(vanilla_lfs.symlinkattributes(symlink, 'mode'), 'file')
        end)

        it('soft link', function()
            local _, err = lfs.link('lfs_ffi.lua', symlink, true)
            is_nil(err)
            eq(vanilla_lfs.attributes(symlink, 'mode'), 'file')
            eq(vanilla_lfs.symlinkattributes(symlink, 'mode'), 'link')
        end)

        after_each(function()
            os.remove(symlink)
        end)
    end)

    describe('dir', function()
        it('mkdir', function()
            lfs.mkdir('test')
        end)

        it('return err if mkdir failed', function()
            local res, err = lfs.mkdir('test')
            is_nil(res)
            eq('File exists', err)
        end)

        it('raise error if open dir failed', function()
            has_error(function() lfs.dir('nonexisted') end,
                "cannot open nonexisted : No such file or directory")
        end)

        it('iterate dir', function()
            local _, dir_obj = lfs.dir('test')
            local names = {}
            while true do
                local name = dir_obj:next()
                if not name then break end
                names[#names + 1] = name
            end
            eq({'..', '.'}, names)
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
            eq({'..', '.'}, names)
            is_true(dir_obj.closed)
        end)

        it('close', function()
            local _, dir_obj = lfs.dir('.')
            dir_obj:close()
            has_error(function() dir_obj:next() end, "closed directory")
        end)

        it('chdir and currentdir', function()
            lfs.chdir('test')
            local cur_dir = lfs.currentdir()
            lfs.chdir('..')
            is_not_nil(cur_dir:find('test$'))
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

    describe('touch', function()
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
end)
