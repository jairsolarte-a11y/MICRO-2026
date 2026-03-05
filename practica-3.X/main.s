;=========================================================
; Código en Assembler para PIC18F4550
; practica led sequence + boton de retroceso 
; Frecuencia: 8 MHz (Oscilador Interno)
;=========================================================
 
#include <xc.inc>             

;======================
; BITS DE CONFIGURACIÓN 
;======================

CONFIG  FOSC = INTOSCIO_EC   ; Oscilador interno
CONFIG  WDT = OFF            ; Desactiva Watchdog Timer
CONFIG  LVP = OFF            ; Desactiva programación en bajo voltaje
CONFIG  PBADEN = OFF         ; PORTB inicia como digital
CONFIG  MCLRE = OFF          ; Desactiva pin MCLR externo
CONFIG  XINST = OFF          ; Usa instrucciones normales
CONFIG  PWRT = ON            ; Activa temporizador de encendido


;======================
; SE DECLARAN VARIABLES 
;======================

PSECT udata_acs              ; Sección donde se guardan variables

Secuencia:  DS 1             ; Guarda número de secuencia (0-3)
Velocidad:  DS 1             ; 0=lenta, 1=media, 2=rapida
Direccion:  DS 1             ; Control de rebote izquierda/derecha
BtnBack:    DS 1             ; Control de retroceso
BtnState:   DS 1             ; Control lógico para anti-rebote
Delay1:     DS 1             ; Contador externo del retardo
Delay2:     DS 1             ; Contador intermedio del retardo
Delay3:     DS 1             ; Contador interno del retardo 


;======================
; VECTOR DE RESET
;======================

PSECT resetVec,class=CODE,reloc=2
ORG 0x00                     ; Dirección donde inicia el programa
    GOTO INIT                ; Salta a la inicialización

    PSECT code

;======================
; VECTOR DE INTERRUPCIÓN
;======================

PSECT intVec,class=CODE,reloc=2
ORG 0x08                     ; Dirección del vector de interrupción
    GOTO ISR                 ; Salta a la rutina de interrupción


;======================
; CÓDIGO PRINCIPAL
;======================

PSECT code


;======================
; INICIALIZACIÓN
;======================

INIT:

    MOVLW   0b01110010       ; 8 MHz interno
    MOVWF   OSCCON           ; Configura el oscilador

    MOVLW   0b00001111       ; Todos los pines como digitales 
    MOVWF   ADCON1           ; Desactiva entradas analógicas

    CLRF    Secuencia        ; Inicia en secuencia 0
    CLRF    Velocidad        ; Inicia en velocidad lenta
    CLRF    Direccion        ; Dirección inicial izquierda
    MOVLW   0b00000001
    MOVWF   BtnState         ; Botón inicia liberado
    MOVLW   0b00000001
    MOVWF   BtnBack          ; Botón de retroceso

    CLRF    TRISD            ; PORTD como salida
    CLRF    LATD             ; Apaga todos los LEDs
    MOVLW   0b00000001
    MOVWF   LATD             ; Enciende LED RD0 al inicio

    BSF     TRISB,0          ; RB0 como entrada
    BSF     TRISB,1          ; RB1 como entrada
    BSF     TRISB,2          ; RB2 como entrada 
    
    BCF     INTCON2,7        ; Activa pull-ups internos
    BCF     INTCON2,6        ; INT0 por flanco descendente
    BCF     INTCON,1         ; Limpia bandera INT0
    BSF     INTCON,4         ; Habilita INT0
    BSF     INTCON,7         ; Habilita interrupciones globales


;======================
; BUCLE PRINCIPAL
;======================

MAIN:

    CALL    CHECK_VEL        ; Revisa botón de velocidad

    MOVF    Secuencia,W      ; Pasa Secuencia a W
    ANDLW   0b00000011       ; Limita valor entre 0 y 3
    MOVWF   Secuencia        ; Guarda valor corregido

    MOVF    Secuencia,W
    BZ      SEQ0             ; Si es 0 → SEQ0

    MOVLW   0b00000001
    CPFSEQ  Secuencia
    GOTO    CHECK2
    GOTO    SEQ1             ; Si es 1 → SEQ1

CHECK2:
    MOVLW   0b00000010
    CPFSEQ  Secuencia
    GOTO    SEQ3             ; Si no es 2 → SEQ3
    GOTO    SEQ2             ; Si es 2    → SEQ2


;======================
; SECUENCIA 00
;======================

SEQ0:
    CALL    RETARDO
    RLCF    LATD,F           ; Rota LEDs hacia la izquierda
    MOVF    LATD,W
    ANDLW   0b00001111       ; Solo usa RD0-RD3
    BNZ     S0_OK
    MOVLW   0b00000001       ; Si quedó en 0 reinicia
    MOVWF   LATD
S0_OK:
    GOTO    MAIN


;======================
; SECUENCIA 01
;======================

SEQ1:
    CALL    RETARDO
    MOVF    Direccion,W
    BZ      LEFT             ; Si Direccion=0 va izquierda

RIGHT:
    RRCF    LATD,F           ; Rota derecha
    BTFSC   LATD,0           ; Si llegó a RD0
    CLRF    Direccion        ; Cambia dirección
    GOTO    MAIN

