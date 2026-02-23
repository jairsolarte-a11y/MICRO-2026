#include <xc.inc>                 ; Incluye definiciones de registros/bits para el PIC seleccionado (PIC18F4550)

;============================================================

PSECT udata_acs                   ; Sección de datos en “Access RAM”
blinkCnt:   DS 1                  ; Reservar 1 byte: contador de parpadeos (5 o 2)
ovfCnt:     DS 1                  ; Reservar 1 byte: contador de overflows de Timer1


PSECT resetVec, class=CODE, reloc=2 ; Sección de código para el vector de reset
resetVec:
    GOTO main                     

;------------------------
; código
;------------------------
PSECT code                        

main:
    
    MOVLW 0x72                    
    MOVWF OSCCON, a               

    MOVLW 0x0F                    ; WREG = 0x0F
    MOVWF ADCON1, a               ; ADCON1 = 0x0F (todo digital)

    ;--------------------------------------------------------
    ; Configurar RB0 como salida para el LED
    ;--------------------------------------------------------
    CLRF LATB, a                  ; LATB = 0 (apaga todo PORTB para iniciar seguro)
    BCF  TRISB, 0, a              ; TRISB0 = 0 -> RB0 es SALIDA (0 salida, 1 entrada)

    ;--------------------------------------------------------
    ;  Configurar Timer1 para hacer delays
    ;--------------------------------------------------------
    
    MOVLW 0xB0                    ; 0xB0 = 1011 0000b (RD16=1, presc=1:8, off)
    MOVWF T1CON, a                ; T1CON = 0xB0

;============================================================
; Bucle principal
;============================================================
MainLoop:
    ;--------------------------------------------------------
    ; FASE A: 5 parpadeos de 1 segundo ON + 1 segundo OFF
    
    ;--------------------------------------------------------
    MOVLW 5                       ; WREG = 5
    MOVWF blinkCnt, a             ; blinkCnt = 5 (contador de repeticiones)

Blink1s:
    BSF  LATB, 0, a               ; LATB0 = 1 -> LED ON
    CALL Delay1s                  ; Esperar 1 segundo
    BCF  LATB, 0, a               ; LATB0 = 0 -> LED OFF
    CALL Delay1s                  ; Esperar 1 segundo

    DECFSZ blinkCnt, f, a         ; blinkCnt = blinkCnt - 1; si llega a 0, salta la próxima instrucción
    BRA Blink1s                   ; Si NO llegó a 0, repetir otro parpadeo

    ;--------------------------------------------------------
    ; FASE B: 2 parpadeos de 2 segundos ON + 2 segundos OFF
    ;--------------------------------------------------------
    MOVLW 2                       ; WREG = 2
    MOVWF blinkCnt, a             ; blinkCnt = 2

Blink2s:
    BSF  LATB, 0, a               ; LED ON
    CALL Delay2s                  ; Esperar 2 segundos
    BCF  LATB, 0, a               ; LED OFF
    CALL Delay2s                  ; Esperar 2 segundos

    DECFSZ blinkCnt, f, a         ; Decrementa contador y verifica cero
    BRA Blink2s                   ; Si no es cero, repetir

    BRA MainLoop                  ; Regresa al inicio de la secuencia (bucle infinito)

;============================================================
; Delay1s:
; Genera 1 segundo exacto usando Timer1 (polling, sin interrupciones)
;
; Parámetros del tiempo:
;  Fosc = 8 MHz
;  Finst = Fosc/4 = 2 MHz
;  Prescaler 1:8 -> tick = 2MHz/8 = 250k ticks/seg
;  Periodo tick = 4 us
;  1 s = 250,000 ticks
;
; Estrategia:
;  - Cargamos TMR1 con un valor inicial (precarga) para que el
;    primer overflow ocurra tras cierta cantidad de ticks.
;  - Luego esperamos 3 overflows completos adicionales.
;

