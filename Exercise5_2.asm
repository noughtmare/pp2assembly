;
;      2017.01.17:  authors:  Jaro Reinders, Tijmen Jansen
;
;      Interrupts
;
@DATA
    INPUT   EQU   -9                 ; location of the input buttons
    TRILEDS EQU   -6                 ; location of the potential meter
    OUTPUT  EQU   -5                 ; location of the output leds
    TIMER   EQU   -3                 ; location of the timer
    DELTA   EQU 1000                 ; Time to add to the timer
    BUTTS   DS     1                 ; Holds state of input buttons
    COUNTER DS     1                 ; Temp counter
    FLIP    DS     1                 ; LED status
  
    ; R0 := Button checker
    ; R1 := Input location holder
    ; R2 := *
    ; R3 := *
    ; R4 := *
    ; R5 := *
    ; R6 := GB
    ; R7 := SP
  
@CODE

begin:  ; R5 contains the pointer to the Code Segment
        LOAD R0 timISR          ;
        ADD  R0 R5              ;
        LOAD R1 16              ; 2*8
        STOR R0 [R1]            ;
        SETI 8                  ; IE[8] <=> Timer < 0
        
        LOAD R3 %0111           ; Init regs
        STOR R3 [GB+FLIP]       ;
        LOAD R1 INPUT           ;
        
        LOAD R0 0               ; Init timer
        LOAD R5 0               ;
        SUB  R0 [R5+TIMER]      ;
        STOR R0 [R5+TIMER]      ;
        
loop:   LOAD R0 [R1]            ; Get button status constantly
        STOR R0 [GB+BUTTS]      ;
        BRA  loop               ;
        
timISR: ; Manage stack
        ;PUSH R0                 ;
        ;PUSH R1                 ;
        ;PUSH R2                 ;
        ;PUSH R3                 ;
        ;PUSH R4                 ;
        ;PUSH R5                 ;
        
        LOAD R5 [GB+COUNTER]    ; Add 1 to temp counter
        ADD  R5 1               ;
        STOR R5 [GB+COUNTER]    ;
        
        ; Handle interrupt
        LOAD R2 TRILEDS         ; Flip trileds
        LOAD R3 [GB+FLIP]       ;
        STOR R3 [R2]            ;
        XOR  R3 %0111           ;
        STOR R3 [GB+FLIP]       ;
        
        LOAD R2 [GB+BUTTS]      ; Store buttons to LEDs
        LOAD R4 OUTPUT          ;
        STOR R2 [R4]            ;
        
        LOAD R1 DELTA           ; Restore timer
        LOAD R4 TIMER           ;
        STOR R1 [R4]            ;
        
        ; Manage stack
        ;PULL R0                 ;
        ;PULL R1                 ;
        ;PULL R2                 ;
        ;PULL R3                 ;
        ;PULL R4                 ;
        ;PULL R5                 ;
        
        SETI 8                  ;
        RTE                     ;
@END