;      2017.01.13:  authors:  Jaro Reinders, Tijmen Jansen
@DATA 

  TIMER   EQU  -3
  INPUT   EQU  -9 ; location of the input buttons
  OUTLEDS EQU  -5 ; location of the output leds
  PWMVAR  DS    4 ; 4 Distinct PWM values
  LASTVAR DS    1 ; last state of buttons
  COUNT   DS    1 ;
  DELTA   EQU   1 ;

; R0 := Temp var
; R1 := Counter
; R2 := PWM Threshold
; R3 := Temp button var
; R4 := Input check var
; R5 := New led state
; R6 := GB
; R7 := SP

@CODE

   init: ; R5 contains the pointer to the Code Segment
         LOAD R0 timISR          ;
         ADD  R0 R5              ;
         LOAD R1 16              ; 2*8
         STOR R0 [R1]            ;
         SETI 8                  ; IE[8] <=> Timer < 0

         LOAD R0 0               ; Init timer
         LOAD R5 0               ;
         SUB  R0 [R5+TIMER]      ;
         STOR R0 [R5+TIMER]      ;

         ; incremenent the counter
         ; read the buttons
   main: LOAD R4 INPUT
         LOAD R0 [R4]              ; Load the current state
         LOAD R4 [GB + LASTVAR]    ; Load the last state
         AND  R0 %00001111         ; filter the first 4 buttons
         XOR  R4 R0                ; R4 := changed buttons, R0 := new button state
         STOR R0 [GB + LASTVAR]    ; Store the current state in LASTVAR

         ; check if the first button state has changed
   btn0: LOAD R3 R4                ; R3 := changed buttons
 	 AND  R3 %00000001         ; Has the first button changed state?
         BEQ  btn1                 ; No -> check the next button; Yes -> continue

         ; check if the first button is now depressed
         LOAD R3 R0                ; R3 := new button state
         AND  R3 %00000001         ; Is the first button released?
         BNE  btn1                 ; No -> check the next button; Yes -> continue

         ; update the first PWM threshold
         LOAD R3 [GB + PWMVAR + 0]
         ADD  R3 1
         MOD  R3 100
         STOR R3 [GB + PWMVAR + 0]

         ; See btn0
   btn1: LOAD R3 R4
 	 AND  R3 %00000010
         DIV  R3 2                 ; shift right by 1
         CMP  R3 0
         BEQ  btn2

         LOAD R3 R0
         AND  R3 %00000010
         DIV  R3 2
         CMP  R3 0
         BNE  btn2

         LOAD R3 [GB + PWMVAR + 1] 
         ADD  R3 1
         MOD  R3 100
         STOR R3 [GB + PWMVAR + 1]

         ; See btn0
   btn2: LOAD R3 R4
 	 AND  R3 %00000100
         DIV  R3 4                 ; shift right by 2
         CMP  R3 0
         BEQ  btn3

         LOAD R3 R0
         AND  R3 %00000100
         DIV  R3 4
         CMP  R3 0
         BNE  btn3

         LOAD R3 [GB + PWMVAR + 2] 
         ADD  R3 1
         MOD  R3 100
         STOR R3 [GB + PWMVAR + 2]

         ; See btn0
   btn3: LOAD R3 R4               
 	 AND  R3 %00001000
         DIV  R3 8                 ; shift right by 3
         CMP  R3 0
         BEQ  main

         LOAD R3 R0
         AND  R3 %00001000         
         DIV  R3 8
         CMP  R3 0
         BNE  main

         LOAD R3 [GB + PWMVAR + 3] 
         ADD  R3 1
         MOD  R3 100
         STOR R3 [GB + PWMVAR + 3]

         BRA main

 timISR: ; Handle interrupt
         LOAD R1 [GB+COUNT]
         ADD  R1 1
         MOD  R1 100

  check: LOAD R5 0                 ; clear R5
         
         ; Check if the threshold is reached
 chk_o0: LOAD R2 [GB + PWMVAR + 0] ; load the first PWM threshold
         CMP  R2 R1                ; Is it greater than the counter?
         BMI  chk_o1               ; No -> go to the second check; Yes -> continue
         OR   R5 %00000001         ; enable the first button

         ; See chk_o0
 chk_o1: LOAD R2 [GB + PWMVAR + 1]
         CMP  R2 R1
         BMI  chk_o2
         OR   R5 %00000010

         ; See chk_o0
 chk_o2: LOAD R2 [GB + PWMVAR + 2]
         CMP  R2 R1
         BMI  chk_o3
         OR   R5 %00000100

         ; See chk_o0
 chk_o3: LOAD R2 [GB + PWMVAR + 3]
         CMP  R2 R1
         BMI  format
         OR   R5 %00001000

         ; make the left four bits the inverse of the right four bits
 format: STOR R1 [GB+COUNT]
         LOAD R0 R5
         MULS R0 16
         XOR  R5 %00001111
         OR   R5 R0

         ; Show R5 on the leds
   show: LOAD R0 OUTLEDS
         STOR R5 [R0]

         LOAD R1 DELTA           ; Restore timer
         LOAD R4 TIMER           ;
         STOR R1 [R4]            ;
         
         SETI 8                  ;
         RTE                     ;

@END
