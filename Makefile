all: generic/sharedlibs/glinkLib.so

generic/sharedlibs/glinkLib.so: src/glink.c
	gcc src/glink.c --shared -o generic/sharedlibs/glinkLib.so -I/usr/include/lua5.3 -llua5.3 -Werror -std=gnu11 -pthread

clean:
	rm generic/sharedlibs/glinkLib.so

install:
	./tools/install.sh

uninstall:
	./tools/uninstall.sh