LEFT:
    RLCF    LATD,F           ; Rota izquierda
    BTFSC   LATD,3           ; Si llegó a RD3
    MOVLW   0b00000001
    MOVWF   Direccion        ; Cambia dirección
    GOTO    MAIN


;======================
; SECUENCIA 02
;======================
 
SEQ2:
    CALL    RETARDO
    MOVLW   0b00001111
    XORWF   LATD,F           ; Invierte los 4 LEDs
    GOTO    MAIN


;======================
; SECUENCIA 03
;======================

SEQ3:
    CALL    RETARDO
    INCF    LATD,F           ; Incrementa valor binario
    MOVF    LATD,W
    ANDLW   0b00001111       ; Mantiene solo 4 bits
    MOVWF   LATD
    GOTO    MAIN


;======================
; INTERRUPCIÓN INT0
;======================

ISR:
    BTFSS   INTCON,1         ; Verifica si fue INT0
    RETFIE

    BCF     INTCON,1         ; Limpia bandera
    INCF    Secuencia,F      ; Cambia secuencia
    CLRF    LATD
    MOVLW   0b00000001
    MOVWF   LATD             ; Reinicia LED inicial
    RETFIE


;======================
; BOTÓN VELOCIDAD (RB1)
;======================

CHECK_VEL:

    BTFSC   PORTB,1          ; Si botón está suelto
    GOTO    RELEASE

    MOVF    BtnState,W
    BZ      END_CHECK

    CLRF    BtnState
    INCF    Velocidad,F

    MOVLW   0b00000011
    CPFSEQ  Velocidad
    GOTO    END_CHECK
    CLRF    Velocidad        ; Si llegó a 3 vuelve a 0

END_CHECK:
    RETURN

RELEASE:
    MOVLW   0b00000001
    MOVWF   BtnState
    RETURN


;======================
; RETARDO  VELOCIDAD
;======================

RETARDO:                     ; Etiqueta de la subrutina de retardo.
                             ; Aquí se calcula el tiempo de espera
                             ; dependiendo del valor almacenado en "Velocidad".

    MOVF    Velocidad,W      ; Mueve el contenido de la variable Velocidad al registro W.
                             ; Esto permite evaluar qué velocidad está seleccionada.
			     
			     
    BZ      LENTA            ; BZ = Branch if Zero.
                             ; Si Velocidad = 0, el resultado en W es 0,
                             ; entonces salta directamente a LENTA.


    MOVLW   0b00000001       ; Carga en W el valor binario 1.
                             ; Este valor representa la velocidad rápida.
			     
			     
    CPFSEQ  Velocidad        ; Compara W (que vale 1) con Velocidad.
                             ; Si son iguales, salta la siguiente instrucción.

    GOTO    RAPIDA            ; Si NO son iguales (o sea, Velocidad diferente de 1),
                              ; salta a RAPIDA.
                              ; Si son iguales, esta línea se omite
                              ; y continúa en MEDIA.


MEDIA:                         ;  velocidad media.
    MOVLW   0b00000100         ; Carga en W el valor 4.
    GOTO    SETVEL             ; Este valor define cuánto se repetirá
                               ; el ciclo externo del retardo (tiempo medio).
			       ; Salta a SETVEL para guardar el valor en Delay1.

			       
RAPIDA:                       ;  velocidad rápida.
    MOVLW   0b00000001        ; Carga en W el valor 1.
    GOTO    SETVEL            ; Esto hará que el retardo sea más corto.
                              ; Salta a SETVEL.

LENTA:                        ; Etiqueta para velocidad lenta.
    MOVLW   0b00001000        ; Carga en W el valor 8.
                              ; Esto hará que el retardo sea más largo.

SETVEL:                      ; Punto común donde se configura el retardo.
    MOVWF   Delay1           ; Guarda el valor de W en Delay1.
                             ; Delay1 será el contador más externo del retardo.
				  
				  
D1:
    MOVLW   0b11001000       ; Primer nivel del retardo (bucle externo).
    MOVWF   Delay2           ; Carga en W el valor 200.
                             ; Este valor será usado como contador intermedio.
			     ; Guarda 200 en Delay2.
			     
D2:                           ; Carga nuevamente 200 en W.
                              ; Guarda 200 en Delay3.
    MOVLW   0b11001000
    MOVWF   Delay3
D3:
    DECFSZ  Delay3,F          ;Decrementa Delay3.
                              ; Si después de decrementar es 0,
			      ; salta la siguiente instrucción.
			    
    GOTO    D3                ; Mientras Delay3 es diferente de 0, sigue repitiendo D3.
    DECFSZ  Delay2,F          ; Cuando Delay3 llega a 0,
                              ; decrementa Delay2.
			      ; Si no es 0, repite D2.
    GOTO    D2                ; Regresa a D2 si Delay2 aún no es 0.
    DECFSZ  Delay1,F          ; Cuando Delay2 llega a 0,
                              ; decrementa Delay1 (nivel externo).
    GOTO    D1                ; Si Delay1 es diferente de 0, repite todo el proceso.


    RETURN                    ; Cuando Delay1 también llega a 0,
                              ; termina el retardo y regresa
                              ; al programa principal.



END
			      
    


