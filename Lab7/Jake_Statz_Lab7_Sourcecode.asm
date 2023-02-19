
;***********************************************************
;*
;*	This is the TRANSMIT skeleton file for Lab 7 of ECE 375
;*
;*  Rock Paper Scissors
;* 	Requirement:
;* 	1. USART1 communication
;* 	2. Timer/counter1 Normal mode to create a 1.5-sec delay
;***********************************************************
;*
;*	 Author: Jake Statz
;*	   Date: 11/15/2022
;*
;***********************************************************

.include "m32U4def.inc"         ; Include definition file

;***********************************************************
;*  Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	state = r17				; Game State
.def	txbyte = r18			; Transmit Byte
.def	rxbyte = r19			; Receive Byte
.def	umove = r23				; User Move
.def	opmove = r24			; Opponent Move
.def	opready = r25			; Opponent Ready
.def	waitcnt = r11			; Wait Loop Counter
.def	ilcnt = r10				; Inner Loop Counter
.def	olcnt = r9				; Outer Loop Counter

.equ	WTime = 150				; Time to wait in wait loop
; Use this signal code between two boards for their game ready
.equ    SendReady = 0b11111111

;***********************************************************
;*  Start of Code Segment
;***********************************************************
.cseg                           ; Beginning of code segment

;***********************************************************
;*  Interrupt Vectors
;***********************************************************
.org    $0000						; Beginning of IVs
	    rjmp    INIT            	; Reset interrupt

.org	$0002
		rcall	READY
		reti

.org	$0004
		rcall	MOVESELECT
		reti

.org	$0032
		rcall	RX
		reti

.org    $0056						; End of Interrupt Vectors

;***********************************************************
;*  Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND
	;I/O Ports
		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low

		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State
	;USART1
		;Set baudrate at 2400bps
		ldi		mpr, 0x00
		sts		UBRR1H, mpr
		ldi		mpr, 0xCF
		sts		UBRR1L, mpr

		;Enable receiver and transmitter
		ldi		mpr, (1<<RXEN1)|(1<<TXEN1)
		sts		UCSR1B, mpr

		;Set frame format: 8 data bits, 2 stop bits
		ldi		mpr, (1<<USBS1)|(3<<UCSZ10)
		sts		UCSR1C, mpr

	;TIMER/COUNTER1
		ldi mpr, 0b00000000		;Set Normal mode
		sts TCCR1A, mpr
		ldi mpr, 0b00000101
		sts TCCR1B, mpr

	;LCD
		rcall	LCDInit
		rcall	LCDClr
		rcall	LCDBacklightOn
		rcall	WELCOMEMSG

	;Interrupts
		ldi		mpr, 0b00001010
		sts		EICRA, mpr
		ldi		mpr, 0b00000001
		out		EIMSK, mpr

	;Clears
		clr		state
		clr		umove
		clr		opready

		sei		; Enable Interrupts

;***********************************************************
;*  Main Program
;***********************************************************
MAIN:	
		cpi		state, 0x02			; Poll for the game to start
		breq	START
		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
READY:
		ldi		state, 0x01			; Set state to ready
		rcall	WAITMSG				; Display the wait message

		ldi		txbyte, SendReady	; Transmit you are ready
		sts		UDR1, txbyte

		READYLOOP:
			cpi		rxbyte, SendReady	; Constantly check for oponent ready
			breq	READYLOOP
		ldi		state, 0x02				; Set state to start
		ldi		mpr, 0b00000001			; clear interrupts 
		out		EIFR, mpr

		ret

RX:
		lds		rxbyte, UDR1			; receive transmition

		ret

LEDCOUNTDOWN:
		push	state					; There are not enough registors so reuse some

		ldi		mpr, 0b11110000
		out		PORTB, mpr
		ldi		state, WTime
		rcall	WAIT
		ldi		mpr, 0b01110000
		out		PORTB, mpr
		ldi		state, WTime
		rcall	WAIT
		ldi		mpr, 0b00110000
		out		PORTB, mpr
		ldi		state, WTime
		rcall	WAIT
		ldi		mpr, 0b00010000
		out		PORTB, mpr
		ldi		state, WTime
		rcall	WAIT
		ldi		mpr, 0b00000000
		out		PORTB, state

		pop		state

		ret

START:
		rcall	STARTMSG			; Display the start message
		rcall	LCDClrLn2			; Clear the second line to clean up

		ldi		mpr, 0b00000011		; Enable pd4
		out		EIMSK, mpr
		rcall	LEDCOUNTDOWN		; Start led countdown
		ldi		state, 0x03			
		mov		txbyte, umove
		sts		UDR1, txbyte		; Send move after countdown 
		rcall	RX					; Receive move
		mov		opmove, rxbyte
		cpi		umove, 0x01			; Branch depending on what move the play used
		breq	UROCK
		cpi		umove, 0x02
		breq	UPAPER
		cpi		umove, 0x03
		breq	USCISSORS
		rjmp	INIT

		ret

UROCK:							; Determine who won
		cpi		opmove, 0x01
		breq	DRAW
		cpi		opmove, 0x02
		breq	LOSE
		cpi		opmove, 0x03
		breq	WIN
		ret

UPAPER:
		cpi		opmove, 0x01
		breq	WIN
		cpi		opmove, 0x02
		breq	DRAW
		cpi		opmove, 0x03
		breq	LOSE
		ret

USCISSORS:
		cpi		opmove, 0x01
		breq	LOSE
		cpi		opmove, 0x02
		breq	WIN
		cpi		opmove, 0x03
		breq	DRAW
		ret

