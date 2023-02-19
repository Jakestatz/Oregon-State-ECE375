
/*
This code will cause a TekBot connected to the AVR board to
move forward and when it touches an obstacle, it will reverse
and turn away from the obstacle and resume forward motion.

PORT MAP
Port B, Pin 5 -> Output -> Right Motor Enable
Port B, Pin 4 -> Output -> Right Motor Direction
Port B, Pin 6 -> Output -> Left Motor Enable
Port B, Pin 7 -> Output -> Left Motor Direction
Port D, Pin 5 -> Input -> Left Whisker
Port D, Pin 4 -> Input -> Right Whisker
*/

#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>

int main(void)
{
	DDRB = 0b11110000;      
	PORTB = 0b11110000;
	DDRD = 0b00001111;
	PORTD = 0b11111111;
	
	while (1) // loop forever
	{
		PORTB = 0b10010000;
		if (PIND == 0b11011111){								// Hit left 
			PORTB = 0b00000000;
			_delay_ms(1000);
			PORTB = 0b10000000;
			_delay_ms(1000);
		}
		if ((PIND == 0b11101111 || PIND == 0b10011111)){			// Hit right or both
			PORTB = 0b00000000;
			_delay_ms(1000);
			PORTB = 0b00010000;
			_delay_ms(1000);
		}
	}
}

