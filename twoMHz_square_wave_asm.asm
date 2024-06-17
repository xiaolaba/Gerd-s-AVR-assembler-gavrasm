;Atmel assembler, avrasm2.exe will uses *.inc
;Gavrasm assembler, no need and do not use *.inc

.nolist
	.include "m328Pdef.inc"	;included for compability only
.list

; what follows is to be placed in program memory
.cseg

; starting at this address
.org 0x0000
Setup:
	cli	;disable all interrupt

	; set PB5~PB0 to output using DDRB
    ldi r16, 0b00111111	;arduino nano/uno, PB6/PB7 used for XTAL1/XTAL2, not IO
	out DDRB, r16
	
	;24bit pattern to rolling and output to PORTB
	ldi r16, 0b10101010	; 
	ldi r17, 0b10101010	; 
	ldi r18, 0b10101010	;
	out PORTB, r16		; output pattern to PORTB

Main:
    ror r16			; rotate pattern
	out PORTB, r16	; output pattern to PORTB
    ror r17			; rotate pattern
	out PORTB, r17	; output pattern to PORTB
    ror r18			; rotate pattern
	out PORTB, r18	; output pattern to PORTB
    rjmp Main		; repeat forever
