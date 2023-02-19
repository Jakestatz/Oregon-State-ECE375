;***********************************************************
;*
;*	This is the skeleton file for Lab 6 of ECE 375
;*
;*	 Author: Jake Statz
;*	   Date: 11/9/2022
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	spd = r20				; Current speed
.def	waitcnt = r17			; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter
.def	Lcount = r14			; Left hit count
.def	Rcount = r15			; Right hit count

.equ	WTime = 150				; Time to wait in wait loop

.equ	EngEnR = 5				; right Engine Enable Bit
.equ	EngEnL = 6				; left Engine Enable Bit
.equ	EngDirR = 4				; right Engine Direction Bit
.equ	EngDirL = 7				; left Engine Direction Bit

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command
.equ	MovBck = $00				; Move Backward Command
.equ	TurnR = (1<<EngDirL)			; Turn Right Command
.equ	TurnL = (1<<EngDirR)			; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)		; Halt Command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt

.org	$0002
		rcall	SPEED_DOWN		; Decrease speed by 1
		reti

.org	$0004
		rcall	SPEED_UP		; Increase speed by 1
		reti

.org	$0008
		rcall	SPEED_MAX		; Set speed to max
		reti

.org	$0056					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND

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
  
		; Configure External Interrupts, if needed
		ldi		mpr, 0b10101010
		sts		EICRA, mpr
		ldi		mpr, 0b00001011	
		out		EIMSK, mpr

		; Configure 16-bit Timer/Counter 1A and 1B
		ldi		mpr, 0b10100001		; Fast PWM, 8-bit mode, no prescaling
		sts		TCCR1A, mpr
		ldi		mpr, 0b00001001	
		sts		TCCR1B, mpr

		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL) on Port B
		ldi		mpr, MovFwd
		out		PORTB, mpr

		; Set initial speed, display on Port B pins 3:0
		ldi		spd, 0
		ldi		mpr, MovFwd		; Adjust speed indication
		or		mpr, spd					
		out		PORTB, mpr

		; Enable global interrupts (if any are used)
		sei
;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		; poll Port D pushbuttons (if needed)

		ldi		mpr, MovFwd		; Adjust speed indication
		or		mpr, spd					
		out		PORTB, mpr

		rjmp	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Sub:	SPEED_DOWN
; Desc:	Cut and paste this and fill in the info at the
;		beginning of your functions
;-----------------------------------------------------------
SPEED_DOWN:
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr

		cpi		spd, 0
		breq	DSKIP
		dec		spd				
		ldi		mpr, 17			
		mul		mpr, spd		
		mov		mpr, r0			
		sts		OCR1AL, mpr		
		sts		OCR1BL, mpr	
		ldi		mpr, 0
		sts		OCR1AH, mpr		
		sts		OCR1BH, mpr	

DSKIP:
		ldi		mpr, 0b00001011
		out		EIFR, mpr	
		
		rcall	Wait	

		pop		mpr				; Restore program state
		out		SREG, mpr		
		pop		waitcnt			; Restore wait register
		pop		mpr				; Restore mpr
		ret						; End a function with RET
;-----------------------------------------------------------
; Sub:	SPEED_UP
; Desc:	Cut and paste this and fill in the info at the
;		beginning of your functions
;-----------------------------------------------------------
SPEED_UP:
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr

		cpi		spd, 15
		breq	USKIP
		inc		spd				
		ldi		mpr, 17			
		mul		mpr, spd		
		mov		mpr, r0			
		sts		OCR1AL, mpr		
		sts		OCR1BL, mpr	
		ldi		mpr, 0
		sts		OCR1AH, mpr		
		sts		OCR1BH, mpr			

USKIP:
		ldi		mpr, 0b00001011
		out		EIFR, mpr		

		rcall	Wait

		pop		mpr				; Restore program state
		out		SREG, mpr		
		pop		waitcnt			; Restore wait register
		pop		mpr				; Restore mpr
		ret						; End a function with RET
;-----------------------------------------------------------
; Sub:	SPEED_MAX
; Desc:	Cut and paste this and fill in the info at the
;		beginning of your functions
;-----------------------------------------------------------
SPEED_MAX:
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr
		
		ldi		spd, 15
		ldi		mpr, 255			
		sts		OCR1AL, mpr		
		sts		OCR1BL, mpr	
		ldi		mpr, 0
		sts		OCR1AH, mpr		
		sts		OCR1BH, mpr		

		ldi		mpr, 0b00001011	
		out		EIFR, mpr		
		
		rcall	Wait

		pop		mpr				; Restore program state
		out		SREG, mpr		
		pop		waitcnt			; Restore wait register
		pop		mpr				; Restore mpr
		ret						; End a function with RET

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly
;		waitcnt*10ms.  Just initialize wait for the specific amount
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			(((((3*ilcnt)-1+4)*olcnt)-1+4)*waitcnt)-1+16
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait
		brne	Loop			; Continue Wait loop

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine

;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program