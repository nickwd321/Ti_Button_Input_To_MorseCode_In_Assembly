;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .global _main
            .global __STACK_END
            .sect   .stack                  ; Make stack linker segment ?known?

            .text                           ; Assemble to Flash memory
            .retain                         ; Ensure current section gets linked
            .retainrefs

SEGA        .set    BIT0 ; P2.0
SEGB        .set    BIT1 ; P2.1
SEGC        .set    BIT2 ; P2.2
SEGD        .set    BIT3 ; P2.3
SEGE        .set    BIT4 ; P2.4
SEGF        .set    BIT5 ; P2.5
SEGG        .set    BIT6 ; P2.6
SEGDP       .set    BIT7 ; P2.7

DIG1        .set    BIT0 ; P3.0
DIG2        .set    BIT1 ; P3.1
DIG3        .set    BIT2 ; P3.2
DIG4        .set    BIT3 ; P3.3
DIGCOL      .set    BIT7 ; P3.7

BTN1		.set	BIT7 ; P4.7
BTN2		.set	BIT3 ; P1.3
BTN3		.set    BIT5 ; P1.5

digit       .set    R4   ; Set of flags for state machine
display1    .set    R5   ; Display digits
display2    .set    R6   ; Temporary Display digits
display3     .set    R7
display4     .set    R8
mreg         .set    R14
count        .set	R13
temp         .set    R12
disselect    .set   R11

_main
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w #WDTPW+WDTCNTCL+WDTTMSEL+7+WDTSSEL__ACLK,&WDTCTL ; Interval mode with ACLK
			bis.w #WDTIE, &SFRIE1                                       ; enable interrupts for the watchdog

SetupSeg    bic.b   #SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG+SEGDP,&P2OUT
            bic.b   #DIG1+DIG2+DIG3+DIG4+DIGCOL,&P3OUT
            bis.b   #SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG+SEGDP,&P2DIR
            bis.b   #DIG1+DIG2+DIG3+DIG4+DIGCOL,&P3DIR
            bic.b   #SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG+SEGDP,&P2OUT
            bic.b   #DIG1+DIG2+DIG3+DIG4+DIGCOL,&P3OUT

SetupPB		bic.b   #BTN1, &P4DIR
			bic.b   #BTN3+BTN2, &P1DIR
			bis.b   #BTN1, &P4REN
			bis.b   #BTN3+BTN2, &P1REN
			bis.b   #BTN1, &P4OUT
			bis.b   #BTN3+BTN2, &P1OUT
			bis.b   #BTN1, &P4IES
			bis.b   #BTN3+BTN2, &P1IES
			bis.b   #BTN1, &P4IE
			bis.b   #BTN3+BTN2, &P1IE

EditClock   mov.b   #CSKEY_H,&CSCTL0_H      ; Unlock CS registers
            mov.w   #DCOFSEL_3,&CSCTL1      ; Set DCO setting for 4MHz
            mov.w   #DIVA__1+DIVS__1+DIVM__1,&CSCTL3 ; MCLK = SMCLK = DCO = 4MHz
            clr.b   &CSCTL0_H               ; Lock CS registers

TimerSetup  mov.w   #CCIE,&TA0CCTL0                            ; TACCR0 interrupt enabled
            mov.w   #12499,&TA0CCR0                             ; Delay by 1 second
            mov.w   #TASSEL__SMCLK+MC__STOP+BIT6+BIT7,&TA0CTL  ; SMCLK, continuous mode, Div 8
            mov.w   #BIT0+BIT1+BIT2,&TA0EX0  ; Div 8

UnlockGPIO  bic.w   #LOCKLPM5,&PM5CTL0      ; Disable the GPIO power-on default
                                            ; high-impedance mode to activate
                                            ; previously configured port settings

			bic.b   #BTN2+BTN3, &P1IFG      ; Reset interrupts here,
			bic.b   #BTN1, &P4IFG           ; unlocking the GPIO tends to trigger an interrupt



			nop
			bis.b   #GIE, SR                ; enable all interrupts
			nop



			mov.w  #0, display1
			mov.w  #0, display2
			mov.w  #0, display3
			mov.w  #0, display4
			mov.w  #1, mreg
			mov.w  #0, count
			mov.w  #0, temp
			mov.w #0, disselect

Mainloop

		    jmp     Mainloop                ; Again
