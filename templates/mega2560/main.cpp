void setup();
void loop();

#include <avr/interrupt.h>

int main() {
	setup();
	sei();
	while(1) loop();
}

void setup() {
}

void loop() {
}