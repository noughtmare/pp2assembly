; Exercise 2.3a
; 20161220 - Tijmen Jansen
;
; Construct a program, using the timer, that makes output LED0 blink. The
; LED should be \on" for half-a-second, then \o" for a full second, then \on"
; again for one half second, and so on forever. Check that the total frequency is
; (close to) 0:66 Hz indeed, by timing the blinking with your wrist watch for at
; least 2 minutes.
@DATA
        TIMER   EQU -3  ; Register of the timer
        IOAREA  EQU -16 ; Register of the start of the I/O area
        OUTPUT  EQU 11  ; Relative position of the LEDs
        INPUT   EQU 7   ;

@CODE
        LOAD    R5  TIMER   ;
        LOAD    R4  IOAREA  ;
main:   LOAD    R0  [R5]    ; GOOD HEAVENS WOULD YOU LOOK AT THE TIME
        MOD     R0  256     ; 2^8
        STOR    R0  [R4+OUTPUT]  ; TURN ON THE LIGHTS
        BRA     main        ;
@END