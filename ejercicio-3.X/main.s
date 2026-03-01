;========================================================
; 4 Secuencias de LEDS con dos botones
; PIC18F4550 – 8 MHz interno
; RB0 cambia la secuencia
; RB1 aumenta la velocidad
; Los LEDS están conectados en RD0–RD3
;========================================================

        #include <xc.inc>

;--------------------------------------------------------
; Configuración básica del micro
; Aquí le decimos cómo debe arrancar
;--------------------------------------------------------

        CONFIG  FOSC   = INTOSCIO_EC   ; Usamos el oscilador interno
        CONFIG  WDT    = OFF           ; Quitamos el Watchdog
        CONFIG  LVP    = OFF           ; Sin programación a bajo voltaje
        CONFIG  PBADEN = OFF           ; PORTB como digital
        CONFIG  MCLRE  = OFF           ; MCLR como pin digital
        CONFIG  XINST  = OFF
        CONFIG  PWRT   = ON            ; Pequeña espera al encender

;--------------------------------------------------------
; Variables en RAM
;--------------------------------------------------------

        PSECT udata_acs

Secuencia: DS 1      ; Guarda qué efecto está activo (0–3)
Velocidad: DS 1      ; Controla qué tan rápido se mueven los LEDS
Delay1:    DS 1      ; Variables internas del retardo
Delay2:    DS 1
Direccion: DS 1      ; 0 = izquierda, 1 = derecha (para rebote)

;--------------------------------------------------------
; Vectores importantes
;--------------------------------------------------------

        PSECT resetVec,class=CODE,reloc=2
        ORG 0x00
        GOTO INIT     ; Cuando el PIC enciende viene aquí

        PSECT intVec,class=CODE,reloc=2
        ORG 0x08
        GOTO ISR      ; Si ocurre INT0 viene aquí

;========================================================
; Inicialización
;========================================================

INIT:

        ; Configuramos el oscilador interno a 8 MHz
        MOVLW   0b01110010
        MOVWF   OSCCON, a

        ; Nos aseguramos de que todo sea digital
        MOVLW   0x0F
        MOVWF   ADCON1, a

        ; Empezamos en la secuencia 0
        CLRF    Secuencia, a

        ; Velocidad inicial media
        MOVLW   5
        MOVWF   Velocidad, a

        ; Dirección inicial hacia la izquierda
        CLRF    Direccion, a

        ; PORTD como salida (ahí están los LEDs)
        CLRF    TRISD, a
        CLRF    LATD, a      ; Todos apagados al inicio

        ; Configuramos los botones
        BSF     TRISB,0,a    ; RB0 como entrada (INT0)
        BSF     TRISB,1,a    ; RB1 como entrada (velocidad)

        ; Configuración de la interrupción INT0
        BCF     INTCON2,6,a  ; Interrupción por flanco de bajada
        BCF     INTCON,1,a   ; Limpiamos bandera
        BSF     INTCON,4,a   ; Habilitamos INT0
        BSF     INTCON,7,a   ; Habilitamos interrupciones globales

;========================================================
; Bucle principal
;========================================================

MAIN:

        ; Miramos qué secuencia está activa
        MOVF    Secuencia,W,a
        ANDLW   0x03         ; Solo permitimos valores de 0 a 3

        ; Dependiendo del valor saltamos al efecto
        BZ      SEQ0
        DECF    WREG,W
        BZ      SEQ1
        DECF    WREG,W
        BZ      SEQ2
        GOTO    SEQ3

;========================================================
; SECUENCIA 0 – Corrimiento hacia la izquierda continuo
;========================================================

SEQ0:
        ; Si todos están apagados empezamos con el primero
        MOVF    LATD,W,a
        BNZ     CONT0
        MOVLW   0x01
        MOVWF   LATD,a

CONT0:
        CALL    RETARDO      ; Esperamos un poco
        RLCF    LATD,F,a     ; Movemos el LED a la izquierda
        GOTO    MAIN

;========================================================
; SECUENCIA 1 – Rebote tipo ping-pong
;========================================================

SEQ1:
        ; Si está apagado, iniciamos en el primero
        MOVF    LATD,W,a
        BNZ     CONT1
        MOVLW   0x01
        MOVWF   LATD,a

CONT1:
        CALL    RETARDO

        ; Revisamos la dirección
        MOVF    Direccion,W,a
        BZ      IZQUIERDA

DERECHA:
        RRCF    LATD,F,a
        ; Si llegó al primer LED cambiamos dirección
        BTFSC   LATD,0,a
        CLRF    Direccion,a
        GOTO    MAIN

IZQUIERDA:
        RLCF    LATD,F,a
        ; Si llegó al último LED cambiamos dirección
        BTFSC   LATD,3,a
        MOVLW   1
        MOVWF   Direccion,a
        GOTO    MAIN

;========================================================
; SECUENCIA 2 – Parpadeo total
;========================================================

SEQ2:
        MOVLW   0x0F         ; Encendemos todos
        MOVWF   LATD,a
        CALL    RETARDO

        CLRF    LATD,a       ; Apagamos todos
        CALL    RETARDO
        GOTO    MAIN

;========================================================
; SECUENCIA 3 – Conteo binario
;========================================================

SEQ3:
        INCF    LATD,F,a     ; Sumamos 1 al valor mostrado
        CALL    RETARDO
        GOTO    MAIN

;========================================================
; Interrupción – Cambio de secuencia
;========================================================

ISR:
        ; Verificamos que realmente fue INT0
        BTFSS   INTCON,1,a
        RETFIE

        BCF     INTCON,1,a   ; Limpiamos
        INCF    Secuencia,F,a ; Pasamos a la siguiente secuencia

        RETFIE               ; Volvemos al programa principal

;========================================================
; Retardo con control de velocidad
;========================================================

RETARDO:

        ; Si se presiona RB1 aumentamos velocidad (máx 10)
        BTFSS   PORTB,1,a
        CALL    AUMENTAR

        MOVF    Velocidad,W,a
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

;--------------------------------------------------------
; Aumenta velocidad hasta un límite
;--------------------------------------------------------

AUMENTAR:
        MOVF    Velocidad,W,a
        SUBLW   10
        BZ      SALIR        ; Si ya está en 10 no sube más
        INCF    Velocidad,F,a
SALIR:
        RETURN

        END 