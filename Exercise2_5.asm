;
;      2016.12.22:  author:  Jaro Reinders, Tijmen Jansen
;
;      Alarm
;

@DATA
   TIMER       EQU   -3  ;  address of the Timer
   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
   INPUT       EQU    7  ;  position of the input buttons (relative to IOAREA)
   OUTPUT      EQU   11  ;  relative position of the power outputs
   DSPDIG      EQU    9  ;  relative position of the display selector
   DSPSEG      EQU    8  ;  relative position of the segment selector
   DELTA       EQU   20  ;  1 KHz --> 1 ms --> 1000 µs
   DELTA2      EQU  10000;  1 s
   ;  TO GET N WORDS [0..N-1] CHOOSE N+1, BECAUSE FUCK YOU THAT'S WHY
   ARRX        DS     7  ;  Array to store digits of the counter
   DSPCNT      DS     2  ;  Counter for the displays
   COUNTER     DS     2  ;  The actual counter
   FIXTMR      DS     2  ;  Fixed timer value pulled at start
   FIXTMR2     DS     2  ;  Fixed timer value pulled at start2
   ONOFF       DS     2  ;  Button6 On/Off toggle
   
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
   timer0:  LOAD  R4  TIMER     ;
            STOR  R3  [GB+COUNTER]  ;
            LOAD  R3  [R4]      ;
            STOR  R3  [GB+FIXTMR]
   timer1:  LOAD  R3  [GB+FIXTMR]
            SUB   R3  DELTA     ;
            STOR  R3  [GB+FIXTMR]   ;
   timer2:  LOAD  R3  [GB+FIXTMR]   ;
            CMP   R3  [R4]      ;
            BMI   cntdwn2       ;  Swap between timer and countdown
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
            
  cntdwn0:  LOAD  R4  TIMER     ;  Obsolete
            LOAD  R3  [R4]      ;  Obsolete
            STOR  R3  [GB+FIXTMR2]  ;  Obsolete
  cntdwn1:  LOAD  R3  [GB+FIXTMR2]  ;
            SUB   R3  DELTA2    ;
            STOR  R3  [GB+FIXTMR2]  ;
            BRA   timer2        ;  Swap between timer and countdown
  cntdwn2:  LOAD  R3  [GB+FIXTMR2]  ;
            CMP   R3  [R4]      ;
            BMI   timer2        ;  Swap between timer and countdown
            ;BEGIN PERIODIC TASK
            LOAD  R3  [GB+ONOFF];
            CMP   R3  1         ;
            BNE   cntdwn1       ;
            LOAD  R3  [GB+COUNTER]  ;
            SUB   R3  1         ;
            STOR  R3  [GB+COUNTER]  ;
            BRS   Counter2Dig   ;  Update visible counter
            LOAD  R3  [GB+COUNTER]  ;  Check if timer == 0
            CMP   R3  1         ;
            BPL   pooper        ;
            BRS   party         ;
            LOAD  R3  0         ;
            STOR  R3  [GB+COUNTER]  ;
  pooper:   ;  PARTY.STATUS = POOPED;
            ;END PERIODIC TASK
            BRA   cntdwn1       ;
            
            
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
   btn6:    ;  Alarm stop/run
            ;LOAD R0  [GB+ONOFF]    ;
            ;XOR   R0  1      ;
            LOAD  R0  1     ;
            STOR  R0  [GB+ONOFF]    ;
            RTS             ;
   
   ;  Converts the counter into a decimal number and stores its digits in the array
   Counter2Dig:
            BRS   waste_time;
            BPL   skip_mod  ;
            ADD   R3  86400 ;
   skip_mod:MOD   R3  86400 ;
            STOR  R3  [GB+COUNTER]  ;
            ;  The alaram is mod 24h
            ;  Idea: check 10h - 1h - 10min - 1min - 10s - 1s with some loop
            LOAD  R0  0     ;  Used to count powers of ten
   tenhour: CMP   R3  36000 ;
            BMI   tenhour1  ;  If negative --> No more 1000s
            SUB   R3  36000 ;
            ADD   R0  1     ;  One more 1000 found
            BRA   tenhour   ;  Check again
   tenhour1:BRS   Hex7Seg   ;
            STOR  R1  [GB+ARRX + 6] ;  Display 3 --> 10^3
            LOAD  R0  0     ;  Reset counting of powers of ten
   hour:    CMP   R3  3600  ;
            BMI   hour1     ;  If negative --> No more 100s
            SUB   R3  3600  ;
            ADD   R0  1     ;  One more 100 found
            BRA   hour      ;  Check again
   hour1:   BRS   Hex7Seg   ;
            OR    R1 %10000000  ;  Decimal point
            STOR  R1 [GB+ARRX + 5]  ;  Display 2 --> 10^2
            LOAD  R0  0     ;
   tenmin:  CMP   R3  600   ;
            BMI   tenmin1   ;  If negative --> No more 100s
            SUB   R3  600   ;
            ADD   R0  1     ;  One more 100 found
            BRA   tenmin    ;  Check again
   tenmin1: BRS   Hex7Seg   ;
            STOR  R1 [GB+ARRX + 4]  ;  Display 2 --> 10^2
            LOAD  R0  0     ;
   min:     CMP   R3  60    ;
            BMI   min1      ;  If negative --> No more 10s
            SUB   R3  60    ;
            ADD   R0  1     ;  One more 10 found
            BRA   min       ;  Check again
   min1:    BRS   Hex7Seg   ;
            OR    R1 %10000000  ;  Decimal point
            STOR  R1 [GB+ARRX + 3]  ;  Display 1 --> 10^1
            LOAD  R0  0     ;
   tensec:  CMP   R3  10    ;
            BMI   tensec1   ;  If negative --> No more 10s
            SUB   R3  10    ;
            ADD   R0  1     ;  One more 10 found
            BRA   tensec    ;  Check again
   tensec1: BRS   Hex7Seg   ;
            STOR  R1 [GB+ARRX + 2]  ;  Display 1 --> 10^1
            LOAD  R0  0     ;
   sec:     CMP   R3  1     ;
            BMI   sec1      ;  If negative --> No more 1s
            SUB   R3  1     ;
            ADD   R0  1     ;  One more 1 found
            BRA   sec       ;  Check again
   sec1:    BRS   Hex7Seg   ;
            STOR  R1 [GB+ARRX + 1] ;  Display 0 --> 10^0
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
            LOAD  R1  %01000000 ;
            AND   R0  R1        ;
            CMP   R0  %01000000     ;  Is Button6 pressed?
            BEQ   btn6          ;
            LOAD  R0  0         ;
            STOR  R0  [GB+ONOFF];
            RTS                 ;
            
   party:   ;  Too lazy to loop
            LOAD  R0  %111111   ;  Turn all LEDs on
            STOR  R0  [R5+OUTPUT]  ;  Woopwoop
            BRS   waste_time    ;
            LOAD  R0  0         ;  Turn all LEDs off
            STOR  R0  [R5+OUTPUT]  ;  Woopwoop
            LOAD  R0  %111111   ;  Turn all LEDs on
            STOR  R0  [R5+OUTPUT]  ;  Woopwoop
            BRS   waste_time    ;
            LOAD  R0  0         ;  Turn all LEDs off
            STOR  R0  [R5+OUTPUT]  ;  Woopwoop
            LOAD  R0  %111111   ;  Turn all LEDs on
            STOR  R0  [R5+OUTPUT]  ;  Woopwoop
            BRS   waste_time    ;
            LOAD  R0  0         ;  Turn all LEDs off
            STOR  R0  [R5+OUTPUT]  ;  Woopwoop
            LOAD  R0  %111111   ;  Turn all LEDs on
            STOR  R0  [R5+OUTPUT]  ;  Woopwoop
            BRS   waste_time    ;
            LOAD  R0  0         ;  Turn all LEDs off
            STOR  R0  [R5+OUTPUT]  ;  Woopwoop
            LOAD  R0  %111111   ;  Turn all LEDs on
            STOR  R0  [R5+OUTPUT]  ;  Woopwoop
            BRS   waste_time    ;
            LOAD  R0  0         ;  Turn all LEDs off
            STOR  R0  [R5+OUTPUT]  ;  Woopwoop
            LOAD  R0  %111111   ;  Turn all LEDs on
            STOR  R0  [R5+OUTPUT]  ;  Woopwoop
            BRS   waste_time    ;
            LOAD  R0  0         ;  Turn all LEDs off
            STOR  R0  [R5+OUTPUT]  ;  Woopwoop
            LOAD  R0  %111111   ;  Turn all LEDs on
            STOR  R0  [R5+OUTPUT]  ;  Woopwoop
            BRS   waste_time    ;
            LOAD  R0  0         ;  Turn all LEDs off
            STOR  R0  [R5+OUTPUT]  ;  Woopwoop
            RTS
            
waste_time: LOAD  R0 $0fffff;
while:      SUB   R0 1
            BEQ   fin
            BRA   while
fin:        RTS
