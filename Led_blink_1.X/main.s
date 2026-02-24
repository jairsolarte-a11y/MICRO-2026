;===============================================================================
;  EJERCICIO A / EJERCICIO 1: LED BLINK


        PROCESSOR 18F4550
        #include <xc.inc>


; === LED ===
#define LED_TRIS        TRISD
#define LED_LAT         LATD
#define LED_BIT         0

; 0 = LED activo en ALTO  (1 enciende, 0 apaga)  
; 1 = LED activo en BAJO  (0 enciende, 1 apaga)  
#define LED_ACTIVE_LOW  0


#define USE_INTOSC      1

; Frecuencia 
#define FOSC_HZ         8000000


;-------------------------------------------------------------------------------
#define TMR1_PRELOAD_H  0xF6
#define TMR1_PRELOAD_L  0x3C


;-------------------------------------------------------------------------------


PSECT resetVec, class=CODE, reloc=2
resetVec:
        goto    main

; Variables en Access RAM 
PSECT udata_acs
cnt10ms:    DS 1

; Código principal
PSECT code, class=CODE, reloc=2

;===============================================================================
; main: Inicialización + bucle infinito 
;===============================================================================
main:
        ;---------------------------------------------------------------
        ; 1) Forzar pines analógicos a digitales (evita fallas típicas)
        ;    ADCON1=0x0F => pines ANx como digitales
        ;---------------------------------------------------------------
        movlw   0x0F
        movwf   ADCON1, c

        ;---------------------------------------------------------------
        ; 2) Configurar oscilador interno a 8 MHz (solo si USE_INTOSC=1)
       
        ;---------------------------------------------------------------
#if (USE_INTOSC == 1)
        movlw   0x72
        movwf   OSCCON, c

wait_osc:
        ; Esperar a que IOFS=1 (bit2) indique frecuencia estable
        btfss   OSCCON, 2, c
        goto    wait_osc
#endif

        ;---------------------------------------------------------------
        ; 3) Configurar pin del LED como salida
        
        ;---------------------------------------------------------------
        bcf     LED_TRIS, LED_BIT, c

        ;---------------------------------------------------------------
        ; 4) Inicializar LED apagado según polaridad
        ;---------------------------------------------------------------
#if (LED_ACTIVE_LOW == 1)
        bsf     LED_LAT, LED_BIT, c     ; activo-bajo: 1 apaga
#else
        bcf     LED_LAT, LED_BIT, c     ; activo-alto: 0 apaga
#endif

        ;---------------------------------------------------------------
        ; 5) Configurar Timer1:
        
        ;---------------------------------------------------------------
        movlw   0xB0
        movwf   T1CON, c

;===============================================================================
; Bucle principal: 1s ON, 2s OFF
;===============================================================================
loop:
        call    led_on
        call    delay_1s

        call    led_off
        call    delay_2s

        goto    loop

;===============================================================================
; Rutinas LED ON/OFF (maneja activo-alto o activo-bajo)
;===============================================================================
led_on:
#if (LED_ACTIVE_LOW == 1)
        bcf     LED_LAT, LED_BIT, c     ; activo-bajo: 0 enciende
#else
        bsf     LED_LAT, LED_BIT, c     ; activo-alto: 1 enciende
#endif
        return

led_off:
#if (LED_ACTIVE_LOW == 1)
        bsf     LED_LAT, LED_BIT, c     ; activo-bajo: 1 apaga
#else
        bcf     LED_LAT, LED_BIT, c     ; activo-alto: 0 apaga
#endif
        return

;===============================================================================
; delay_1s: 1 segundo = 100 * 10ms
;===============================================================================
delay_1s:
        movlw   100
        movwf   cnt10ms, c
d1:
        call    delay_10ms
        decfsz  cnt10ms, f, c
        goto    d1
        return

;===============================================================================
; delay_2s: 2 segundos = 200 * 10ms
;===============================================================================
delay_2s:
        movlw   200
        movwf   cnt10ms, c
d2:
        call    delay_10ms
        decfsz  cnt10ms, f, c
        goto    d2
        return

;===============================================================================
; delay_10ms: retardo base usando Timer1 (~10ms)

;===============================================================================
delay_10ms:
        ; 1) preload
        movlw   TMR1_PRELOAD_H
        movwf   TMR1H, c
        movlw   TMR1_PRELOAD_L
        movwf   TMR1L, c

        ; 2) clear overflow flag (TMR1IF = PIR1,0)
        bcf     PIR1, 0, c

        ; 3) Timer1 ON
        bsf     T1CON, 0, c

wait_ov:
        ; 4) esperar overflow
        btfss   PIR1, 0, c
        goto    wait_ov

        ; 5) Timer1 OFF
        bcf     T1CON, 0, c
        return

        END     resetVec