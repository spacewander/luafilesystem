local vanilla_lfs = require('lfs')
local lfs = require('./lfs_ffi')


describe('lfs', function()
    describe('attributes', function()
        it('without argument', function()
            local info = lfs.attributes('.')
            assert.are.same(vanilla_lfs.attributes('.'), info)
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
                assert.are.same(
                    vanilla_lfs.attributes('.', attr), info, attr..' is not equal')
            end
        end)

        it('with attributes table', function()
            local tab = {"table", "for", "attributes"}
            local info = lfs.attributes('.', tab)
            assert.are.same(vanilla_lfs.attributes('.', tab), info)
        end)

        it('with nonexisted file', function()
            local info, err = lfs.attributes('nonexisted')
            assert.is_nil(info)
            assert.are.same('No such file or directory', err)
        end)
    end)

    describe('dir', function()
        it('mkdir', function()
            lfs.mkdir('test')
        end)

        it('return err if mkdir failed', function()
            local res, err = lfs.mkdir('test')
            assert.is_nil(res)
            assert.are.same('File exists', err)
        end)

        it('raise error if open dir failed', function()
            assert.has_error(function() lfs.dir('nonexisted') end,
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
            assert.are.same({'..', '.'}, names)
            assert.is_true(dir_obj.closed)
        end)

        it('iterate dir via iterator', function()
            local iter, dir_obj = lfs.dir('test')
            local names = {}
            while true do
                local name = iter(dir_obj)
                if not name then break end
                names[#names + 1] = name
            end
            assert.are.same({'..', '.'}, names)
            assert.is_true(dir_obj.closed)
        end)

        it('close', function()
            local _, dir_obj = lfs.dir('.')
            dir_obj:close()
            assert.has_error(function() dir_obj:next() end, "closed directory")
        end)

        it('chdir and currentdir', function()
            lfs.chdir('test')
            local cur_dir = lfs.currentdir()
            lfs.chdir('..')
            assert.is_not_nil(cur_dir:find('test$'))
        end)

        it('return err if chdir failed', function()
            local res, err = lfs.chdir('nonexisted')
            assert.is_nil(res)
            assert.are.same('No such file or directory', err)
        end)

        it('rmdir', function()
            lfs.rmdir('test')
        end)

        it('return err if rmdir failed', function()
            local res, err = lfs.rmdir('test')
            assert.is_nil(res)
            assert.are.same('No such file or directory', err)
        end)
    end)
end)
