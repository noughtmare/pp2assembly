;
;      2011.10.11:  author:  Rob Hoogerwoord
;
;      2013.10.29:  removed errors in the annotation [RH]
;
;      This routine continuously reads the intput buttons and copies them to the
;      LED outputs. In addition, if Button 0 is pressed this increases a modulo
;      16 counter which is displayed at the right-most digit of the display,
;      and, similarly, if Button 1 is pressed this increases a modulo 16 counter
;      which is displayed at the second right-most digit of the display.
;
;
@CODE

   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
    INPUT      EQU    7  ;  position of the input buttons (relative to IOAREA)
   OUTPUT      EQU   11  ;  relative position of the power outputs
   DSPDIG      EQU    9  ;  relative position of the 7-segment display's digit selector
   DSPSEG      EQU    8  ;  relative position of the 7-segment display's segments

  begin :      BRA  main         ;  skip subroutine Hex7Seg
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
   main :     LOAD  R5  IOAREA   ;  R5 := "address of the area with the I/O-registers"
              LOAD  R2  0        ;  R2 is counter nr. 0, initially 0
              LOAD  R3  0        ;  R3 is counter nr. 1, initially 0
;
   loop :     LOAD  R0  [R5+INPUT]  ;   read Input Buttons
              STOR  R0  [R5+OUTPUT] ;  write this to Output LEDs
               CMP  R0  1        ;  test if Button 0 is pressed, and no other ones
               BNE  next         ;  if not then skip this part, continue at "next"
               ADD  R2  1        ;  increment counter nr. 0
               AND  R2  %01111   ;  take it modulo 16
              LOAD  R0  R2       ;  copy counter 0 into R0; R2 must be preserved
               BRS  Hex7Seg      ;  translate (value in) R0 into a display pattern
              STOR  R1  [R5+DSPSEG] ; and place this in the Display Element
              LOAD  R1  %000001  ;  R1 := the bitpattern identifying Digit 0
              STOR  R1  [R5+DSPDIG] ; activate Display Element nr. 0
               BRA  loop         ;  repeat ad infinitum...
;
   next :      CMP  R0  2        ;  test if Button 1 is pressed, and no other ones
               BNE  loop         ;  if not then skip this part
               ADD  R3  1        ;  increment counter nr. 1
               AND  R3  %01111   ;  take it modulo 16
              LOAD  R0  R3       ;  copy counter 1 into R0; R3 must be preserved
               BRS  Hex7Seg      ;  translate (value in) R0 into a display pattern
              STOR  R1  [R5+DSPSEG] ; and place this in the Display Element
              LOAD  R1  %000010  ;  R1 := the bitpattern identifying Digit 1
              STOR  R1  [R5+DSPDIG] ; activate Display Element nr. 1
               BRA  loop         ;  repeat ad infinitum...
@END
