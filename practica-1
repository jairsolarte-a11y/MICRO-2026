PROCESSOR 18F4550
#include <xc.inc>

;====================
; RESET
;====================

PSECT resetVec,class=CODE,reloc=2
goto Inicio


;====================
; VARIABLES
;====================

PSECT udata_acs

Cont1: DS 1
Cont2: DS 1


;====================
; PROGRAMA
;====================

PSECT code

Inicio:

; Oscilador 8 MHz
MOVLW 0b01110000
MOVWF OSCCON

; Puerto B salida
CLRF TRISB
CLRF PORTB

Loop:

; LED ON
BSF PORTB,0

CALL Delay1s

; LED OFF
BCF PORTB,0

CALL Delay2s

GOTO Loop


;====================
; Delay 1 segundo
;====================

Delay1s:

MOVLW 0b11111111
MOVWF Cont1

L1:

MOVLW 0b11111111
MOVWF Cont2

L2:

NOP
NOP

DECFSZ Cont2,F
GOTO L2

DECFSZ Cont1,F
GOTO L1

RETURN


;====================
; Delay 2 segundos
;====================

Delay2s:

CALL Delay1s
CALL Delay1s

RETURN

END