;-------------------------------------------------------------------------------
; Look Up Tables
;-------------------------------------------------------------------------------
letters         .byte   SEGA+SEGB+SEGC	   +SEGE+SEGF+SEGG      ; A
				.byte             SEGC+SEGD+SEGE+SEGF+SEGG      ; b
				.byte   SEGA          +SEGD+SEGE+SEGF           ; c
				.byte        SEGB+SEGC+SEGD+SEGE     +SEGG      ; d
				.byte   SEGA		  +SEGD+SEGE+SEGF+SEGG      ; e
				.byte   SEGA               +SEGE+SEGF+SEGG      ; f
				.byte   SEGA     +SEGC+SEGD+SEGE+SEGF+SEGG      ; g
				.byte        SEGB+SEGC     +SEGE+SEGF+SEGG      ; h
				.byte                       SEGE+SEGF           ; i
				.byte        SEGB+SEGC+SEGD                     ; j
				.byte   SEGA     +SEGC     +SEGE+SEGF+SEGG      ; k
				.byte                  SEGD+SEGE+SEGF           ; l
				.byte   SEGA+SEGB+SEGC     +SEGE+SEGF           ; m
				.byte             SEGC+     SEGE+     SEGG      ; n
				.byte             SEGC+SEGD+SEGE     +SEGG      ; o
				.byte   SEGA+SEGB          +SEGE+SEGF+SEGG      ; p
				.byte   SEGA+SEGB+SEGC+          SEGF+SEGG      ; q
				.byte   SEGA+SEGB          +SEGE+SEGF           ; r
				.byte   SEGA     +SEGC+SEGD     +SEGF+SEGG      ; s
				.byte                       SEGE+SEGF+SEGG      ; t
				.byte             SEGC+SEGD+SEGE                ; u
				.byte        SEGB+SEGC+SEGD+SEGE+SEGF           ; v
				.byte   SEGA+     SEGC+SEGD+SEGE                ; w
				.byte             SEGC     +SEGE                ; x
				.byte        SEGB+SEGC+SEGD     +SEGF+SEGG      ; y
				.byte   SEGA+SEGB     +SEGD+SEGE     +SEGG      ; z
				.byte   SEGA+SEGB+SEGC+SEGD+SEGE+SEGF           ; 0
            	.byte        SEGB+SEGC                          ; 1
          	    .byte   SEGA+SEGB+     SEGD+SEGE+     SEGG      ; 2
          	    .byte	SEGA+SEGB+SEGC+SEGD          +SEGG		; 3
                .byte        SEGB+SEGC+          SEGF+SEGG      ; 4
                .byte   SEGA+     SEGC+SEGD+     SEGF+SEGG      ; 5
                .byte   SEGA+     SEGC+SEGD+SEGE+SEGF+SEGG      ; 6
                .byte   SEGA+SEGB+SEGC                          ; 7
                .byte   SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG      ; 8
                .byte   SEGA+SEGB+SEGC+SEGD+     SEGF+SEGG      ; 9

morsecode
				.word	000000000000000000000110b  ;a
				.word	000000000000000000010111b  ;b
				.word	000000000000000000010101b  ;c
				.word	000000000000000000001011b  ;d
				.word	000000000000000000000011b  ;e
				.word	000000000000000000011101b  ;f
				.word	000000000000000000001001b  ;g
				.word	000000000000000000011111b  ;h
				.word	000000000000000000000111b  ;i
				.word	000000000000000000011000b  ;j
				.word	000000000000000000001010b  ;k
				.word	000000000000000000011011b  ;l
				.word	000000000000000000000100b  ;m
				.word	000000000000000000000101b  ;n
				.word	000000000000000000001000b  ;o
				.word	000000000000000000011001b  ;p
				.word	000000000000000000010010b  ;q
				.word	000000000000000000001101b  ;r
				.word	000000000000000000001111b  ;s
				.word	000000000000000000000010b  ;t
				.word	000000000000000000001110b  ;u
				.word	000000000000000000011110b  ;v
				.word	000000000000000000001100b  ;w
				.word	000000000000000000010110b  ;x
				.word	000000000000000000010100b  ;y
				.word	000000000000000000010011b  ;z
				.word	000000000000000000100000b  ;0
				.word	000000000000000000110000b  ;1
				.word	000000000000000000111000b  ;2
				.word	000000000000000000111100b  ;3
				.word	000000000000000000111110b  ;4
				.word	000000000000000000111111b  ;5
				.word	000000000000000000101111b  ;6
				.word	000000000000000000100111b  ;7
				.word	000000000000000000100011b  ;8
				.word	000000000000000000100001b  ;9

