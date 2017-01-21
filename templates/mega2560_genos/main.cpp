#include <hal/arch.h>
#include <kernel/diag.h>
#include <drivers/gpio.h>

#include <debug/delay.h>
#include <drivers/serial/UartRingDriver.h>
#include <drivers/serial/avr/UartDriver.h>

#include <debug/dprint.h>
#include <kernel/irq.h>

char txbuf[128];
char rxbuf[128];
AVRHardwareUsart __usart0(USART0, ATMEGA_IRQ_U0RX);
UartRingDriver usart0(&__usart0, txbuf, 128, rxbuf, 128);

void setup();
void loop();

int main() {
	arch_init();
	diag_init();

	setup();
	global_irq_enable();
	while(1) loop();
}

void setup() {
	gpio_settings(GPIOB, (1<<7), GPIO_MODE_OUTPUT);
	gpio_set_level(GPIOB, (1<<7), 1);
	UartParams params;
	params.baudRate = 115200;

	usart0.begin(&params);
}

void loop() {
	debug_delay(1000);
	usart0.println("HelloWorld");
	gpio_tgl_level(GPIOB, (1<<7));
}