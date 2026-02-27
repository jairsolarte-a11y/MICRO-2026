        ;Ejercicio 1: Escribe un programa en el que se realice el parpadeo de un led de la siguiente
        ;forma, 1 segundo encendido y 2 segundos apagado.
	; primer paso el led parpadea, pero se ha ajustado los tiempo
	
	; tercer cambio
	
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

        ; (CAMBIO) Estado inicial: LED apagado (activo-alto)
        bcf     LED_LAT, LED_BIT, c

	; (CAMBIO) quitamos este call porque delay_off aún no existía y aquí no ayuda
	;call delay_off    ; aqui se controla linea agregada (1 cambio)
	
;===================================
;BUCLE INFINITO
;===============================================

blink:
        ;----------------------------------------
	;cambiar el estado del led
	;-----------------------------------------

        
        ; LED ON (activo-alto: 1 enciende)
        bsf     LED_LAT, LED_BIT, c
        call    delay_on          ; (AGREGO) 1 segundo aprox

        ; LED OFF (activo-alto: 0 apaga)
        bcf     LED_LAT, LED_BIT, c
        call    delay_off         ; (AGREGO) 2 segundos aprox

	;repeticion infinita
        goto    blink

;  parpadeo
	;=======================
	;cambio de codigo
	;===================================
	
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

;=========================================================
; (AGREGO) delays con relación 1s ON y 2s OFF (aproximado)
; - En esta etapa NO son exactos: se basan en delay_sw
; - delay_on  = 1 * delay_sw
; - delay_off = 2 * delay_sw
;=========================================================

delay_on:
        call    delay_sw
        return

delay_off:
        call    delay_sw
        call    delay_sw
        return

        END resetVec