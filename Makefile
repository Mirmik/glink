all: sharedlib/glinkLib.so

glinkLib.so: ccsrc/glink.c
	gcc ccsrc/glink.c --shared -o sharedlib/glinkLib.so -I/usr/include/lua5.3 -llua5.3 -Werror -std=gnu11 -pthread

clean:
	rm sharedlib/glinkLib.so

install:
	./tools/install.sh

uninstall:
	./tools/uninstall.sh