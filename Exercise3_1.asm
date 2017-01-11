;
;      2011.01.11:  author:  Jaro Reinders, Tijmen Jansen
;
;      Potentiometer
;

@DATA
   TIMER       EQU   -3  ;  address of the Timer
   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
   INPUT       EQU    7  ;  position of the input buttons (relative to IOAREA)
   OUTPUT      EQU   11  ;  relative position of the power outputs
   DSPDIG      EQU    9  ;  relative position of the display selector
   DSPSEG      EQU    8  ;  relative position of the segment selector
   ADCONVS     EQU  -10  ;  #potential
   DELTA       EQU   20  ;  1 KHz --> 1 ms --> 1000 µs
   ;  TO GET N WORDS [0..N-1] CHOOSE N+1, BECAUSE FUCK YOU THAT'S WHY
   FIXTMR      DS     2  ;
   DSPCNT      DS     2  ;  Counter for the displays
   ARRX        DS     7  ;
   
@CODE
begin :     BRA  main    ;  skip subroutine Hex7Seg
;  
;      Routine Hex7Seg maps a number in the range [0..15] to its hexadecimal
;      representation pattern for the 7-segment display.
;      R0 : upon entry, contains the number
;      R1 : upon exit,  contains the resulting pattern
;
Hex7Seg     :  BRS  Hex7Seg_bgn  ;  push address(tbl) onto stack and proceed at "bgn"
Hex7Seg_tbl : CONS  %01111110    ;  7-segment pattern for '0'
              CONS  %00110000    ;  7-segment pattern for '1'
              CONS  %01101101    ;  7-segment pattern for '2'
              CONS  %01111001    ;  7-segment pattern for '3'
              CONS  %00110011    ;  7-segment pattern for '4'
              CONS  %01011011    ;  7-segment pattern for '5'
              CONS  %01011111    ;  7-segment pattern for '6'
              CONS  %01110000    ;  7-segment pattern for '7'
              CONS  %01111111    ;  7-segment pattern for '8'
              CONS  %01111011    ;  7-segment pattern for '9'
              CONS  %01110111    ;  7-segment pattern for 'A'
              CONS  %00011111    ;  7-segment pattern for 'b'
              CONS  %01001110    ;  7-segment pattern for 'C'
              CONS  %00111101    ;  7-segment pattern for 'd'
              CONS  %01001111    ;  7-segment pattern for 'E'
              CONS  %01000111    ;  7-segment pattern for 'F'
Hex7Seg_bgn:   AND  R0  %01111   ;  R0 := R0 MOD 16 , just to be safe...
              LOAD  R1  [SP++]   ;  R1 := address(tbl) (retrieve from stack)
              LOAD  R1  [R1+R0]  ;  R1 := tbl[R0]
               RTS
;
;      The body of the main program
;
   main :   LOAD  R5  IOAREA    ;  R5 := "address of the area with the I/O-registers"
   timer0:  LOAD  R4  TIMER     ;
            LOAD  R3  [R4]      ;
            STOR  R3  [GB+FIXTMR]
   timer1:  LOAD  R3  [GB+FIXTMR]
            SUB   R3  DELTA     ;
            STOR  R3  [GB+FIXTMR]   ;
   timer2:  LOAD  R3  [GB+FIXTMR]   ;
            LOAD  R4  TIMER     ;
            CMP   R3  [R4]      ;
            BMI   timer2       ;  Swap between timer and countdown
            ;BEGIN PERIODIC TASK
            BRS readpot         ;
   disp:    LOAD  R2  [GB+DSPCNT]   ;  Cycle through displays
            ADD   R2  1         ;
            MOD   R2  3         ;
            STOR  R2  [GB+DSPCNT]   ;
            LOAD  R1  1         ;
   power2:  CMP   R2  0         ;  While R2>0 do R1+R1, R2--
            BEQ   end_pow       ;
            ADD   R1  R1        ;
            SUB   R2  1         ;
            BRA   power2        ;
   end_pow: LOAD  R2  [GB+DSPCNT]   ;  We now have selected the right display element
            ADD   R2  1         ;
            ADD   R2  ARRX      ;
            LOAD  R0  [GB+R2]   ;
            SUB   R2  ARRX      ;
            STOR  R0  [R5+DSPSEG]   ;
            STOR  R1  [R5+DSPDIG]   ;
            ;END PERIODIC TASK
            BRA   timer1        ;
            
            
   readpot: LOAD  R4  ADCONVS   ;
            LOAD  R2  [R4]      ;  Get contents
            AND   R2  %0000000011111111 ;  Lower 8 bits
            STOR  R2  [R5+OUTPUT]  ;  Store in LEDs
            LOAD  R0  250       ;
            CMP   R0  R2        ;
            BPL   r2d           ;
            LOAD  R2  250       ;
   r2d:     MULS  R2  2         ;
            LOAD  R0  0         ;
   hndrds:  CMP   R2  100  ;
            BMI   hndrds1   ;  If negative --> No more 100s
            SUB   R2  100  ;
            ADD   R0  1     ;  One more 100 found
            BRA   hndrds    ;  Check again
   hndrds1: BRS   Hex7Seg   ;
            OR    R1 %10000000  ;  Decimal point
            STOR  R1  [GB+ARRX + 3] ;  Display 2 --> 10^2
            LOAD  R0  0     ;  Reset counting of powers of ten
   tens:    CMP   R2  10  ;
            BMI   tens1   ;  If negative --> No more 10s
            SUB   R2  10  ;
            ADD   R0  1     ;  One more 10 found
            BRA   tens    ;  Check again
   tens1:   BRS   Hex7Seg   ;
            STOR  R1  [GB+ARRX + 2] ;  Display 1 --> 10^1
            LOAD  R0  0     ;  Reset counting of powers of ten   
    ones:   CMP   R2  1  ;
            BMI   ones1   ;  If negative --> No more 10s
            SUB   R2  1  ;
            ADD   R0  1     ;  One more 10 found
            BRA   ones    ;  Check again
   ones1:   BRS   Hex7Seg   ;
            STOR  R1  [GB+ARRX + 1] ;  Display 0 --> 10^0
            RTS       ;
            
waste_time: LOAD  R0 5000;
while:      SUB   R0 1
            BEQ   fin
            BRA   while
fin:        RTS