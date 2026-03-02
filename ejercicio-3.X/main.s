;========================================================
; PIC18F4550 - 4 Secuencias LEDs Mejorado
; XC8 v3.x - pic-as
; RB0 = Cambia secuencia (INT0)
; RB1 = Cambia velocidad
; RD0-RD3 = LEDs
;========================================================

#include <xc.inc>

;--------------------------------------------------------
; CONFIG
;--------------------------------------------------------

CONFIG  FOSC = INTOSCIO_EC
CONFIG  WDT = OFF
CONFIG  LVP = OFF
CONFIG  PBADEN = OFF
CONFIG  MCLRE = OFF
CONFIG  XINST = OFF
CONFIG  PWRT = ON

;--------------------------------------------------------
; VARIABLES
;--------------------------------------------------------

PSECT udata_acs
Secuencia:  DS 1
Velocidad:  DS 1
Delay1:     DS 1
Delay2:     DS 1
Delay3:     DS 1
Direccion:  DS 1

;--------------------------------------------------------
; VECTORES
;--------------------------------------------------------

PSECT resetVec,class=CODE,reloc=2
ORG 0x00
GOTO INIT

PSECT intVec,class=CODE,reloc=2
ORG 0x08
GOTO ISR

;--------------------------------------------------------
; PROGRAMA
;--------------------------------------------------------

PSECT code

;========================================================
; INIT
;========================================================

INIT:

    MOVLW   0x72
    MOVWF   OSCCON

    MOVLW   0x0F
    MOVWF   ADCON1

    CLRF    Secuencia
    MOVLW   8          ; empieza lento
    MOVWF   Velocidad
    CLRF    Direccion

    CLRF    TRISD
    CLRF    LATD

    BSF     TRISB,0
    BSF     TRISB,1

    BCF     INTCON2,7      ; pullups ON
    BCF     INTCON2,6      ; flanco bajada INT0
    BCF     INTCON,1       ; limpia bandera
    BSF     INTCON,4       ; habilita INT0
    BSF     INTCON,7       ; global

;========================================================
; MAIN
;========================================================

MAIN:

    MOVF    Secuencia,W
    ANDLW   0x03
    MOVWF   Secuencia

    MOVF    Secuencia,W
    BZ      SEQ0

    MOVLW   1
    CPFSEQ  Secuencia
    GOTO    CHECK2
    GOTO    SEQ1

CHECK2:
    MOVLW   2
    CPFSEQ  Secuencia
    GOTO    SEQ3
    GOTO    SEQ2

;========================================================
; SECUENCIA 0 (Corrimiento simple)
;========================================================

SEQ0:
    MOVF    LATD,W
    ANDLW   0x0F
    BNZ     S0_CONT

    MOVLW   0x01
    MOVWF   LATD

S0_CONT:
    CALL    RETARDO
    RLCF    LATD,F
    MOVF    LATD,W
    ANDLW   0x0F
    MOVWF   LATD
    GOTO    MAIN

;========================================================
; SECUENCIA 1 (Ping Pong)
;========================================================

SEQ1:
    MOVF    LATD,W
    ANDLW   0x0F
    BNZ     S1_CONT

    MOVLW   0x01
    MOVWF   LATD

S1_CONT:
    CALL    RETARDO

    MOVF    Direccion,W
    BZ      IZQ

DER:
    RRCF    LATD,F
    BTFSC   LATD,0
    CLRF    Direccion
    GOTO    AJUSTE

IZQ:
    RLCF    LATD,F
    BTFSC   LATD,3
    MOVLW   1
    MOVWF   Direccion

AJUSTE:
    MOVF    LATD,W
    ANDLW   0x0F
    MOVWF   LATD
    GOTO    MAIN

;========================================================
; SECUENCIA 2 (Todos ON/OFF)
;========================================================

SEQ2:
    MOVLW   0x0F
    MOVWF   LATD
    CALL    RETARDO
    CLRF    LATD
    CALL    RETARDO
    GOTO    MAIN

;========================================================
; SECUENCIA 3 (Contador binario)
;========================================================

SEQ3:
    INCF    LATD,F
    MOVF    LATD,W
    ANDLW   0x0F
    MOVWF   LATD
    CALL    RETARDO
    GOTO    MAIN

;========================================================
; ISR INT0
;========================================================

ISR:
    BTFSS   INTCON,1
    RETFIE

    BCF     INTCON,1
    CALL    ANTIRREBOTE

    BTFSS   PORTB,0
    GOTO    CAMBIO
    RETFIE

CAMBIO:
    INCF    Secuencia,F
    CLRF    LATD
    RETFIE

;========================================================
; RETARDO PRINCIPAL (Visible)
;========================================================

RETARDO:

    ; Botón velocidad
    BTFSS   PORTB,1
    CALL    CAMBIAR_VEL

    MOVF    Velocidad,W
    MOVWF   Delay1

D1:
    MOVLW   255
    MOVWF   Delay2
D2:
    MOVLW   255
    MOVWF   Delay3
D3:
    DECFSZ  Delay3,F
    GOTO    D3

    DECFSZ  Delay2,F
    GOTO    D2

    DECFSZ  Delay1,F
    GOTO    D1

    RETURN

;========================================================
; CAMBIAR VELOCIDAD (1–10)
;========================================================

CAMBIAR_VEL:
    CALL    ANTIRREBOTE

    MOVF    Velocidad,W
    SUBLW   1
    BZ      RESETVEL

    DECF    Velocidad,F
    RETURN

RESETVEL:
    MOVLW   10
    MOVWF   Velocidad
    RETURN

;========================================================
; ANTIRREBOTE
;========================================================

ANTIRREBOTE:
    MOVLW   40
    MOVWF   Delay1
R1:
    MOVLW   255
    MOVWF   Delay2
R2:
    DECFSZ  Delay2,F
    GOTO    R2
    DECFSZ  Delay1,F
    GOTO    R1
    RETURN

END  