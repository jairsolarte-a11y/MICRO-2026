        PROCESSOR 18F4550
        #include <xc.inc>

        CONFIG  FOSC = INTOSCIO_EC
        CONFIG  WDT = OFF
        CONFIG  LVP = OFF
        CONFIG  PBADEN = OFF
        CONFIG  MCLRE = ON

#define LED_TRIS TRISD
#define LED_LAT  LATD
#define LED_BIT  0

PSECT resetVec, class=CODE, reloc=2
resetVec:
        goto    main

PSECT code, class=CODE, reloc=2
main:
        
        movlw   0x0F
        movwf   ADCON1, c

        ; RD0 salida
        bcf     LED_TRIS, LED_BIT, c

blink:
        ; LED (cambia de estado)
        btg     LED_LAT, LED_BIT, c

        ; 
        call    delay_sw

        goto    blink

;  parpadeo
delay_sw:
        movlw   0xFF
        movwf   0x20, c        ; usa una dirección en access RAM
d1:     movlw   0xFF
        movwf   0x21, c
d2:     decfsz  0x21, f, c
        goto    d2
        decfsz  0x20, f, c
        goto    d1
        return

        END resetVec