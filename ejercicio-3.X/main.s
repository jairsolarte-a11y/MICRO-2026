;========================================================
; 4 Secuencias de LEDs con dos botones
; PIC18F4550 – 8 MHz interno
; RB0 cambia la secuencia
; RB1 aumenta la velocidad
; Los LEDs están conectados en RD0–RD3
; Inicio del progrma
	
;========================================================

        #include <xc.inc>     ; libreria del el PIC 18F4550

        ; Configuración básica del microcontrolador
        CONFIG FOSC   = INTOSCIO_EC    ;  Usamos el oscilador interno
        CONFIG  WDT    = OFF           ;  Desactivamos el Watchdog (temporizador)
        CONFIG  LVP    = OFF           ;  Desactivamos programación en bajo voltaje
        CONFIG  PBADEN = OFF           ;  PORTB inicia como digital
        CONFIG  MCLRE  = OFF           ;  El pin MCLR se usa como entrada digital
        CONFIG  XINST  = OFF           ;  Desactivamos instrucciones extendidas
        CONFIG  PWRT   = ON            ;  Activamos temporizador de encendido (más estable)

        ; Vector de reinicio
        PSECT resetVec,class=CODE,reloc=2
        ORG 0x00              ; Dirección inicial del programa
        GOTO INIT             ; Saltamos a la rutina principal

;========================================================
; Inicio del programa
;========================================================
INIT:

        ; Configuramos el oscilador interno a 8 MHz
        ; Esto define la velocidad a la que trabajará el PIC
        MOVLW   0b01110010
        MOVWF   OSCCON, a

        ; Configuramos todos los pines como digitales
        ; Así evitamos que funcionen como entradas analógicas
        MOVLW   0x0F
        MOVWF   ADCON1, a

        ; Configuramos todo el PORTD como salida
        ; TRISD = 0 significa salida
        CLRF    TRISD, a

        ; Encendemos el LED conectado en RD0
        ; Escribimos un 1 en el bit 0 del puerto D
        MOVLW   0x01
        MOVWF   LATD, a

;========================================================
; Bucle infinito
;========================================================
LOOP:
        GOTO LOOP     ; El programa se queda aquí para mantener el LED encendido

        END 