;========================================================================
; PRACTICA 1 - PUNTO 3
; PIC18F4550 - 4 Secuencias con botón usando INT0
; Oscilador interno 8 MHz
; Ensamblador: PIC-AS (XC8 v3.x)
;========================================================================

        processor PIC18F4550
        #include <xc.inc>

;========================
; CONFIGURACION
;========================

        CONFIG  FOSC = INTOSCIO_EC
        CONFIG  WDT = OFF
        CONFIG  LVP = OFF
        CONFIG  PBADEN = OFF
        CONFIG  MCLRE = OFF
        CONFIG  XINST = OFF
        CONFIG  PWRT = ON

;========================
; VARIABLES
;========================

PSECT udata
Secuencia: DS 1
Cont1:     DS 1
Cont2:     DS 1

;========================
; VECTOR RESET
;========================

PSECT resetVec,class=CODE,reloc=2
resetVec:
        goto INIT

;========================
; VECTOR INTERRUPCION
;========================

PSECT intVec,class=CODE,reloc=2
intVec:
        goto ISR

;========================
; CODIGO PRINCIPAL
;========================

PSECT code

INIT:
        movlw   b'01110010'
        movwf   OSCCON

        movlw   b'11110000'
        movwf   TRISD
        clrf    LATD

        bsf     TRISB,0
        bcf     INTCON2,6
        bcf     INTCON,1
        bsf     INTCON,4
        bsf     INTCON,7

        clrf    Secuencia

MAIN_LOOP:

        movf    Secuencia,W
        bz      SEQ0

        movlw   1
        cpfseq  Secuencia
        goto    SEQ1

        movlw   2
        cpfseq  Secuencia
        goto    SEQ2

        goto    SEQ3

;========================
; SECUENCIAS
;========================

SEQ0:
        movlw   b'00000001'
        movwf   LATD
        call    DELAY

        movlw   b'00000010'
        movwf   LATD
        call    DELAY

        movlw   b'00000100'
        movwf   LATD
        call    DELAY

        movlw   b'00001000'
        movwf   LATD
        call    DELAY

        goto    MAIN_LOOP

SEQ1:
        movlw   b'00001000'
        movwf   LATD
        call    DELAY

        movlw   b'00000100'
        movwf   LATD
        call    DELAY

        movlw   b'00000010'
        movwf   LATD
        call    DELAY

        movlw   b'00000001'
        movwf   LATD
        call    DELAY

        goto    MAIN_LOOP

SEQ2:
        movlw   b'00001111'
        movwf   LATD
        call    DELAY

        clrf    LATD
        call    DELAY
        goto    MAIN_LOOP

SEQ3:
        movlw   b'00000001'
        movwf   LATD
        call    DELAY

        movlw   b'00000011'
        movwf   LATD
        call    DELAY

        movlw   b'00000111'
        movwf   LATD
        call    DELAY

        movlw   b'00001111'
        movwf   LATD
        call    DELAY
        goto    MAIN_LOOP

;========================
; INTERRUPCION
;========================

ISR:
        btfss   INTCON,1
        retfie

        bcf     INTCON,1
        incf    Secuencia,F

        movlw   4
        cpfslt  Secuencia
        clrf    Secuencia

        retfie

;========================
; RETARDO
;========================

DELAY:
        movlw   0xFF
        movwf   Cont1
D1:
        movlw   0xFF
        movwf   Cont2
D2:
        decfsz  Cont2,F
        goto    D2
        decfsz  Cont1,F
        goto    D1
        return

        END