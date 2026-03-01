;========================================================
; 4 Secuencias de LEDs con dos botones
; PIC18F4550 – 8 MHz interno
; RB0 cambia la secuencia
; RB1 aumenta la velocidad
; Los LEDs están conectados en RD0–RD3
; Inicio del progrma
	
;========================================================
;========================================================
; Dos secuencias básicas con botón RB0
; 1) movimiento de LEDs
; 2) Parpadeo de los leds
;========================================================

        #include <xc.inc>

       
        CONFIG  FOSC   = INTOSCIO_EC   ; Usamos el oscilador interno
        CONFIG  WDT    = OFF           ; Desactivamos el Watchdog
        CONFIG  LVP    = OFF           ; RB5 como pin normal
        CONFIG  PBADEN = OFF           ; PORTB inicia como digital
        CONFIG  MCLRE  = OFF           ; MCLR como entrada digital
        CONFIG  XINST  = OFF           ; Sin instrucciones extendidas
        CONFIG  PWRT   = ON            ; Encendido más estable

;--------------------------------------------------------
; Reservamos memoria para el retardo y la variable
; que controlará qué secuencia está activa.
;--------------------------------------------------------
        PSECT udata_acs
Delay1:    DS 1          ; Contador lento del retardo
Delay2:    DS 1          ; Contador rápido del retardo
Secuencia: DS 1          ; Guarda qué modo está activo

;--------------------------------------------------------
; Vector de inicio del programa
;--------------------------------------------------------
        PSECT resetVec,class=CODE,reloc=2
        ORG 0x00
        GOTO INIT

;========================================================
; Inicialización
;========================================================
INIT:

        ; Configuramos el oscilador interno a 8 MHz
        MOVLW   0b01110010
        MOVWF   OSCCON, a

        ; Configuramos todos los pines como digitales
        MOVLW   0x0F
        MOVWF   ADCON1, a

        ; PORTD como salida (donde están los LEDs)
        CLRF    TRISD, a
        CLRF    LATD, a

        ; RB0 como entrada (botón)
        BSF     TRISB,0,a

        ; Iniciamos en la secuencia 0
        CLRF    Secuencia, a

        ; Encendemos el primer LED como punto inicial
        MOVLW   0x01
        MOVWF   LATD, a

;========================================================
; Programa principal
;========================================================
MAIN:

        ; Si se presiona el botón RB0,
        ; cambiamos el valor de la variable Secuencia
        BTFSS   PORTB,0,a
        INCF    Secuencia,F,a

        ; Solo usamos el bit 0 de la variable,
        ; así alternamos entre 0 y 1 (dos modos)
        MOVF    Secuencia,W,a
        ANDLW   0x01
        BZ      SEQ0       ; Si es 0 → movimiento
        GOTO    SEQ1       ; Si es 1 → Parpadeo

;========================================================
; SECUENCIA 0 : movimiento  de LEDs
;========================================================
SEQ0:

        CALL RETARDO       ; Esperamos antes de mover

        ; Rotamos el contenido hacia la izquierda
        ; Esto mueve el LED encendido al siguiente
        RLCF LATD,F,a

        ; Si el corrimiento llega a RD4,
        ; reiniciamos en RD0
        BTFSC LATD,4,a
        MOVLW 0x01
        MOVWF LATD,a

        GOTO MAIN

;========================================================
; SECUENCIA 1 : Parpadeo 
;========================================================
SEQ1:

        ; Encendemos los 4 LEDs
        MOVLW 0x0F
        MOVWF LATD,a
        CALL RETARDO

        ; Apagamos todos
        CLRF LATD,a
        CALL RETARDO

        GOTO MAIN

;========================================================
; Se usan dos contadores anidados para generar una
; pausa visible sin usar temporizadores internos.
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