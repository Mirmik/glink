all: generic/sharedlibs/glinkLib.so

generic/sharedlibs/glinkLib.so: src/glink.c src/straight_executor.cpp
	gcc src/glink.c -fPIC -c -o generic/sharedlibs/glink.o  -I/usr/include/lua5.3 -llua5.3 -Werror -std=gnu11
	g++ src/straight_executor.cpp  -fPIC -c -o generic/sharedlibs/straight_executor.o -I/usr/include/lua5.3 -llua5.3 -Werror -std=gnu++14
	g++ generic/sharedlibs/straight_executor.o generic/sharedlibs/glink.o --shared -fPIC -o generic/sharedlibs/glinkLib.so -I/usr/include/lua5.3 -llua5.3 -Werror -std=gnu++14 -pthread

clean:
	rm generic/sharedlibs/glinkLib.so

install:
	./tools/install.sh

uninstall:
	./tools/uninstall.sh