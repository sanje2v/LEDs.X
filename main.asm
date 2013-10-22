; LED strip's 'WS2811' communicator for PIC16F877A
; PORT A's pin 0 is used to communicate with 'WS2811'
; Written by: Sanjeev Sharma
; http://sanje2v.wordpress.com/
; No copyright attached, Any liabilities disclaimed

	list 	p=16f877a			; list directive to define processor
	#include	<p16f877A.inc>	; processor specific include file (contains SFR register definitions)


;**********************************************************************
; CONFIGURATION BITS
;  Please DO NOT modify the configuration bits, otherwise your program may
;  fail to work!
;***********************************************************************

	__CONFIG	_CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _HS_OSC & _WRT_OFF & _LVP_OFF & _CPD_OFF

    radix dec


;**********************************************************************
; GENERAL PURPOSE REGISTERS: ADDRESS DEFINITIONS
;
;**********************************************************************

	CBLOCK	0x20
	POR_DELAY	;Stored in location 0x20 [Note: POR = Power On Reset]
	RED_BYTE	;0x21
    GREEN_BYTE	;0x22
    BLUE_BYTE	;0x23

    WAIT_COUNT
    ID_LED_READY
	ENDC


;**********************************************************************
; PROGRAM CODE
;
;**********************************************************************

	ORG	0x000	; Processor Reset Vector
RESET_V
    call INIT
	goto MAIN


;----------------------------------------------------------------------
; INTERRUPT SERVICE ROUTINE
;  This code can be removed if interrupts are not going to be used.
;----------------------------------------------------------------------

	ORG	0x004	; Interrupt Vector Location
ISR retfie		; return from interrupt


;----------------------------------------------------------------------
; INIT ROUTINE
;
;----------------------------------------------------------------------

INIT
    bcf STATUS, RP1
    bsf STATUS, RP0     ; Bank 1
    movlw 0x06
    movwf ADCON1        ; Make all pins digital
    movlw b'00000000'
    movwf TRISA         ; Set port A, all pins as output

    bcf STATUS, RP0     ; Bank 0
    bcf ADCON0, ADON    ; Disable ADCON module
    movlw b'00000000'
    movwf PORTA         ; Set all pins of port A to low

    return


;----------------------------------------------------------------------
; MAIN ROUTINE
;
;----------------------------------------------------------------------

MAIN
    bcf STATUS, RP0
    bcf STATUS, RP1     ; Select Bank 0

    ; Default values for each color data byte
    movlw 0xFF
    movwf RED_BYTE
    movwf GREEN_BYTE
    movwf BLUE_BYTE

NEXT_REFRESH_CYCLE
    movlw 60            ; No of LEDs to control
    movwf ID_LED_READY

    movlw 0x35          ; Value for delay of ~50 us
    movwf WAIT_COUNT

    ; Color changing processing here, also adjust wait appropriately above
    comf RED_BYTE, f

;    incfsz RED_BYTE
;    goto NEXT_DELAY
;    incfsz GREEN_BYTE
;    goto NEXT_DELAY
;    incf BLUE_BYTE

NEXT_DELAY

    nop
    addlw -1
    btfss STATUS, Z
    goto NEXT_DELAY

CONTINUOUS_SEND

    call SEND_RGB

    decfsz ID_LED_READY, f
    goto CONTINUOUS_SEND
    goto NEXT_REFRESH_CYCLE

	;goto	$	; DO NOT REMOVE THIS INSTRUCTION!!!

;----------------------------------------------------------------------
; SEND_RGB SUBROUTINE
; Sends data in 'RED_BYTE', 'GREEN_BYTE' and 'BLUE_BYTE'. Actually, the
; proper byte order requested by hardware 'WS2811' is 'GRB' instead of
; 'RGB' and so is sent in that order. Also, high bit is sent first.
; Here is the timing requirement for High-Speed WS2811:
;   Logical '0': 0.25 us HIGH, 1.0 us LOW
;   Logical '1': 0.60 us HIGH, 0.65 us LOW
;   Total period of a bit: 1.25 us
;
; The following code actually gives a cell length of '1.20 us' which is
; the most that can be expected out of a 5 MHz (200ns instruction cycle)
; microprocessor:
;   OUTPUT_0 MACRO
;    bsf PORTA, 0x0
;    bcf PORTA, 0x0
;    nop
;    nop
;    nop
;    nop
;    ENDM
;
;   OUTPUT_1 MACRO
;    bsf PORTA, 0x0
;    nop
;    nop
;    bcf PORTA, 0x0
;    nop
;    nop
;    ENDM
; As there are more stuff that need to be done and processing cycle is
; very tight, we remove some of the 'nop's and come up with the following.
;
; For 24-bits sent by this subroutine, the average timing for each cell
; was calculated to be 1.23 us which is pretty good!
;----------------------------------------------------------------------

OUTPUT_0 MACRO
    bsf PORTA, 0x0
    bcf PORTA, 0x0
    ENDM

OUTPUT_1 MACRO
    bsf PORTA, 0x0
    nop
    nop
    bcf PORTA, 0x0
    ENDM

SEND_RGB

SEND_BIT23
    btfsc GREEN_BYTE, 7
    goto SEND_BIT23_1

SEND_BIT23_0
    OUTPUT_0
    goto SEND_BIT22

SEND_BIT23_1
    OUTPUT_1