WIN:											; Display who won
		ldi		ZL, low(WIN_START<<1)
		ldi		ZH, high(WIN_START<<1)
		ldi		XH, High($0100)
		ldi		XL, Low($0100)

		WINLOOP:
			lpm		mpr, Z+
			st		X+, mpr
			cpi		ZL, low(WIN_END<<1)
			brne	WINLOOP
		rcall	LCDWrLn1

		ret

LOSE:
		ldi		ZL, low(LOSE_START<<1)
		ldi		ZH, high(LOSE_START<<1)
		ldi		XH, High($0100)
		ldi		XL, Low($0100)

		LOSELOOP:
			lpm		mpr, Z+
			st		X+, mpr
			cpi		ZL, low(LOSE_END<<1)
			brne	LOSELOOP
		rcall	LCDWrLn1

		ret

DRAW:
		ldi		ZL, low(DRAW_START<<1)
		ldi		ZH, high(DRAW_START<<1)
		ldi		XH, High($0100)
		ldi		XL, Low($0100)

		DRAWLOOP:
			lpm		mpr, Z+
			st		X+, mpr
			cpi		ZL, low(DRAW_END<<1)
			brne	DRAWLOOP
		rcall	LCDWrLn1

		ret
			
MOVESELECT:
		inc		umove							; Branch depending on move count
		cpi		umove, 0x01
		breq	ROCK
		cpi		umove, 0x02
		breq	PAPER	
		cpi		umove, 0x03
		breq	SCISSORS

		ROCK:
			ldi		ZL, low(ROCK_START<<1)		; Display The move
			ldi		ZH, high(ROCK_START<<1)
			ldi		XH, High($0110)
			ldi		XL, Low($0110)
			ROCKLOOP:
				lpm		mpr, Z+
				st		X+, mpr
				cpi		ZL, low(ROCK_END<<1)
				brne	ROCKLOOP
			rcall	LCDWrLn2
			ldi		mpr, 0b00000001
			out		EIFR, mpr
			ret

		PAPER:
			ldi		ZL, low(PAPER_START<<1)
			ldi		ZH, high(PAPER_START<<1)
			ldi		XH, High($0110)
			ldi		XL, Low($0110)
			PAPERLOOP:
				lpm		mpr, Z+
				st		X+, mpr
				cpi		ZL, low(PAPER_END<<1)
				brne	PAPERLOOP
			rcall	LCDWrLn2
			ldi		mpr, 0b00000001
			out		EIFR, mpr
			ret

		SCISSORS:
			ldi		ZL, low(SCISSORS_START<<1)
			ldi		ZH, high(SCISSORS_START<<1)
			ldi		XH, High($0110)
			ldi		XL, Low($0110)
			SCISSORSLOOP:
				lpm		mpr, Z+
				st		X+, mpr
				cpi		ZL, low(SCISSORS_END<<1)
				brne	SCISSORSLOOP
			rcall	LCDWrLn2
			clr		umove							; Clear to start loop over
			ldi		mpr, 0b00000001
			out		EIFR, mpr
			ret

WELCOMEMSG:
		push	mpr
		
		ldi		ZL, low(WELCOME_START<<1)
		ldi		ZH, high(WELCOME_START<<1)
		ldi		XH, High($0100)
		ldi		XL, Low($0100)

		WELLOOP:
			lpm		mpr, Z+
			st		X+, mpr
			cpi		ZL, low(WELCOME_END<<1)
			brne	WELLOOP

		rcall	LCDWrite
		pop		mpr

		ret

WAITMSG:
		push	mpr
		
		ldi		ZL, low(WAIT_START<<1)
		ldi		ZH, high(WAIT_START<<1)
		ldi		XH, High($0100)
		ldi		XL, Low($0100)

		WAILOOP:
			lpm		mpr, Z+
			st		X+, mpr
			cpi		ZL, low(WAIT_END<<1)
			brne	WAILOOP

		rcall	LCDWrite
		pop		mpr

		ret

STARTMSG:
		
		push	mpr

		ldi		ZL, low(START_START<<1)
		ldi		ZH, high(START_START<<1)
		ldi		XH, High($0100)
		ldi		XL, Low($0100)

		STARLOOP:
			lpm		mpr, Z+
			st		X+, mpr
			cpi		ZL, low(START_END<<1)
			brne	STARLOOP

		rcall	LCDWrite
		pop		mpr

		ret

WAIT:	
		push	state			; Save wait register
		push	txbyte			; Save ilcnt register
		push	rxbyte			; Save olcnt register

Loop:	ldi		rxbyte, 224		; load olcnt register
OLoop:	ldi		txbyte, 237		; load ilcnt register
ILoop:	dec		txbyte			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		rxbyte		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		state		; Decrement wait
		brne	Loop			; Continue Wait loop

		pop		rxbyte		; Restore olcnt register
		pop		txbyte		; Restore ilcnt register
		pop		state		; Restore wait register
		ret				; Return from subroutine
;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
WELCOME_START:
    .DB		"Welcome!        Please press PD7"		; Declaring data in ProgMem
WELCOME_END:

WAIT_START:
    .DB		"READY, Waiting  for the opponent"		
WAIT_END:

ROCK_START:
    .DB		"Rock            "
ROCK_END:

PAPER_START:
    .DB		"Paper           "
PAPER_END:

SCISSORS_START:
    .DB		"Scissors        "		
SCISSORS_END:

START_START:
    .DB		"GAME START      "
START_END:

WIN_START:
    .DB		"You Won!        "
WIN_END:

LOSE_START:
    .DB		"You Lost.       "
LOSE_END:

DRAW_START:
    .DB		"Draw            "
DRAW_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver

