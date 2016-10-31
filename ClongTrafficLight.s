@ CSC230 --  Traffic Light simulation program
@ Latest edition: Spring 2013
@ Author:  Micaela Serra 
@ Modified by: Cameron Long V00748439 <---- PUT YOUR NAME AND ID HERE!!!! 

@===== STAGE 0
@  	Sets initial outputs and screen for INIT
@ Calls StartSim to start the simulation,
@	polls for left black button, returns to main to exit simulation

        .equ    SWI_EXIT, 		0x11		@terminate program
        @ swi codes for using the Embest board
        .equ    SWI_SETSEG8, 		0x200	@display on 8 Segment
        .equ    SWI_SETLED, 		0x201	@LEDs on/off
        .equ    SWI_CheckBlack, 	0x202	@check press Black button
        .equ    SWI_CheckBlue, 		0x203	@check press Blue button
        .equ    SWI_DRAW_STRING, 	0x204	@display a string on LCD
        .equ    SWI_DRAW_INT, 		0x205	@display an int on LCD  
        .equ    SWI_CLEAR_DISPLAY, 	0x206	@clear LCD
        .equ    SWI_DRAW_CHAR, 		0x207	@display a char on LCD
        .equ    SWI_CLEAR_LINE, 	0x208	@clear a line on LCD
        .equ 	SEG_A,	0x80		@ patterns for 8 segment display
		.equ 	SEG_B,	0x40
		.equ 	SEG_C,	0x20
		.equ 	SEG_D,	0x08
		.equ 	SEG_E,	0x04
		.equ 	SEG_F,	0x02
		.equ 	SEG_G,	0x01
		.equ 	SEG_P,	0x10                
        .equ    LEFT_LED, 	0x02	@patterns for LED lights
        .equ    RIGHT_LED, 	0x01
        .equ    BOTH_LED, 	0x03
        .equ    NO_LED, 	0x00       
        .equ    LEFT_BLACK_BUTTON, 	0x02	@ bit patterns for black buttons
        .equ    RIGHT_BLACK_BUTTON, 0x01
        @ bit patterns for blue keys 
        .equ    Ph1, 		0x0100	@ =8
        .equ    Ph2, 		0x0200	@ =9
        .equ    Ps1, 		0x0400	@ =10
        .equ    Ps2, 		0x0800	@ =11

		@ timing related
		.equ    SWI_GetTicks, 		0x6d	@get current time 
		.equ    EmbestTimerMask, 	0x7fff	@ 15 bit mask for Embest timer
											@(2^15) -1 = 32,767        										
        .equ	OneSecond,	1000	@ Time intervals
        .equ	TwoSecond,	2000
	@define the 2 streets
	@	.equ	MAIN_STREET		0
	@	.equ	SIDE_STREET		1
 
       .text           
       .global _start

@===== The entry point of the program
_start:	
		
	@ initialize all outputs
	BL Init				@ void Init ()
	@ Check for left black button press to start simulation

RepeatTillBlackLeft:
	swi     SWI_CheckBlack
	cmp     r0, #LEFT_BLACK_BUTTON	@ start of simulation
	beq		S1
	cmp     r0, #RIGHT_BLACK_BUTTON	@ stop simulation
	beq     StpS

	bne     RepeatTillBlackLeft
StrS:	
	BL StartSim		@else start simulation: void StartSim()
	@ on return here, the right black button was pressed
StpS:
	BL EndSim		@clear board: void EndSim()
EndTrafficLight:
	swi	SWI_EXIT
	
@ === Init ( )-->void
@   Inputs:	none	
@   Results:  none 
@   Description:
@ 		both LED lights on
@		8-segment = point only
@		LCD = ID only
Init:
	stmfd	sp!,{r1-r10,lr}
	@ LCD = ID on line 1
	mov	r1, #0			@ r1 = row
	mov	r0, #0			@ r0 = column 
	ldr	r2, =lineID		@ identification
	swi	SWI_DRAW_STRING
	@ both LED on
	mov	r0, #BOTH_LED	@LEDs on
	swi	SWI_SETLED
	@ display point only on 8-segment
	mov	r0, #10			@8-segment pattern off
	mov	r1,#1			@point on
	BL	Display8Segment

DoneInit:
	LDMFD	sp!,{r1-r10,pc}

@===== EndSim()
@   Inputs:  none
@   Results: none
@   Description:
@      Clear the board and display the last message
EndSim:	
	stmfd	sp!, {r0-r2,lr}
	mov	r0, #10				@8-segment pattern off
	mov	r1,#0
	BL	Display8Segment		@Display8Segment(R0:number;R1:point)
	mov	r0, #NO_LED
	swi	SWI_SETLED
	swi	SWI_CLEAR_DISPLAY
	mov	r0, #5
	mov	r1, #7
	ldr	r2, =Goodbye
	swi	SWI_DRAW_STRING  	@ display goodbye message on line 7
	ldmfd	sp!, {r0-r2,pc}
	
@ === StartSim ( )-->void
@   Inputs:	none	
@   Results:  none 
@   Description:
@ 		XXX
StartSim:
	stmfd	sp!,{r1-r10,lr}
	@THIS CODE WITH LOOP IS NOT NEEDED - TESTING ONLY NOW
	@display a sample pattern on the screen and one state number
	mov	r10,#1			@display state number on LCD
	BL	DrawState
	mov	r10,#1		@ test all patterns eventually
	BL	DrawScreen 	@DrawScreen(PatternType:R10)
	@Start at S1
	bal S1



@CAR CYCLE: MAIN ENTRY POINT OF THE PROGRMA STARTING AT S1	
@INPUTS NONE
@ENTERS FROM START SIM AND PEDESTRIAN CYCLE

Carcycle:

bal	S1

@STATE S1
S1:
	mov r8,#0	@loop counter
	mov	r0, #10			@8-segment pattern off
	mov	r1,#1		@point on
	BL	Display8Segment
	
@LIGHT CYCLE FOR S1	
S1LOOP:
	mov r10,#1	@draw State 1
	bl DrawScreen
	bl	DrawState
	@swi SWI_CheckBlue	@Check for Blue Button
	@add r5,r0,r5		@str button presses in r5
	@swi SWI_CheckBlack	@Same for black
	@add r6,r0,r6		
	mov r7,#1		@State for Ped Cycle
	mov r0,#LEFT_LED	@Set LEDS
	swi SWI_SETLED
	mov r10,#TwoSecond
	bl Wait			@Wait two seconds
	mov r0,#NO_LED
	swi SWI_SETLED
	mov r10,#2		@Draw Flashing State
	bl DrawScreen
	mov r10,#OneSecond	@Wait One Second
	bl Wait
	add r8,r8,#1		@Loop counter
	cmp r8,#4
	beq S1Check		
	bne S1LOOP

@CHECK FOR BUTTON PRESSES AND PEDSTRIANS	
S1Check:
	cmp	r6,#RIGHT_BLACK_BUTTON
	beq	StpS
	@swi SWI_CheckBlue	@Check BLue Button
	cmp	r5,#Ph1
	beq	PedCycle	@Branch to Ped Cycle if Pressed
	cmp	r5,#Ph2
	beq	PedCycle
	cmp	r5,#Ps1
	beq	PedCycle
	cmp	r5,#Ps2
	beq	PedCycle
	bal	S2		@Or to S2

@STATE S2	
S2:
	swi		SWI_CheckBlack
	cmp		r0,#RIGHT_BLACK_BUTTON
	beq	StpS
	cmp	r6,#RIGHT_BLACK_BUTTON
	beq	StpS
	mov r10,#1	@draw State 1
	bl DrawScreen
	mov r10,#2
	bl DrawState
	mov		r10,#2	@Draw State
	mov 		r7,#2		@Store as state two for Ped Cycle
	mov 		r0,#LEFT_LED
	swi 		SWI_SETLED
	cmp		r5,#Ph1		@Set LEDS
	beq		PedCycle
	cmp		r5,#Ph2		@Check branch for Ped Cycle
	beq		PedCycle
	cmp		r5,#Ps1
	beq		PedCycle
	cmp		r5,#Ps2
	beq		PedCycle
	mov 		r10,#TwoSecond	@Wait
	BL  		Wait
	mov 		r0,#NO_LED
	swi 		SWI_SETLED
	mov 		r10,#2		@Draw Flashing State
	bl DrawScreen
	mov 		r10,#OneSecond
	BL		Wait
	add 		r9,r9,#1	@Wait and Set LEDS
	cmp 		r9,#2		@Compare loop counter
	beq 		S32		@Branch to next States
	bne 		S2
@STATE 3	
S32:
	mov	r0, #10			@8-segment pattern off
	mov	r1,#0			@point on
	BL	Display8Segment
	mov r10,#3	@Draw States
	bl	DrawScreen
	bl	DrawState
	@swi		SWI_CheckBlue	@Check Blue Pressed
	@add		r5,r0,r5	@Store result
	mov 	r0,#BOTH_LED		@set LEDS
	swi 	SWI_SETLED
	mov 	r10,#TwoSecond
	BL	Wait			@Wait
	mov 	r9,#0
	bal	S4			@Reset loop counter and proceed to S4
@STATE 4
S4:
	mov	r10,#4			@Draw State
	bl	DrawScreen
	bl	DrawState
	@swi		SWI_CheckBlue	@Check Blue Button
	@add		r5,r0,r5	@ Store Result
	mov	r0,#NO_LED		@Set LEDS
	swi	SWI_SETLED
	mov 	r10,#OneSecond
	BL	Wait			@WAIT
	mov	r8,#0
	bal	S5			@Reset counter and Branch to S5
@STATE 5
S5:
	mov	r0, #10			@8-segment pattern off
	mov	r1,#1			@point on
	BL	Display8Segment
	
	mov	r10,#5			@Draw State
	bl	DrawState		@Set LEDS
	bl	DrawScreen
	mov	r0,#NO_LED
@STATE 5 CHECK LOOP
s5loop:
	@swi		SWI_CheckBlue	@Check BLue Button
	@add		r5,r0,r5	@Store Result	
	swi	SWI_SETLED		@Set LEDS
	mov	r0,#RIGHT_LED
	swi	SWI_SETLED
	mov	r10,#TwoSecond		@Wait
	bl 	Wait
	add	r8,r8,#1		@Increment counter
	cmp	r8,#3
	bne	s5loop			@Branch to next State
	beq	S6
@STATE 6
S6:
	mov	r0, #10			@8-segment pattern off
	mov	r1,#0			@point on
	BL	Display8Segment
	mov	r10,#6			@Draw State	
	bl	DrawState
	bl	DrawScreen
	@swi		SWI_CheckBlue	@Check Blue Button
	@add		r5,r0,r5	@store result
	mov 	r0,#NO_LED
	swi 	SWI_SETLED
	mov	r0,#BOTH_LED		@set LEDS
	swi	SWI_SETLED
	mov	r10,#TwoSecond
	Bl 	Wait
	bal	S7			@Branch to S7

@STATE 7
S7:
	mov	r10,#7			@Draw Screen
	bl	DrawScreen
	bl	DrawState
	@swi		SWI_CheckBlue @Check Blue
	@mov		r5,r0		@Store Result	
	mov 	r0,#BOTH_LED		@ set LEDS	
	swi 	SWI_SETLED
	mov	r10,#OneSecond
	mov     r7,#3			@Wait
	mov	r8,#0			@Reset Loop counters
	Bl	Wait
	cmp     r6, #RIGHT_BLACK_BUTTON	@Black button pressed, exit program
	beq     StpS
	cmp		r5,#Ph1		@If Button has been pressed, branch to Ped Cycle
	beq		PedCycle
	cmp		r5,#Ph2
	beq		PedCycle
	cmp		r5,#Ps1
	beq		PedCycle
	cmp		r5,#Ps2
	beq		PedCycle
	bal	S1
	
@ PEDESTRIAN CYCLE
@INPUTS
@r7== BRANCH TO EACH STATE
@TERMINATES AFTER CYCLE IS COMPLETE

PedCycle:
	mov	r0, #10			@8-segment pattern off
	mov	r1,#1			@point on
	BL	Display8Segment
	cmp     r6, #RIGHT_BLACK_BUTTON	@Stop simulation if black has been pressed
	beq     StpS
	cmp r7,#3	@branch according to entry state
	bne I1
	bal I3
	
	
@State I1
I1:

	mov 	r0,#BOTH_LED  @ Set LEDS
	swi 	SWI_SETLED
	mov 	r10,#TwoSecond
	BL 	Wait		@Wait		
	mov 	r0,#NO_LED
	swi 	SWI_SETLED
	mov 	r10,#OneSecond
	bl 	Wait
	bal	 I3		@Branch to I3

@STATE I3
I3:
	
	mov	r1,#1			@point on
	BL	Display8Segment
	mov 	r8,#0		@Loop Counter
	mov 	r0,#NO_LED
	swi	SWI_SETLED
	mov	r1,#1		@Set Walk Light
	bl	Display8Segment
	mov 	r10,#OneSecond	@Set Time Delay
	mov	r0,#SEG_A|SEG_G|SEG_F|SEG_C|SEG_D|SEG_E	@set timer countdown
	swi	SWI_SETSEG8
	Bl	Wait
	mov	r0,#SEG_A|SEG_G|SEG_F|SEG_C|SEG_D
	swi	SWI_SETSEG8
	Bl	Wait
	mov	r0,#SEG_G|SEG_F|SEG_C|SEG_B
	swi	SWI_SETSEG8
	bl	Wait
	mov	r0,#SEG_A|SEG_B|SEG_F|SEG_C|SEG_D
	swi	SWI_SETSEG8
	bl Wait
	swi     SWI_CheckBlack	@Check black at end of Pedestrian Cycle
	

	bal	P4		@Branch to P4


@STATE P4

P4:
	mov r10,#8
	bl	DrawScreen	@Draw State
	mov	r0,#SEG_A|SEG_B|SEG_F|SEG_E|SEG_D	@Set LED countdown
	swi	SWI_SETSEG8
	mov	r10,#OneSecond
	Bl	Wait
	mov	r0,#SEG_B|SEG_C
	swi	SWI_SETSEG8
	Bl	Wait
	bal P5			@Branch to P5


@STATE P5
P5:
	mov r10,#9		@Draw State
	bl	DrawScreen
	mov	r0,#SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_G @Set COuntdown timer
	swi	SWI_SETSEG8
	mov r10,#OneSecond
	Bl	Wait
	cmp     r6, #RIGHT_BLACK_BUTTON
	beq     StpS		@Exit if Pressed
	mov	r5,#0
	cmp	r7,#3
	bne	S5		@branch to s5 or s1 depending on entry state
	beq	S1
	

DoneStartSim:
	LDMFD	sp!,{r1-r10,pc}

@ ==== void Wait(Delay:r10) 
@   Inputs:  R10 = delay in milliseconds
@   Results: none
@   Description:
@      Wait for r10 milliseconds using a 15-bit timer 
@HAS BEEN MODIFIED TO POLL FOR EVENTS WHILE WAITING
Wait:
	stmfd	sp!, {r0-r2,r7-r10,lr}
	ldr     r7, =EmbestTimerMask
	swi     SWI_GetTicks		@get time T1
	and		r1,r0,r7			@T1 in 15 bits
WaitLoop:
	swi SWI_GetTicks			@get time T2
	and		r2,r0,r7
		swi		SWI_CheckBlack
	cmp		r0,#RIGHT_BLACK_BUTTON
	beq		SaveBlack
	swi		SWI_CheckBlue
	cmp		r0,#Ph1		
	beq		SaveBlue
	cmp		r0,#Ph2
	beq		SaveBlue
	cmp		r0,#Ps1
	beq		SaveBlue
	cmp		r0,#Ps2
	beq		SaveBlue			@T2 in 15 bits
	cmp		r2,r1				@ is T2>T1?
	bge		simpletimeW
	sub		r9,r7,r1			@ elapsed TIME= 32,676 - T1
	add		r9,r9,r2			@    + T2
	
	bal		CheckIntervalW

@SAVE BLACK
@SAVES IF THE BLACK BUTTON HAS BEEN PRESSED AND STORES IN R6
@R6 IS A GLOBAL VARIBLE
SaveBlack:
	mov r6,r0
	cmp		r2,r1				@ is T2>T1?
	bge		simpletimeW
	sub		r9,r7,r1			@ elapsed TIME= 32,676 - T1
	add		r9,r9,r2			@    + T2
	
	bal		CheckIntervalW
@SAVE BLUE
@SAVES IF THE BLUE PEDESTRAIN BUTTONS HAVE BEEN PRESSED
@STORES IN R7
SaveBlue:
	mov r5,r0
	cmp		r2,r1				@ is T2>T1?
	bge		simpletimeW
	sub		r9,r7,r1			@ elapsed TIME= 32,676 - T1
	add		r9,r9,r2			@    + T2
	
	bal		CheckIntervalW

simpletimeW:
		sub		r9,r2,r1		@ elapsed TIME = T2-T1
CheckIntervalW:
	cmp		r9,r10				@is TIME < desired interval?
	blt		WaitLoop
WaitDone:
	ldmfd	sp!, {r0-r2,r7-r10,pc}	

@ *** void Display8Segment (Number:R0; Point:R1) ***
@   Inputs:  R0=bumber to display; R1=point or no point
@   Results:  none
@   Description:
@ 		Displays the number 0-9 in R0 on the 8-segment
@ 		If R1 = 1, the point is also shown
Display8Segment:
	STMFD 	sp!,{r0-r2,lr}
	ldr 	r2,=Digits
	ldr 	r0,[r2,r0,lsl#2]
	tst 	r1,#0x01 @if r1=1,
	orrne 	r0,r0,#SEG_P 			@then show P
	swi 	SWI_SETSEG8
	LDMFD 	sp!,{r0-r2,pc}
	
@ *** void DrawScreen (PatternType:R10) ***
@   Inputs:  R10: pattern to display according to state
@   Results:  none
@   Description:
@ 		Displays on LCD screen the 5 lines denoting
@		the state of the traffic light
@	Possible displays:
@	1 => S1.1 or S2.1- Green High Street
@	2 => S1.2 or S2.2	- Green blink High Street
@	3 => S3 or P1 - Yellow High Street   
@	4 => S4 or S7 or P2 or P5 - all red
@	5 => S5	- Green Side Road
@	6 => S6 - Yellow Side Road
@	7 => P3 - all pedestrian crossing
@	8 => P4 - all pedestrian hurry
DrawScreen:
	STMFD 	sp!,{r0-r2,lr}
	cmp	r10,#1
	beq	S11
	cmp	r10,#2
	beq	S12
	cmp	r10,#3
	beq	S3
	cmp	r10,#4
	beq	S44
	cmp	r10,#5
	beq	S55
	cmp	r10,#6
	beq	S66
	cmp	r10,#7
	beq	S77
	cmp	r10,#8
	beq	P33
	cmp	r10,#9
	beq	P44
	@more to do
	bal	EndDrawScreen
S11:
	ldr	r2,=line1S11
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S11
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S11
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
S12:
	ldr	r2,=line1S12
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S12
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S12
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
S3:
	ldr	r2,=line1S3
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S3
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S3
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
S44:
	ldr	r2,=line1S4
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S4
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S4
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen

S55:
	ldr	r2,=line1S5
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S5
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S5
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen

S66:
	ldr	r2,=line1S6
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S6
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S6
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen

S77:

	ldr	r2,=line1S4
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S4
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S4
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen

P33:
	ldr	r2,=line1P3
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3P3
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5P3
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen


P44:
	ldr	r2,=line1P4
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3P4
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5P4
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen

@ MORE PATTERNS TO BE IMPLEMENTED
EndDrawScreen:
	LDMFD 	sp!,{r0-r2,pc}
	
@ *** void DrawState (PatternType:R10) ***
@   Inputs:  R10: number to display according to state
@   Results:  none
@   Description:
@ 		Displays on LCD screen the state number
@		on top right corner
DrawState:
	STMFD 	sp!,{r0-r2,lr}
	cmp	r10,#1
	beq	S1draw
	cmp	r10,#2
	beq	S2draw
	cmp	r10,#3
	beq	S3draw
	cmp	r10,#4
	beq	S4draw
	cmp	r10,#5
	beq	S5draw
	cmp	r10,#6
	beq	S6draw
	cmp	r10,#7
	beq	S7draw
	@ MORE TO IMPLEMENT......
	bal	EndDrawScreen
S1draw:
	ldr	r2,=S1label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S2draw:
	ldr	r2,=S2label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S3draw:
	ldr	r2,=S3label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
@ MORE TO IMPLEMENT.....
S4draw:
	ldr	r2,=S4label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S5draw:
	ldr	r2,=S5label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S6draw:
	ldr	r2,=S6label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S7draw:
	ldr	r2,=S7label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState

EndDrawState:
	LDMFD 	sp!,{r0-r2,pc}
	
@@@@@@@@@@@@=========================
	.data
	.align
Digits:							@ for 8-segment display
	.word SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_G 	@0
	.word SEG_B|SEG_C 				@1
	.word SEG_A|SEG_B|SEG_F|SEG_E|SEG_D 		@2
	.word SEG_A|SEG_B|SEG_F|SEG_C|SEG_D 		@3
	.word SEG_G|SEG_F|SEG_B|SEG_C 			@4
	.word SEG_A|SEG_G|SEG_F|SEG_C|SEG_D 		@5
	.word SEG_A|SEG_G|SEG_F|SEG_E|SEG_D|SEG_C 	@6
	.word SEG_A|SEG_B|SEG_C 			@7
	.word SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_F|SEG_G @8
	.word SEG_A|SEG_B|SEG_F|SEG_G|SEG_C 		@9
	.word 0 									@Blank 
	.align
lineID:		.asciz	"Traffic Light -- Cameron Long V00748439"
@ patterns for all states on LCD
line1S11:		.asciz	"        R W        "
line3S11:		.asciz	"GGG W         GGG W"
line5S11:		.asciz	"        R W        "

line1S12:		.asciz	"        R W        "
line3S12:		.asciz	"  W             W  "
line5S12:		.asciz	"        R W        "

line1S3:		.asciz	"        R W        "
line3S3:		.asciz	"YYY W         YYY W"
line5S3:		.asciz	"        R W        "

line1S4:		.asciz	"        R W        "
line3S4:		.asciz	" R W           R W "
line5S4:		.asciz	"        R W        "

line1S5:		.asciz	"       GGG W       "
line3S5:		.asciz	" R W           R W "
line5S5:		.asciz	"       GGG W       "

line1S6:		.asciz	"       YYY W       "
line3S6:		.asciz	" R W           R W "
line5S6:		.asciz	"       YYY W       "

line1P3:		.asciz	"       R XXX       "
line3P3:		.asciz	"R XXX         R XXX"
line5P3:		.asciz	"       R XXX       "

line1P4:		.asciz	"       R !!!       "
line3P4:		.asciz	"R !!!         R !!!"
line5P4:		.asciz	"       R !!!       "

S1label:		.asciz	"S1"
S2label:		.asciz	"S2"
S3label:		.asciz	"S3"
S4label:		.asciz	"S4"
S5label:		.asciz	"S5"
S6label:		.asciz	"S6"
S7label:		.asciz	"S7"
P1label:		.asciz	"P1"
P2label:		.asciz	"P2"
P3label:		.asciz	"P3"
P4label:		.asciz	"P4"
P5label:		.asciz	"P5"

Goodbye:
	.asciz	"*** Traffic Light program ended ***"

	.end