SEND_BIT22
    btfsc GREEN_BYTE, 6
    goto SEND_BIT22_1

SEND_BIT22_0
    OUTPUT_0
    goto SEND_BIT21

SEND_BIT22_1
    OUTPUT_1

SEND_BIT21
    btfsc GREEN_BYTE, 5
    goto SEND_BIT21_1

SEND_BIT21_0
    OUTPUT_0
    goto SEND_BIT20

SEND_BIT21_1
    OUTPUT_1

SEND_BIT20
    btfsc GREEN_BYTE, 4
    goto SEND_BIT20_1

SEND_BIT20_0
    OUTPUT_0
    goto SEND_BIT19

SEND_BIT20_1
    OUTPUT_1

SEND_BIT19
    btfsc GREEN_BYTE, 3
    goto SEND_BIT19_1

SEND_BIT19_0
    OUTPUT_0
    goto SEND_BIT18

SEND_BIT19_1
    OUTPUT_1

SEND_BIT18
    btfsc GREEN_BYTE, 2
    goto SEND_BIT18_1

SEND_BIT18_0
    OUTPUT_0
    goto SEND_BIT17

SEND_BIT18_1
    OUTPUT_1

SEND_BIT17
    btfsc GREEN_BYTE, 1
    goto SEND_BIT17_1

SEND_BIT17_0
    OUTPUT_0
    goto SEND_BIT16

SEND_BIT17_1
    OUTPUT_1

SEND_BIT16
    btfsc GREEN_BYTE, 0
    goto SEND_BIT16_1

SEND_BIT16_0
    OUTPUT_0
    goto SEND_BIT15

SEND_BIT16_1
    OUTPUT_1

SEND_BIT15
    btfsc RED_BYTE, 7
    goto SEND_BIT15_1

SEND_BIT15_0
    OUTPUT_0
    goto SEND_BIT14

SEND_BIT15_1
    OUTPUT_1

SEND_BIT14
    btfsc RED_BYTE, 6
    goto SEND_BIT14_1

SEND_BIT14_0
    OUTPUT_0
    goto SEND_BIT13

SEND_BIT14_1
    OUTPUT_1

SEND_BIT13
    btfsc RED_BYTE, 5
    goto SEND_BIT13_1

SEND_BIT13_0
    OUTPUT_0
    goto SEND_BIT12

SEND_BIT13_1
    OUTPUT_1

SEND_BIT12
    btfsc RED_BYTE, 4
    goto SEND_BIT12_1

SEND_BIT12_0
    OUTPUT_0
    goto SEND_BIT11

SEND_BIT12_1
    OUTPUT_1

SEND_BIT11
    btfsc RED_BYTE, 3
    goto SEND_BIT11_1

SEND_BIT11_0
    OUTPUT_0
    goto SEND_BIT10

SEND_BIT11_1
    OUTPUT_1

SEND_BIT10
    btfsc RED_BYTE, 2
    goto SEND_BIT10_1

SEND_BIT10_0
    OUTPUT_0
    goto SEND_BIT9

SEND_BIT10_1
    OUTPUT_1

SEND_BIT9
    btfsc RED_BYTE, 1
    goto SEND_BIT9_1

SEND_BIT9_0
    OUTPUT_0
    goto SEND_BIT8

SEND_BIT9_1
    OUTPUT_1

SEND_BIT8
    btfsc RED_BYTE, 0
    goto SEND_BIT8_1

SEND_BIT8_0
    OUTPUT_0
    goto SEND_BIT7

SEND_BIT8_1
    OUTPUT_1

SEND_BIT7
    btfsc BLUE_BYTE, 7
    goto SEND_BIT7_1

SEND_BIT7_0
    OUTPUT_0
    goto SEND_BIT6

SEND_BIT7_1
    OUTPUT_1

SEND_BIT6
    btfsc BLUE_BYTE, 6
    goto SEND_BIT6_1

SEND_BIT6_0
    OUTPUT_0
    goto SEND_BIT5

SEND_BIT6_1
    OUTPUT_1

SEND_BIT5
    btfsc BLUE_BYTE, 5
    goto SEND_BIT5_1

SEND_BIT5_0
    OUTPUT_0
    goto SEND_BIT4

SEND_BIT5_1
    OUTPUT_1

SEND_BIT4
    btfsc BLUE_BYTE, 4
    goto SEND_BIT4_1

SEND_BIT4_0
    OUTPUT_0
    goto SEND_BIT3

SEND_BIT4_1
    OUTPUT_1

SEND_BIT3
    btfsc BLUE_BYTE, 3
    goto SEND_BIT3_1

SEND_BIT3_0
    OUTPUT_0
    goto SEND_BIT2

SEND_BIT3_1
    OUTPUT_1

SEND_BIT2
    btfsc BLUE_BYTE, 2
    goto SEND_BIT2_1

SEND_BIT2_0
    OUTPUT_0
    goto SEND_BIT1

SEND_BIT2_1
    OUTPUT_1

SEND_BIT1
    btfsc BLUE_BYTE, 1
    goto SEND_BIT1_1

SEND_BIT1_0
    OUTPUT_0
    goto SEND_BIT0

SEND_BIT1_1
    OUTPUT_1

SEND_BIT0
    btfsc BLUE_BYTE, 0
    goto SEND_BIT0_1

SEND_BIT0_0
    OUTPUT_0
    return

SEND_BIT0_1
    OUTPUT_1
    return

	END