sDIG        .byte   0
			.byte   DIG4
			.byte   DIG3
			.byte   DIG2
			.byte   DIG1




;----------------------------------------------------------
; ISRssss
;----------------------------------------------------------

TIMER0_A0_ISR;    Timer0_A3 CC0 Interrupt Service Routine
;-------------------------------------------------------------------------------
			rlax.w mreg
            bit.b   #BTN3, &P1IFG
            jz		Dashinc
          ;  rlax.w mreg

          	jmp endtimer

Dashinc
			inc mreg


endtimer
			bic.b   #BTN3+BTN2,&P1IFG
			add.w   #12499,&TA0CCR0         ; Add offset to TA0CCR0
            clrc
            mov.w   #TASSEL__SMCLK+MC__STOP+BIT6+BIT7,&TA0CTL  ; SMCLK, stop mode, Div 8
	        reti

;-------------------------------------------------------------------------------
WDT_ISR;    WDT Interrupt Service Routine
;-------------------------------------------------------------------------------

Ghosting    bic.b #DIG1+DIG2+DIG3+DIG4+DIGCOL, &P3OUT
			bic.b #SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG+SEGDP,&P2OUT







DIG1Dis
		   bis.b	#DIG1, &P3OUT
		   bis.b  letters(display1), &P2OUT
		   mov.w #100, R15
count1	   dec R15
		   jnz count1

		   bic.b #DIG1+DIG2+DIG3+DIG4+DIGCOL, &P3OUT
		   bic.b #SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG+SEGDP,&P2OUT

DIG2Dis
		   bis.b	#DIG2, &P3OUT
		   bis.b  letters(display2), &P2OUT
		   mov.w #100, R15
count2	   dec R15
		   jnz count2

		   bic.b #DIG1+DIG2+DIG3+DIG4+DIGCOL, &P3OUT
		   bic.b #SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG+SEGDP,&P2OUT

DIG3Dis
		   bis.b	#DIG3, &P3OUT
		   bis.b  letters(display3), &P2OUT
		   mov.w #100, R15
count3	   dec R15
		   jnz count3


		   bic.b #DIG1+DIG2+DIG3+DIG4+DIGCOL, &P3OUT
		   bic.b #SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG+SEGDP,&P2OUT


DIG4Dis
		   bis.b	#DIG4, &P3OUT
		   bis.b  letters(display4), &P2OUT
		   mov.w #100, R15
count4	   dec R15
		   jnz count4

		   bic.b #DIG1+DIG2+DIG3+DIG4+DIGCOL, &P3OUT
		   bic.b #SEGA+SEGB+SEGC+SEGD+SEGE+SEGF+SEGG+SEGDP,&P2OUT
			reti






;---------------------------------------------------------------------------------------------------------------------

PORT1_ISR
			mov.w   #TASSEL__SMCLK+MC__CONTINOUS+BIT6+BIT7,&TA0CTL  ; SMCLK, continuous mode, Div 8
		;	bic.b   #BTN3+BTN2,&P1IFG
			reti


PORT4_ISR
			mov.w #0, count
top

			mov.w morsecode(count), temp
			cmp.w   temp , mreg
			jne notequ
			nop
			rra.w count
			nop
			inc disselect

			cmp.w   #1 , disselect
			jne di2

di1
			mov.w count, display1
			jmp btnend

di2

			cmp.w   #2 , disselect
			jne di3
			mov.w count, display2
			jmp btnend

di3
			cmp.w   #3 , disselect
			jne di4

			mov.w count, display3
			jmp btnend

di4



			mov.w count, display4
			mov.w #0,disselect
			jmp btnend


notequ
			inc count
			inc count
			cmp.w #80, count
			jlo	top

btnend
			mov.w #1, mreg
			bic.b   #BTN1,&P4IFG
			reti

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack

;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            .sect   WDT_VECTOR              ; Watchdog Timer
            .short  WDT_ISR
            .sect   TIMER0_A0_VECTOR        ; Timer0_A3 CC0 Interrupt Vector
            .short  TIMER0_A0_ISR
            .sect   PORT1_VECTOR        ; BTN3 Interrupt Vector
            .short  PORT1_ISR
            .sect   PORT4_VECTOR        ; BTN1 Interrupt Vector
            .short  PORT4_ISR
            .end


