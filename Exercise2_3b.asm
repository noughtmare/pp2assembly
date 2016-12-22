;
;      2016.12.21:  author:  Jaro Reinders, Tijmen Jansen
;
;      LED0 will blink(tm).
;      Pushing Button5 will make LED5 switch between ON/OFF while LED0 keeps on blinking
;      TODO: Use DELTA2 to increase main body frequency to 33 Hz, but keep LED0 at 0.66 Hz
;            Maybe do some counter magic? [0..50] --> ON, [51..150] --> OFF
;      !!!!! Little do they know, this program doesn't run into the problem described in c
;
@DATA
   TIMER       EQU   -3  ;  address of the Timer
   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
   INPUT       EQU    7  ;  position of the input buttons (relative to IOAREA)
   OUTPUT      EQU   11  ;  relative position of the power outputs
   DELTA       EQU 5000  ;  Amount of timer steps to wait, 5000 steps <=> 0.5 second
   DELTA2      EQU  100  ;  5000/50
   PUSHVAR     EQU   1   ;  Location of the pushbutton variable on the heap
   LASTSTATE   EQU   2   ;  Location of the last state variable on the heap
   LEDS        EQU   33  ;  Location of the LEDs variable on the heap

@CODE
;  
;      The body of the main program
;
   main :     LOAD  R5  TIMER   ;  Load specific values we need
              LOAD  R4  IOAREA  ;  ^
              LOAD  R2  [R5]    ;  Fixed timer value
              LOAD  R1  3       ;  Temp value
              STOR  R1  [GB+PUSHVAR] ;  Set pushvar to 3
              LOAD  R1  1       ;  R1 is the counter
              LOAD  R0  0       ;  Temp value
              STOR  R0  [GB+LASTSTATE]  ;  When program starts, last state was not-pressed
              STOR  R0  [GB+LEDS]       ;  When program starts, no LEDs are on
              ;LOAD  R3  1      ;  R3 is the constant one  (on)
;
   loop :     SUB  R2  DELTA    ;  Subtract DELTA from the fixed timer value
;
   loop2:     BRS  chkbutt5     ;  Branch Subroutine to check button 5
              CMP  R2 [R5]      ;  Compare the fixed timer value to the current timer value
              BMI  loop2        ;  Branch Minus --> R2 < TIMER
              SUB  R1 1         ;  Decrement counter
              BNE  light_off    ;  R1 != 0
              ;LOAD R0 [R4+OUTPUT]   ;  Get current state of LEDs <-- Doesn't work?
              LOAD R0 [GB+LEDS] ;  Get current state of LEDs
              LOAD R3 %00000001 ;  Only LED0
              XOR  R3 R0        ;  Flip LED0
              STOR R3 [R4+OUTPUT]   ;  Update LED values
              STOR R3 [GB+LEDS] ;  Set LEDS ^2
              LOAD R1 3         ;  Set counter back to 3
              BRA  loop         ;  Branch Always start a new loop
   light_off: ;LOAD R0 [R4+OUTPUT]   ;  Get current state of LEDs
              LOAD R0 [GB+LEDS] ;  Get current state of LEDs
              LOAD R3 %00000001 ;  Only LED0
              XOR  R3 R0        ;  Flip LED0
              STOR R3 [R4+OUTPUT]   ;  Update LED values
              STOR R3 [GB+LEDS] ;  Set LEDS ^2
              BRA  loop         ;  Branch Always start a new loop
    
;
;      Subs
;   
   chkbutt5:  LOAD R0 [R4+INPUT];  Load the input buttons
              LOAD R4 [GB+LASTSTATE] ; Load the last state of Button5
              LOAD R3 %00100000 ;  Button5
              AND  R0 R3        ;  Only look at Button5
              CMP  R0 R4        ;  Test if Button5 has been changed
              BEQ  end_cb5      ;  Button5 not changed --> Get out
              ;  Button5 has been changed
              STOR R0 [GB+LASTSTATE];  New last state
              LOAD R4 [GB+PUSHVAR]  ; Load the outdated pushvar
              ADD  R4 1         ;  Update it
              MOD  R4 4         ;  Mod 4 it
              STOR R4 [GB+PUSHVAR] ; Store it
              ;  Check if we have to flip LED5
              MOD  R4  2        ;  On 0 and 2 we need to flip LED5
              BNE  end_cb5      ;  If ZERO --> Flip, If ONE --> End
   flip_cb5:  LOAD R4 IOAREA    ;
              ;LOAD R0 [R4+OUTPUT]   ;  Get current LED status
              LOAD R0 [GB+LEDS] ;  Get current state of LEDs
              LOAD R3 %00100000 ;  LED5
              XOR  R3 R0        ;  Flip LED5
              STOR R3 [R4+OUTPUT]   ;  Set LEDs
              STOR R3 [GB+LEDS] ;  Set LEDS ^2
   end_cb5:   ;LOAD R0 0         ;  Restore the constant zero (off)
              ;LOAD R3 1         ;  Restore the constant one  (on)
              LOAD R4 IOAREA    ;  Restore R4
              RTS               ;  Return from subroutine
              
@END