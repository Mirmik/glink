all: glinkLib.so

glinkLib.so: ccsrc/glink.c
	gcc ccsrc/glink.c --shared -o glinkLib.so -I/usr/include/lua5.3 -llua5.3 -Werror -std=gnu11 -pthread

clean:
	rm glinkLib.so