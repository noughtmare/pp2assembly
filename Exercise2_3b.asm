;
;      2016.12.21:  author:  Jaro Reinders
;
;      The led will blink(tm).
;      
@DATA
   TIMER       EQU   -3  ;  address of the Timer
   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
   INPUT       EQU    7  ;  position of the input buttons (relative to IOAREA)
   OUTPUT      EQU   11  ;  relative position of the power outputs
   DELTA       EQU 5000  ;  Time difference between every step

@CODE
  begin :      BRA  main
;  
;      The body of the main program
;
   main :     LOAD  R5  TIMER
              LOAD  R4  IOAREA
              LOAD  R2  [R5]
              LOAD  R1  1
              LOAD  R0  0
              LOAD  R3  1
;
   loop :     SUB   R2  DELTA
;
   loop2:     CMP R2 [R5]
              BMI loop2
              SUB R1 1
              BNE iets
              STOR R3 [R4+OUTPUT]
              LOAD R1 3
              BRA loop

   iets:      STOR R0 [R4+OUTPUT]
              BRA loop
@END
