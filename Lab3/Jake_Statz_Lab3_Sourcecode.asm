;***********************************************************
;*	This is the skeleton file for Lab 3 of ECE 375
;*
;*	 Author: Jake Statz
;*	   Date: 10/12/2022
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is required for LCD Driver
.def	mpr2 = r17
.def	Cnum = r23
.def	waitcnt = r18
.def	ilcnt = r19
.def	olcnt = r24
.equ	Dmax = 16
.equ	Button1 = 4			
.equ	Button2 = 5			
.equ	Button3 = 6				
.equ	Button4 = 7

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0056					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND
		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State
		; Initialize LCD Display
		rcall LCDInit
		rcall LCDBacklightOn
		rcall LCDClr
		; NOTE that there is no RET or RJMP from INIT,
		; this is because the next instruction executed is the
		; first instruction of the main program

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		in		mpr, PIND
		cpi		mpr, (0b11101111)
		brne	CHECK5
		rcall	CLEAR
		rjmp	MAIN
CHECK5:
		cpi		mpr, (0b11011111)
		brne	CHECK6
		rcall	DIS1
		rjmp	MAIN
CHECK6:
		cpi		mpr, (0b10111111)
		brne	MAIN
		rcall	DIS2
		rjmp	MAIN
								; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Clear
; Desc: Clears both lines of the LCD display
;-----------------------------------------------------------
CLEAR:							
		rcall LCDClr ; Clear both lines of the LCD

		ret						; End a function with RET
;-----------------------------------------------------------
; Func: Dis1
; Desc: Displays my name on line one, and hello word on line 2
;-----------------------------------------------------------
DIS1:
		clr		Cnum
		ldi		ZL, Low(STRING1_BEG<<1)
		ldi		ZH, High(STRING1_BEG<<1)
		ldi		YH, High($0100)
		ldi		YL, Low($0100)
		Loop1:	
				cpi		Cnum, Dmax
				breq	Next1
				lpm		mpr, Z+					
				st		Y+, mpr					
				inc		Cnum						
				rjmp	Loop1
				
		Next1: 
				clr		Cnum
				ldi		ZL, Low(STRING2_BEG<<1)
				ldi		ZH, High(STRING2_BEG<<1)
				ldi		XH, High($0110)
				ldi		XL, Low($0110)
		Loop2:
				cpi		Cnum, Dmax
				breq	Next2
				lpm		mpr, Z+					
				st		X+, mpr					
				inc		Cnum						
				rjmp	Loop2
		Next2:
				rcall	LCDWrite
		ret
;-----------------------------------------------------------
; Func: Dis2
; Desc: Displays hello word on line 1 and my name on line 2
;-----------------------------------------------------------
DIS2:
		clr		Cnum
		ldi		ZL, Low(STRING1_BEG<<1)
		ldi		ZH, High(STRING1_BEG<<1)
		ldi		XH, High($0110)
		ldi		XL, Low($0110)
		Loop3:	
				cpi		Cnum, Dmax
				breq	Next3
				lpm		mpr, Z+					
				st		X+, mpr					
				inc		Cnum						
				rjmp	Loop3
		Next3: 
				clr		Cnum
				ldi		ZL, Low(STRING2_BEG<<1)
				ldi		ZH, High(STRING2_BEG<<1)
				ldi		YH, High($0100)
				ldi		YL, Low($0100)
		Loop4:
				cpi		Cnum, Dmax
				breq	Next4
				lpm		mpr, Z+					
				st		Y+, mpr					
				inc		Cnum						
				rjmp	Loop4
		Next4:
				rcall	LCDWrite
		ret

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING1_BEG:
.DB		"Jake Statz      "					; Declaring data in ProgMem
STRING1_END:
STRING2_BEG:
.DB		"Hello, World    "					; Declaring data in ProgMem
STRING2_END:
STRING3_BEG:
.DB		"My Name Is      "					; Declaring data in ProgMem
STRING3_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
