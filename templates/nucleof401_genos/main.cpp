#include <hal/board.h>
#include <drivers/gpio.h>

#include <debug/dprint.h>
#include <debug/delay.h>
#include <kernel/panic.h>

void setup();
void loop();

int main() {
	board_init();

	setup();
	while(1) loop();
}

void setup() {}

void loop() {
	debug_print("HelloWorld\r\n");	
	debug_delay(1000);
	pin_tgl_level(USER_LED);
	//panic("Hel");
}