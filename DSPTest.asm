@DATA
        TIMER   EQU -3  ; Register of the timer
        IOAREA  EQU -16 ; Register of the start of the I/O area
        OUTPUT  EQU 11  ; Relative position of the LEDs
        INPUT   EQU 7   ;
        DSPDIG      EQU    9  ;  relative position of the 7-segment display's digit selector
        DSPSEG      EQU    8  ;  relative position of the 7-segment display's segments
        ONE EQU %00110000
        TWO EQU %01101101

@CODE
        LOAD    R4  IOAREA  ;
main:   LOAD    R0  ONE   ;
        STOR    R0  [R4+DSPSEG] ; TURN ON THE LIGHTS
        LOAD    R1  1
        STOR    R1  [R4+DSPDIG]
        BRS waste_time
        LOAD    R0  TWO
        STOR    R0  [R4+DSPSEG]
        LOAD    R1  2
        STOR    R1  [R4+DSPDIG]
        BRS waste_time
        BRA     main
waste_time: LOAD R2 10000
while:      SUB R2 1
            BEQ fin
            BRA while
fin:        RTS
@END