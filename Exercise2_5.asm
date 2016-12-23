;
;      2016.12.22:  author:  Jaro Reinders, Tijmen Jansen
;
;      Counter modulo 5000
;

@DATA
   TIMER       EQU   -3  ;  address of the Timer
   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
   INPUT       EQU    7  ;  position of the input buttons (relative to IOAREA)
   OUTPUT      EQU   11  ;  relative position of the power outputs
   DSPDIG      EQU    9  ;  relative position of the display selector
   DSPSEG      EQU    8  ;  relative position of the segment selector
   DELTA       EQU   20  ;  1 KHz --> 1 ms --> 1000 µs
   DELTA2      EQU  10000 ;
   ;  Array to store digits of the counter
   ARR0        EQU    1  ;
   ARR1        EQU    2  ;
   ARR2        EQU    3  ;
   ARR3        EQU    4  ;
   ARR4        EQU    5  ;
   ARR5        EQU    6  ;
   DSPCNT      EQU    7  ;  Counter for the displays
   COUNTER     EQU    8  ;  The actual counter
   FIXTMR      EQU    33  ;  Fixed timer value pulled at start
   FIXTMR      EQU    34  ;  Fixed timer value pulled at start
   
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
            LOAD  R3  0         ;  Set the counter to 0
            ;  TEMP VALS FOR DISPLAY
            ;LOAD  R0  0         ;
            ;BRS   Hex7Seg       ;
            ;STOR  R1  [GB+ARR0] ;
            ;LOAD  R0  1         ;
            ;BRS   Hex7Seg       ;
            ;STOR  R1  [GB+ARR1] ;
            ;LOAD  R0  2         ;
            ;BRS   Hex7Seg       ;
            ;STOR  R1  [GB+ARR2] ;
            ;LOAD  R0  3         ;
            ;BRS   Hex7Seg       ;
            ;STOR  R1  [GB+ARR3] ;
            ;LOAD  R0  4         ;
            ;BRS   Hex7Seg       ;
            ;STOR  R1  [GB+ARR4] ;
            ;LOAD  R0  5         ;
            ;BRS   Hex7Seg       ;
            ;STOR  R1  [GB+ARR5] ;
            ; ----------------------
   timer0:  LOAD  R4  TIMER     ;
            STOR  R3  [GB+COUNTER]  ;
            LOAD  R3  [R4]      ;
            STOR  R3  [GB+FIXTMR]
   timer1:  LOAD  R3  [GB+FIXTMR]
            SUB   R3  DELTA     ;
            STOR  R3  [GB+FIXTMR]   ;
   timer2:  LOAD  R3  [GB+FIXTMR]   ;
            CMP   R3  [R4]      ;
            BMI   timer2        ;
            ;BEGIN PERIODIC TASK
   disp:    BRS   btn_chk       ;
            LOAD  R2  [GB+DSPCNT]   ;  Cycle through displays
            ADD   R2  1         ;
            MOD   R2  6         ;
            STOR  R2  [GB+DSPCNT]   ;
            LOAD  R1  1         ;
   power2:  CMP   R2  0         ;  While R2>0 do R1+R1, R2--
            BEQ   end_pow       ;
            ADD   R1  R1        ;
            SUB   R2  1         ;
            BRA   power2        ;
   end_pow: LOAD  R2  [GB+DSPCNT]   ;  We now have selected the right display element
            ADD   R2  1         ;
            LOAD  R0  [GB+R2]   ;
            STOR  R0  [R5+DSPSEG]   ;
            STOR  R1  [R5+DSPDIG]   ;
            ;END PERIODIC TASK
            BRA   timer1        ;
            
            
   btn0:    ;  counter++
            ADD  R3  1      ;
            BRA  Counter2Dig;
   btn1:    ;  counter--
            SUB  R3  1      ;
            BRA  Counter2Dig;
   btn2:    ;  counter += 10
            ADD  R3  60     ;
            BRA  Counter2Dig;
   btn3:    ;  counter -= 10
            SUB  R3  60     ;
            BRA  Counter2Dig;
   btn4:    ;  counter += 500
            ADD  R3  3600   ;
            BRA  Counter2Dig;
   btn5:    ;  counter -= 500
            SUB  R3  3600   ;
            BRA  Counter2Dig;
   btn7:    ;  counter = 0
            LOAD R3  0      ;
            BRA  Counter2Dig;
   
   ;  Converts the counter into a decimal number and stores its digits in the array
   Counter2Dig:
            BPL   skip_mod  ;
            ADD   R3  86400 ;
   skip_mod:MOD   R3  86400 ;
            STOR  R3  [GB+COUNTER]  ;
            ;  The counter is mod 5000
            ;  Idea: check 1000s - 100s - 10s - 1s with some loop
            LOAD  R0  0     ;  Used to count powers of ten
   tenhour: CMP   R3  36000 ;
            BMI   tenhour1  ;  If negative --> No more 1000s
            SUB   R3  36000 ;
            ADD   R0  1     ;  One more 1000 found
            BRA   tenhour   ;  Check again
   tenhour1:BRS   Hex7Seg   ;
            STOR  R1  [GB+ARR5] ;  Display 3 --> 10^3
            LOAD  R0  0     ;  Reset counting of powers of ten
   hour:    CMP   R3  3600  ;
            BMI   hour1     ;  If negative --> No more 100s
            SUB   R3  3600  ;
            ADD   R0  1     ;  One more 100 found
            BRA   hour      ;  Check again
   hour1:   BRS   Hex7Seg   ;
            OR    R1 %10000000
            STOR  R1 [GB+ARR4]  ;  Display 2 --> 10^2
            LOAD  R0  0     ;
   tenmin:  CMP   R3  600  ;
            BMI   tenmin1   ;  If negative --> No more 100s
            SUB   R3  600  ;
            ADD   R0  1     ;  One more 100 found
            BRA   tenmin    ;  Check again
   tenmin1: BRS   Hex7Seg   ;
            STOR  R1 [GB+ARR3]  ;  Display 2 --> 10^2
            LOAD  R0  0     ;
   min:     CMP   R3  60    ;
            BMI   min1      ;  If negative --> No more 10s
            SUB   R3  60    ;
            ADD   R0  1     ;  One more 10 found
            BRA   min       ;  Check again
   min1:    BRS   Hex7Seg   ;
            OR    R1 %10000000
            STOR  R1 [GB+ARR2]  ;  Display 1 --> 10^1
            LOAD  R0  0     ;
   tensec:  CMP   R3  10    ;
            BMI   tensec1   ;  If negative --> No more 10s
            SUB   R3  10    ;
            ADD   R0  1     ;  One more 10 found
            BRA   tensec    ;  Check again
   tensec1: BRS   Hex7Seg   ;
            STOR  R1 [GB+ARR1]  ;  Display 1 --> 10^1
            LOAD  R0  0     ;
   sec:     CMP   R3  1     ;
            BMI   sec1      ;  If negative --> No more 1s
            SUB   R3  1     ;
            ADD   R0  1     ;  One more 1 found
            BRA   sec       ;  Check again
   sec1:    BRS   Hex7Seg   ;
            STOR  R1 [GB+ARR0] ;  Display 0 --> 10^0
            RTS             ;
            
    btn_chk: LOAD  R0  [R5+INPUT]    ;  Get the input from the buttons
            ;  "You may assume that, at any moment, at most one button is pressed."
            LOAD  R3  [GB+COUNTER]  ;
            CMP   R0  %00000001     ;  Is Button0 pressed?
            BEQ   btn0          ;
            CMP   R0  %00000010     ;  Is Button1 pressed?
            BEQ   btn1          ;
            CMP   R0  %00000100     ;  Is Button2 pressed?
            BEQ   btn2          ;
            CMP   R0  %00001000     ;  Is Button3 pressed?
            BEQ   btn3          ;
            CMP   R0  %00010000     ;  Is Button4 pressed?
            BEQ   btn4          ;
            CMP   R0  %00100000     ;  Is Button5 pressed?
            BEQ   btn5          ;
            CMP   R0  %010000000    ;  Is Button7 pressed?
            BEQ   btn7          ;
            RTS                 ;
   
waste_time: LOAD  R0 5000
while:      SUB   R0 1
            BEQ   fin
            BRA   while
fin:        RTS