;  Conteo hasta overflow = 65536 - 0x2F70 = 53392 ticks
;  Tiempo = 53392 * 4us = 0.213568s
;  Faltante hasta 1s = 1 - 0.213568 = 0.786432s
;  Cada overflow completo = 65536 ticks = 0.262144s
;  3 overflows = 0.786432s
;  Total = 1.000000s exacto
;============================================================
Delay1s:
    BCF  T1CON, 0, a              ; bit0 (TMR1ON)=0 -> apaga Timer1 para cargar TMR1H/TMR1L

    MOVLW 0x2F                    ; WREG = 0x2F (byte alto de precarga)
    MOVWF TMR1H, a                ; TMR1H = 0x2F
    MOVLW 0x70                    ; WREG = 0x70 (byte bajo de precarga)
    MOVWF TMR1L, a                ; TMR1L = 0x70

    BCF  PIR1, 0, a               ; PIR1 bit0 (TMR1IF)=0 -> limpia bandera de overflow de Timer1
    BSF  T1CON, 0, a              ; TMR1ON=1 -> enciende Timer1 y empieza a contar

;--- Esperar el primer overflow (parcial desde 0x2F70 hasta 0xFFFF) ---
D1_First:
    BTFSS PIR1, 0, a              ; ¿TMR1IF=1? (si está en 1, hubo overflow)
    BRA   D1_First                ; Si aún no overflow, seguir esperando (polling)
    BCF   PIR1, 0, a              ; Limpia TMR1IF para contar el siguiente overflow

;--- Esperar 3 overflows completos 
    MOVLW 3                       ; WREG = 3
    MOVWF ovfCnt, a               ; ovfCnt = 3 (contador de overflows completos)

D1_Full:
    BTFSS PIR1, 0, a              ; ¿Ya overflow?
    BRA   D1_Full                 ; No -> esperar
    BCF   PIR1, 0, a              ; Sí -> limpia bandera

    DECFSZ ovfCnt, f, a           ; ovfCnt-- ; si llegó a 0, salir
    BRA   D1_Full                 ; Si faltan overflows, repetir espera

    BCF  T1CON, 0, a              ; Apaga Timer1 (buena práctica)
    RETURN                        ; Regresa a la rutina que llamó Delay1s

;============================================================
; Delay2s:
; Similar a Delay1s, pero total = 2 segundos exactos
;
; 2 s = 500,000 ticks (con tick=4us)
;
; Precarga 0x5EE0:
;  Conteo hasta overflow = 65536 - 0x5EE0 = 41248 ticks
;  Tiempo parcial = 41248*4us = 0.164992s
;  Overflows completos necesarios: 7 * 0.262144s = 1.835008s
;  Total = 0.164992 + 1.835008 = 2.000000s exacto
;============================================================
Delay2s:
    BCF  T1CON, 0, a              ; Apaga Timer1 para cargar precarga

    MOVLW 0x5E                    ; Byte alto precarga
    MOVWF TMR1H, a                ; Carga TMR1H
    MOVLW 0xE0                    ; Byte bajo precarga
    MOVWF TMR1L, a                ; Carga TMR1L

    BCF  PIR1, 0, a               ; Limpia bandera TMR1IF
    BSF  T1CON, 0, a              ; Enciende Timer1

;--- Primer overflow parcial ---
D2_First:
    BTFSS PIR1, 0, a              ; Esperar TMR1IF=1
    BRA   D2_First
    BCF   PIR1, 0, a              ; Limpia bandera

;--- 7 overflows completos ---
    MOVLW 7                       ; WREG=7
    MOVWF ovfCnt, a               ; ovfCnt=7

D2_Full:
    BTFSS PIR1, 0, a              ; ¿Overflow?
    BRA   D2_Full                 ; No -> esperar
    BCF   PIR1, 0, a              ; Sí -> limpiar

    DECFSZ ovfCnt, f, a           ; ovfCnt-- y si es 0 sale
    BRA   D2_Full

    BCF  T1CON, 0, a              ; Apaga Timer1
    RETURN                        ; Retorna

END resetVec                      ; Fin del programa (indica el punto de entrada/reset)