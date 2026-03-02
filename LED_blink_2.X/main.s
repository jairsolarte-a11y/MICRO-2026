        CONFIG  FOSC   = INTOSCIO_EC
        CONFIG  WDT    = OFF
        CONFIG  LVP    = OFF
        CONFIG  PBADEN = OFF
        CONFIG  MCLRE  = ON

        #include <xc.inc>

;================ RAM (Access Bank) =========================
        PSECT   udata_acs
cnt1:       ds  1        ; para delay_1ms
msL:        ds  1        ; contador 16-bit para ms (low)
msH:        ds  1        ; contador 16-bit para ms (high)
blinkCnt:   ds  1        ; contador de parpadeos

;================ Reset vector ==============================
        PSECT   resetVec,class=CODE,reloc=2
resetVec:
        goto    start

;================ Code ======================================
        PSECT   code,class=CODE,reloc=2
start:
        ;---- Oscilador interno 8 MHz ----
        BANKSEL OSCCON
        movlw   0x72              ; IRCF=111 (8MHz), SCS=10
        movwf   OSCCON, b

        ;---- Todo digital ----
        BANKSEL ADCON1
        movlw   0x0F
        movwf   ADCON1, b

        BANKSEL CMCON
        movlw   0x07
        movwf   CMCON, b

        ;---- LED en RB0 (salida) ----
        BANKSEL TRISB
        bcf     TRISB, 0, b

        BANKSEL LATB
        bcf     LATB, 0, b

;================ Main loop =================================
main_loop:
        call    blink_5x_1s       ; 5 parpadeos (1s ON/1s OFF) = 10s
        call    blink_2x_2s       ; 2 parpadeos (2s ON/2s OFF)
        goto    main_loop

;============================================================
;  Rutinas de parpadeo
;============================================================

;--- 5 parpadeos de 1s ON / 1s OFF ---
blink_5x_1s:
        movlw   5
        movwf   blinkCnt, a
b5_loop:
        call    blink_1s
        decfsz  blinkCnt, f, a
        goto    b5_loop
        return

;--- 2 parpadeos de 2s ON / 2s OFF ---
blink_2x_2s:
        movlw   2
        movwf   blinkCnt, a
b2_loop:
        call    blink_2s
        decfsz  blinkCnt, f, a
        goto    b2_loop
        return

;--- Un parpadeo: 1s ON, 1s OFF ---
blink_1s:
        BANKSEL LATB
        bsf     LATB, 0, b
        call    delay_1s
        BANKSEL LATB
        bcf     LATB, 0, b
        call    delay_1s
        return

;--- Un parpadeo: 2s ON, 2s OFF ---
blink_2s:
        BANKSEL LATB
        bsf     LATB, 0, b
        call    delay_2s
        BANKSEL LATB
        bcf     LATB, 0, b
        call    delay_2s
        return

;============================================================
;  Delays (software)
;============================================================

;--- delay_2s = 2 * delay_1s ---
delay_2s:
        call    delay_1s
        call    delay_1s
        return

;--- delay_1s = 1000 * delay_1ms (contador 16-bit) ---
delay_1s:
        movlw   0xE8          ; 1000 = 0x03E8
        movwf   msL, a
        movlw   0x03
        movwf   msH, a
d1s_loop:
        call    delay_1ms

        ; downcounter 16-bit (msH:msL)
        decfsz  msL, f, a
        goto    d1s_loop
        decfsz  msH, f, a
        goto    d1s_loop

        return

;--- delay ~1ms (aprox para 8MHz interno) ---
delay_1ms:
        movlw   250
        movwf   cnt1, a
d1ms_loop:
        nop
        nop
        nop
        nop
        decfsz  cnt1, f, a
        goto    d1ms_loop
        return

        END     resetVec