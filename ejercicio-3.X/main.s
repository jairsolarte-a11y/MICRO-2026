;========================================================
; 4 Secuencias de LEDs con dos botones
; PIC18F4550 – 8 MHz interno
; RB0 cambia la secuencia
; RB1 aumenta la velocidad
; Los LEDs están conectados en RD0–RD3
; Inicio del progrma
	
;========================================================
;========================================================
; Cambio de secuencia usando interrupción INT0 (RB0)
; El botón cambia entre:
;   SEQ0 : Corrimiento de LEDs
;   SEQ1 : Parpadeo total
;========================================================

        #include <xc.inc>

;--------------------------------------------------------
; CONFIGURACIÓN DEL PIC
;--------------------------------------------------------
        CONFIG  FOSC   = INTOSCIO_EC   ; Oscilador interno
        CONFIG  WDT    = OFF           ; Watchdog desactivado
        CONFIG  LVP    = OFF           ; RB5 como pin digital
        CONFIG  PBADEN = OFF           ; PORTB digital
        CONFIG  MCLRE  = OFF           ; MCLR como pin normal
        CONFIG  XINST  = OFF           ; Sin instrucciones extendidas
        CONFIG  PWRT   = ON            ; Encendido más estable

;--------------------------------------------------------
; VARIABLES EN RAM
;--------------------------------------------------------
        PSECT udata_acs
Delay1:    DS 1          ; Contador lento del retardo
Delay2:    DS 1          ; Contador rápido del retardo
Secuencia: DS 1          ; Guarda el modo activo (0 o 1)

;--------------------------------------------------------
; VECTOR DE RESET
;--------------------------------------------------------
        PSECT resetVec,class=CODE,reloc=2
        ORG 0x00
        GOTO INIT

;--------------------------------------------------------
; VECTOR DE INTERRUPCIÓN (INT0 está en 0x08)
;--------------------------------------------------------
        PSECT intVec,class=CODE,reloc=2
        ORG 0x08
        GOTO ISR

;========================================================
; INICIALIZACIÓN
;========================================================
INIT:

        ; Configuramos oscilador a 8 MHz
        MOVLW   0b01110010
        MOVWF   OSCCON, a

        ; Todos los pines digitales
        MOVLW   0x0F
        MOVWF   ADCON1, a

        ; PORTD como salida (LEDs)
        CLRF    TRISD, a
        CLRF    LATD, a

        ; RB0 como entrada (botón INT0)
        BSF     TRISB,0,a

        ; Iniciamos en secuencia 0
        CLRF    Secuencia, a

        ; Encendemos LED inicial
        MOVLW   0x01
        MOVWF   LATD, a

;--------------------------------------------------------
; CONFIGURACIÓN DE INT0
;--------------------------------------------------------

        BCF     INTCON2,6,a   ; Interrupción por flanco descendente
        BCF     INTCON,1,a    ; Limpiamos bandera INT0IF
        BSF     INTCON,4,a    ; Habilitamos INT0IE
        BSF     INTCON,7,a    ; Habilitamos interrupciones globales

;========================================================
; PROGRAMA PRINCIPAL
;========================================================
MAIN:

        ; Revisamos qué secuencia está activa
        MOVF    Secuencia,W,a
        ANDLW   0x01
        BZ      SEQ0
        GOTO    SEQ1

;========================================================
; SECUENCIA 0 → Corrimiento de LEDs RD0-RD3
;========================================================
SEQ0:

        CALL    RETARDO

        ; Rotamos hacia la izquierda
        RLCF    LATD,F,a

        ; Si se sale del rango (llega a RD4)
        ; reiniciamos en 0001
        BTFSC   LATD,4,a
        MOVLW   0x01
        MOVWF   LATD,a

        GOTO    MAIN

;========================================================
; SECUENCIA 1 → Parpadeo total
;========================================================
SEQ1:

        MOVLW   0x0F        ; Encendemos RD0-RD3
        MOVWF   LATD,a
        CALL    RETARDO

        CLRF    LATD,a      ; Apagamos todos
        CALL    RETARDO

        GOTO    MAIN

;========================================================
; RUTINA DE INTERRUPCIÓN
; Se ejecuta automáticamente cuando se presiona RB0
;========================================================
ISR:

        ; Verificamos que sea INT0
        BTFSS   INTCON,1,a
        RETFIE

        ; Limpiamos bandera
        BCF     INTCON,1,a

        ; Cambiamos de secuencia
        INCF    Secuencia,F,a

        RETFIE

;========================================================
; SUBRUTINA DE RETARDO POR SOFTWARE
;========================================================
RETARDO:

        MOVLW   200
        MOVWF   Delay1,a

D1:
        MOVLW   255
        MOVWF   Delay2,a
D2:
        DECFSZ  Delay2,F,a
        GOTO    D2
        DECFSZ  Delay1,F,a
        GOTO    D1

        RETURN

        END 