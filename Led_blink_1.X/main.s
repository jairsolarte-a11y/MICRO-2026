        ;Ejercicio 1: Escribe un programa en el que se realice el parpadeo de un led de la siguiente
        ;forma, 1 segundo encendido y 2 segundos apagado.
	; primer paso el led parpadea, pero se ha ajustado los tiempo
	PROCESSOR 18F4550
        #include <xc.inc>

	; Estos "CONFIG" definen cómo arranca el PIC 
        CONFIG  FOSC = INTOSCIO_EC 
        CONFIG  WDT = OFF  
        CONFIG  LVP = OFF
        CONFIG  PBADEN = OFF
        CONFIG  MCLRE = ON

#define LED_TRIS TRISD
#define LED_LAT  LATD
#define LED_BIT  0

	;reset
PSECT resetVec, class=CODE, reloc=2
resetVec:
        goto    main
	
;================================================
;codigo pincipal
;=============================================

PSECT code, class=CODE, reloc=2
main:
        ;-------------------------------------------
	; poner los pines analogicos como digitales
	;----------------------------------------------
        
        movlw   0x0F
        movwf   ADCON1, c

	;-----------------------------------
	; configurar el pin del led como salida
	;-----------------------------------------------
        ; RD0 salida
        bcf     LED_TRIS, LED_BIT, c
	
;===================================
;BUCLE INFINITO
;===============================================

blink:
        ;----------------------------------------
	;cambiar el estado del led
	;-----------------------------------------
        ; LED (cambia de estado)
        btg     LED_LAT, LED_BIT, c

        ;----------------------------------------
	;retardo por software
	;-----------------------------------------
	; el parpadeo es visible en led
        call    delay_sw

	;repeticion infinita
        goto    blink

;  parpadeo
delay_sw:
        ;-------------------------------------------------
	;cargar contador externo
	;----------------------------------
        movlw   0xFF
        movwf   0x20, c        ; usa una dirección en access RAM

	;------------------------------
	;cargar el cargador interno
	;-----------------------------------
d1:     movlw   0xFF
        movwf   0x21, c
	
	;---------------------------------------
	;bucle interno
	;--------------------------------
d2:     decfsz  0x21, f, c    ;decrementa; si queda en 0satlta la siguiente instruccion 
        goto    d2            ; si no llego a 0, sigue dando vueltas
       
	;---------------------------------------------------------------
	;cuando el contador llega a 0, decrementa contador 1
	;-------------------------------------------------------------
	decfsz  0x20, f, c
        goto    d1        ;si contador1 no llegó a 0, repite otro ciclo completo
       
	 ;-----------------------------------------------------------
        ; 5) Ambos contadores llegaron a 0 => termina el retardo
        ;------------------------------------------------------------
	return

        END resetVec