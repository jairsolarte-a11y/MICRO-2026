        ;=============================================================
        ;Ejercicio 1: Escribe un programa en el que se realice el parpadeo de un led de la siguiente
        ;forma, 1 segundo encendido y 2 segundos apagado.
        ;
        ; - Parpadeo usando Timer1 con tick fijo (10ms)
        ; - Solo se cambian valores de ON_TICKS y OFF_TICKS para variar tiempos
        ;=============================================================

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

       
#define TMR1_PRELOAD_H  0xF6
#define TMR1_PRELOAD_L  0x3C

        ;=============================================================
        ; TIEMPOS (EN TICKS DE 10ms)
        ; 
        ;   1s  = 100 ticks
        ;   2s  = 200 ticks
        ;=============================================================
#define ON_TICKS_H      0x00
#define ON_TICKS_L      0x64    ; 100

#define OFF_TICKS_H     0x00
#define OFF_TICKS_L     0xC8    ; 200


;===============================================================================
; reset
;===============================================================================
PSECT resetVec, class=CODE, reloc=2
resetVec:
        goto    main


;===============================================================================
; Variables (Access RAM)
;===============================================================================
PSECT udata_acs
cntH:   DS 1
cntL:   DS 1


;===============================================================================
; codigo principal
;===============================================================================
PSECT code, class=CODE, reloc=2

main:
        ;-------------------------------------------
        ; poner los pines analogicos como digitales
        ;-------------------------------------------
        movlw   0x0F
        movwf   ADCON1, c

        ;-------------------------------------------
        ; Oscilador interno 8MHz
        ;-------------------------------------------
        movlw   0x72
        movwf   OSCCON, c

wait_osc:
        btfss   OSCCON, 2, c       ; IOFS
        goto    wait_osc

        ;-------------------------------------------
        ; configurar el pin del led como salida
        ;-------------------------------------------
        ; RD0 salida
        bcf     LED_TRIS, LED_BIT, c

        ;-------------------------------------------
        ; estado inicial del led (apagado)
        ;-------------------------------------------
        bcf     LED_LAT, LED_BIT, c

        ;-------------------------------------------
     
        ;-------------------------------------------
        movlw   0xB0
        movwf   T1CON, c


;===================================
; BUCLE INFINITO
;===================================
blink:
        ;----------------------------------------
        ; LED encendido por 1 segundo (100 ticks)
        ;----------------------------------------
        bsf     LED_LAT, LED_BIT, c

        movlw   ON_TICKS_H
        movwf   cntH, c
        movlw   ON_TICKS_L
        movwf   cntL, c
        call    delay_ticks16

        ;----------------------------------------
        ; LED apagado por 2 segundos (200 ticks)
        ;----------------------------------------
        bcf     LED_LAT, LED_BIT, c

        movlw   OFF_TICKS_H
        movwf   cntH, c
        movlw   OFF_TICKS_L
        movwf   cntL, c
        call    delay_ticks16

        ;repeticion infinita
        goto    blink


;===============================================================================
; retardo por ticks (16-bit)
; - cntH:cntL = cantidad de ticks
; - 1 tick = 10ms (delay_10ms_timer1)
;===============================================================================
delay_ticks16:
        ;-------------------------------------------
        ; si el contador es 0, termina
        ;-------------------------------------------
        movf    cntH, w, c
        iorwf   cntL, w, c
        btfsc   STATUS, 2, c       ; Z=1
        return

dt_loop:
        ;-------------------------------------------
        ; retardo base (10ms)
        ;-------------------------------------------
        call    delay_10ms_timer1

        ;-------------------------------------------
        ; decremento 16-bit del contador cntH:cntL
        ;-------------------------------------------
        movf    cntL, w, c
        btfss   STATUS, 2, c       ; si cntL != 0
        goto    dec_low

        ; cntL == 0: borrow -> cntH-- y cntL = 0xFF
        decf    cntH, f, c
        movlw   0xFF
        movwf   cntL, c
        goto    dt_check

dec_low:
        decf    cntL, f, c

dt_check:
        ;-------------------------------------------
        ; mientras contador != 0, seguir
        ;-------------------------------------------
        movf    cntH, w, c
        iorwf   cntL, w, c
        btfss   STATUS, 2, c
        goto    dt_loop
        return


;===============================================================================
; delay_10ms con Timer1
; - preload -> overflow -> apaga timer
;===============================================================================
delay_10ms_timer1:
        ;-------------------------------------------
        ; preload del Timer1
        ;-------------------------------------------
        movlw   TMR1_PRELOAD_H
        movwf   TMR1H, c
        movlw   TMR1_PRELOAD_L
        movwf   TMR1L, c

        ;-------------------------------------------
     
        ;-------------------------------------------
        bcf     PIR1, 0, c

        ;-------------------------------------------
        ; encender Timer1
        ;-------------------------------------------
        bsf     T1CON, 0, c

wait_ov:
        ;-------------------------------------------
        ; esperar overflow
        ;-------------------------------------------
        btfss   PIR1, 0, c
        goto    wait_ov

        ;-------------------------------------------
        ; apagar Timer1
        ;-------------------------------------------
        bcf     T1CON, 0, c
        return

        END     resetVec