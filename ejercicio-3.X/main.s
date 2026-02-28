;========================================================
; 4 Secuencias de LEDs con dos botones
; PIC18F4550 – 8 MHz interno
; RB0 cambia la secuencia
; RB1 aumenta la velocidad
; Los LEDs están conectados en RD0–RD3
; Inicio del progrma
	
;========================================================
; LED parpadeando con retardo
;========================================================

        #include <xc.inc>     ; Librería del compilador para el PIC

        ; Configuración del microcontrolador
        CONFIG  FOSC   = INTOSCIO_EC   ; Usamos oscilador interno
        CONFIG  WDT    = OFF           ; Desactivamos Watchdog
        CONFIG  LVP    = OFF           ; Liberamos RB5 como pin digital
        CONFIG  PBADEN = OFF           ; PORTB inicia como digital
        CONFIG  MCLRE  = OFF           ; MCLR como entrada digital
        CONFIG  XINST  = OFF           ; Sin instrucciones extendidas
        CONFIG  PWRT   = ON            ; Encendido más estable

;--------------------------------------------------------
; Reservamos memoria para el retardo
; Mejora: ahora usamos variables en RAM para controlar
; el tiempo del parpadeo.
;--------------------------------------------------------
        PSECT udata_acs
Delay1: DS 1        ; Primer contador 
Delay2: DS 1        ; Segundo contador 

;--------------------------------------------------------
; Vector de reinicio
;--------------------------------------------------------
        PSECT resetVec,class=CODE,reloc=2
        ORG 0x00
        GOTO INIT

;========================================================
; Inicialización del sistema
;========================================================
INIT:

        ; Configuramos el oscilador interno 
        ; Esto define la velocidad de ejecución del programa
        MOVLW   0b01110010
        MOVWF   OSCCON, a

        ; Configuramos todos los pines como digitales
        MOVLW   0x0F
        MOVWF   ADCON1, a

        ; Configuramos todo PORTD como salida
        ; mejora: ahora iniciamos LATD para empezar apagado
        CLRF    TRISD, a
        CLRF    LATD, a

;========================================================
; Mejora: ahora usamos BSF y BCF para modificar solo
; el bit 0 sin afectar los demás pines del puerto.
;========================================================
MAIN:

        BSF     LATD,0,a     ; Encendemos el LED (RD0 = 1)
        CALL    RETARDO      

        BCF     LATD,0,a     ; Apagamos el LED (RD0 = 0)
        CALL    RETARDO      

        GOTO MAIN           

;========================================================
; Mejora : el tiempo se controla con
; contadores anidados, lo que permite generar una pausa
; visible sin usar temporizadores internos.
;========================================================
RETARDO:

        MOVLW   200          ; Valor inicial del contador 
        MOVWF   Delay1,a

D1:
        MOVLW   255          ; Valor inicial del contador rápido
        MOVWF   Delay2,a

D2:
        DECFSZ  Delay2,F,a   ; disminuye Delay2
        GOTO    D2           ; Si no es cero, sigue contando

        DECFSZ  Delay1,F,a   ; Cuando Delay2 llega a 0,
        GOTO    D1           ; disminuye Delay1 y repite

        RETURN               ; Cuando los dos llegan a 0, regresa

        END 