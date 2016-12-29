local bit = require "bit"
local ffi = require "ffi"


local band = bit.band
local rshift = bit.rshift
local lib = ffi.C
local ffi_str = ffi.string
local concat = table.concat
local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function () return {} end
end


local _M = {
    _VERSION = "0.1",
}

local IS_64_BIT = ffi.abi('64bit')

ffi.cdef([[
    char* strerror(int errnum);
]])

local function errno()
    return ffi_str(lib.strerror(ffi.errno()))
end

local OS = ffi.os
if OS == "Windows" then
    error("TODO support Windows")
else
    local MAXPATH = 4096

    ffi.cdef([[
        char *getcwd(char *buf, size_t size);
        int chdir(const char *path);
        int rmdir(const char *pathname);
        typedef unsigned int mode_t;
        int mkdir(const char *pathname, mode_t mode);
        typedef uint64_t time_t;
        struct utimebuf {
            time_t actime;
            time_t modtime;
        };
        int utime(const char *file, const struct utimebuf *times);

        int link(const char *oldpath, const char *newpath);
        int symlink(const char *oldpath, const char *newpath);

        typedef struct  __dirstream DIR;

        typedef size_t off_t;
        typedef int64_t ino_t;

        struct dirent {
            ino_t           d_ino;
            off_t           d_off;
            unsigned short  d_reclen;
            unsigned char   d_type;
            char            d_name[256];
        };

        DIR *opendir(const char *name);
        struct dirent *readdir(DIR *dirp);
        int closedir(DIR *dirp);
        long syscall(int number, ...);
    ]])

    local stat_func
    if OS == 'Linux' then
        local ARCH = ffi.arch
        -- Taken from justincormack/ljsyscall
        local stat_syscall_num
        if ARCH == 'x64' then
            ffi.cdef([[
                struct stat {
                    unsigned long   st_dev;
                    unsigned long   st_ino;
                    unsigned long   st_nlink;
                    unsigned int    st_mode;
                    unsigned int    st_uid;
                    unsigned int    st_gid;
                    unsigned int    __pad0;
                    unsigned long   st_rdev;
                    long            st_size;
                    long            st_blksize;
                    long            st_blocks;
                    unsigned long   st_atime;
                    unsigned long   st_atime_nsec;
                    unsigned long   st_mtime;
                    unsigned long   st_mtime_nsec;
                    unsigned long   st_ctime;
                    unsigned long   st_ctime_nsec;
                    long            __unused[3];
                };
            ]])
            stat_syscall_num = 4
        elseif ARCH == 'x86' then
            ffi.cdef([[
                struct stat {
                    unsigned long long      st_dev;
                    unsigned char   __pad0[4];
                    unsigned long   __st_ino;
                    unsigned int    st_mode;
                    unsigned int    st_nlink;
                    unsigned long   st_uid;
                    unsigned long   st_gid;
                    unsigned long long      st_rdev;
                    unsigned char   __pad3[4];
                    long long       st_size;
                    unsigned long   st_blksize;
                    unsigned long long      st_blocks;
                    unsigned long   st_atime;
                    unsigned long   st_atime_nsec;
                    unsigned long   st_mtime;
                    unsigned int    st_mtime_nsec;
                    unsigned long   st_ctime;
                    unsigned long   st_ctime_nsec;
                    unsigned long long      st_ino;
                };
            ]])
            stat_syscall_num = IS_64_BIT and 106 or 195
        elseif ARCH == 'arm' then
            if IS_64_BIT then
                ffi.cdef([[
                    struct stat {
                        unsigned long   st_dev;
                        unsigned long   st_ino;
                        unsigned int    st_mode;
                        unsigned int    st_nlink;
                        unsigned int    st_uid;
                        unsigned int    st_gid;
                        unsigned long   st_rdev;
                        unsigned long   __pad1;
                        long            st_size;
                        int             st_blksize;
                        int             __pad2;
                        long            st_blocks;
                        long            st_atime;
                        unsigned long   st_atime_nsec;
                        long            st_mtime;
                        unsigned long   st_mtime_nsec;
                        long            st_ctime;
                        unsigned long   st_ctime_nsec;
                        unsigned int    __unused4;
                        unsigned int    __unused5;
                    };
                ]])
                stat_syscall_num = 106
            else
                ffi.cdef([[
                    struct stat {
                        unsigned long long      st_dev;
                        unsigned char   __pad0[4];
                        unsigned long   __st_ino;
                        unsigned int    st_mode;
                        unsigned int    st_nlink;
                        unsigned long   st_uid;
                        unsigned long   st_gid;
                        unsigned long long      st_rdev;
                        unsigned char   __pad3[4];
                        long long       st_size;
                        unsigned long   st_blksize;
                        unsigned long long      st_blocks;
                        unsigned long   st_atime;
                        unsigned long   st_atime_nsec;
                        unsigned long   st_mtime;
                        unsigned int    st_mtime_nsec;
                        unsigned long   st_ctime;
                        unsigned long   st_ctime_nsec;
                        unsigned long long      st_ino;
                    };
                ]])
                stat_syscall_num = 195
            end
        elseif ARCH == 'ppc' or ARCH == 'ppcspe' then
                ffi.cdef([[
                    struct stat {
                        unsigned long long st_dev;
                        unsigned long long st_ino;
                        unsigned int    st_mode;
                        unsigned int    st_nlink;
                        unsigned int    st_uid;
                        unsigned int    st_gid;
                        unsigned long long st_rdev;
                        unsigned long long __pad1;
                        long long       st_size;
                        int             st_blksize;
                        int             __pad2;
                        long long       st_blocks;
                        int             st_atime;
                        unsigned int    st_atime_nsec;
                        int             st_mtime;
                        unsigned int    st_mtime_nsec;
                        int             st_ctime;
                        unsigned int    st_ctime_nsec;
                        unsigned int    __unused4;
                        unsigned int    __unused5;
                    };
                ]])
                stat_syscall_num = IS_64_BIT and 106 or 195
        elseif ARCH == 'mips' or ARCH == 'mipsel' then
                ffi.cdef([[
                    struct stat {
                        unsigned long   st_dev;
                        unsigned long   __st_pad0[3];
                        unsigned long long      st_ino;
                        mode_t          st_mode;
                        nlink_t         st_nlink;
                        uid_t           st_uid;
                        gid_t           st_gid;
                        unsigned long   st_rdev;
                        unsigned long   __st_pad1[3];
                        long long       st_size;
                        time_t          st_atime;
                        unsigned long   st_atime_nsec;
                        time_t          st_mtime;
                        unsigned long   st_mtime_nsec;
                        time_t          st_ctime;
                        unsigned long   st_ctime_nsec;
                        unsigned long   st_blksize;
                        unsigned long   __st_pad2;
                        long long       st_blocks;
                        long __st_padding4[14];
                    };
                ]])
                stat_syscall_num = IS_64_BIT and 4106 or 4213
        else
            error("TODO support other architectures")
        end

        stat_func = function(filepath, buf)
            return lib.syscall(stat_syscall_num, filepath, buf)
        end
    else
        error('TODO support other posix os')
    end

    local STAT = {
        FMT   = 0xF000,
        FSOCK = 0xC000,
        FLNK  = 0xA000,
        FREG  = 0x8000,
        FBLK  = 0x6000,
        FDIR  = 0x4000,
        FCHR  = 0x2000,
        FIFO  = 0x1000,
    }

    local ftype_name_map = {
        [STAT.FREG]  = 'file',
        [STAT.FDIR]  = 'directory',
        [STAT.FLNK]  = 'link',
        [STAT.FSOCK] = 'socket',
        [STAT.FCHR]  = 'char device',
        [STAT.FBLK]  = "block device",
        [STAT.FIFO]  = "named pipe",
    }

    local function mode_to_ftype(mode)
        local ftype = band(mode, STAT.FMT)
        return ftype_name_map[ftype] or 'other'
    end

    local function mode_to_perm(mode)
        local perm_bits = band(mode, tonumber(777, 8))
        local perm = new_tab(9, 0)
        local i = 9
        while i > 0 do
            local perm_bit = band(perm_bits, 7)
            perm[i] = (band(perm_bit, 1) > 0 and 'x' or '-')
            perm[i-1] = (band(perm_bit, 2) > 0 and 'w' or '-')
            perm[i-2] = (band(perm_bit, 4) > 0 and 'r' or '-')
            i = i - 3
            perm_bits = rshift(perm_bits, 3)
        end
        return concat(perm)
    end

    local attr_handlers = {
        access = function(st) return tonumber(st.st_atime) end,
        blksize = function(st) return tonumber(st.st_blksize) end,
        blocks = function(st) return tonumber(st.st_blocks) end,
        change = function(st) return tonumber(st.st_ctime) end,
        dev = function(st) return tonumber(st.st_dev) end,
        gid = function(st) return st.st_gid end,
        ino = function(st) return tonumber(st.st_ino) end,
        mode = function(st) return mode_to_ftype(st.st_mode) end,
        modification = function(st) return tonumber(st.st_mtime) end,
        nlink = function(st) return tonumber(st.st_nlink) end,
        permissions = function(st) return mode_to_perm(st.st_mode) end,
        rdev = function(st) return tonumber(st.st_rdev) end,
        size = function(st) return tonumber(st.st_size) end,
        uid = function(st) return st.st_uid end,
    }

    local mt = {
        __index = function(self, attr_name)
        local func = attr_handlers[attr_name]
        return func and func(self)
        end
    }
    local stat_type = ffi.metatype('struct stat', mt)

    function _M.attributes(filepath, attr)
        local buf = ffi.new(stat_type)
        if stat_func(filepath, buf) == -1 then
            return nil, errno()
        end

        local atype = type(attr)
        if atype == 'string' then
            return buf[attr]
        else
            local tab = (atype == 'table') and attr or {}
            for k, _ in pairs(attr_handlers) do
                tab[k] = buf[k]
            end
            return tab
        end
    end

    function _M.chdir(path)
        if lib.chdir(path) == 0 then
            return true
        end
        return nil, errno()
    end

    function _M.currentdir()
        local buf = ffi.new("char[?]", MAXPATH)
        if lib.getcwd(buf, MAXPATH) ~= nil then
            return ffi_str(buf)
        end
        return nil, errno()
    end

    function _M.link(old, new, symlink)
        local f = symlink and lib.symlink or lib.link
        if f(old, new) == 0 then
            return true
        end
        return nil, errno()
    end

    function _M.setmode()
        return true, "binary"
    end

    local function iterator(dir)
        if dir.closed then error("closed directory") end

        local entry = lib.readdir(dir.dir)

        if entry ~= nil then
            return ffi_str(entry.d_name)
        else
            dir.dir = nil
            dir.closed = true
            return nil
        end
    end

    local function close(dir)
        dir.dir = nil
        dir.closed = true
    end

    local dirmeta = {__index = {
        next = iterator,
        close = close,
    }}

    function _M.dir(path)
        local dir = lib.opendir(path)
        if dir == nil then
            error("cannot open "..path.." : "..errno())
        end
        ffi.gc(dir, lib.closedir)

        local dir_obj = setmetatable ({
            path    = path,
            dir     = dir,
            closed  = false,
        }, dirmeta)

        return iterator, dir_obj
    end

    function _M.mkdir(path, mode)
        if lib.mkdir(path, mode or 509) == 0 then
            return true
        end
        return nil, errno()
    end

    function _M.rmdir(path)
        if lib.rmdir(path) == 0 then
            return true
        end
        return nil, errno()
    end

    function _M.touch(path, actime, modtime)
        local buf

        if type(actime) == "number" then
            modtime = modtime or actime
            buf = ffi.new("struct utimebuf")
            buf.actime  = actime
            buf.modtime = modtime
        end

        local p = ffi.new("unsigned char[?]", #path + 1)
        ffi.copy(p, path)

        if lib.utime(p, buf) == 0 then
            return true
        end
        return nil, errno()
    end
end

return _M
