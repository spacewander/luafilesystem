PREFIX ?=          /usr/local
LUA_LIB_DIR ?=     $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL ?= install

.PHONY: all install

all: ;

install: all
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)
	$(INSTALL) lfs_ffi.lua $(DESTDIR)/$(LUA_LIB_DIR)

