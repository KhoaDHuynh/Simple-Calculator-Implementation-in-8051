;BTL - VI XU LI
;SIMPLE CACULATOR
; Written by: HUYNH DANG KHOA		8:30PM	27/04/2022
;=====================================================
DBUS 			EQU		P0			;LCD
RS   			BIT		P2.0
RW   			BIT 	P2.2
E   			BIT		P2.1
;---------------------------
ROW				EQU		P1			;KEY PAD  
COLUMN			EQU		P2
;---------------------------
FLAG_0			BIT		00H			;Co toan tu
FLAG_1			BIT		01H			;Co khoi 1
FLAG_2			BIT		02H			;Co khoi 2
FLAG_3			BIT		03H			;Co tran khoi 1
FLAG_4			BIT		04H		  	;Co tran khoi 2
FLAG_5			BIT		05H	  		;Co ERROR SYNTAX
FLAG_6		  	BIT		06H			;Co OUT OF RANGE
FLAG_7		 	BIT		07H			;Co ANSWER

FLAG_8			BIT		08H			;Co de in ra so 0
FLAG_9			BIT		09H			;Co negative answer
;=======================================================
				ORG		0000H
				LJMP	MAIN 
				LJMP	EX0_ISR

				ORG		00BH
				LJMP	T0_ISR
		  	
				ORG 	0013H
				LJMP	EX1_ISR

				ORG 	0023H
				LJMP	SPI_ISR
;===========================================
				ORG		0030H
MAIN:			MOV		SP,#5FH	
				CALL	INITIAL
			   	;-------------------
				
				;-------------------
LOOP_00:		CALL	START
				;-------------------
LOOP_01:		
				MOV		R7,#50				;CHECK KEY PAD
LOOP_02:		CALL	CHECK_KEY
				JNC		LOOP_01
				DJNZ	R7,LOOP_02
				PUSH	ACC				
LOOP_03:		MOV		R7,#50		   	
LOOP_04:		CALL	CHECK_KEY
				JC		LOOP_03
				DJNZ	R7,LOOP_04
				POP		ACC
			    ;-------------------------
				JNB		FLAG_7,CHECK_RESET
				PUSH	ACC
				CALL	START
				MOV		A,#01H				;RESET, xoa man hinh
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT
				POP		ACC

				;----------------------------------------------------
CHECK_RESET:	CJNE	A,#8FH,CHECK_EQUAL
				MOV		A,#01H				;RESET, xoa man hinh
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT
				SJMP	LOOP_00

				;---------------------------------------------------	
CHECK_EQUAL:	CJNE	A,#8EH,SAVE_PRINT  	
											;DAU "="			
				JNB		FLAG_5,CHECK_EQUAL_2			
CHECK_EQUAL_1:	MOV		A,#01H				;Co ERROR 
				CALL	DELAY_2MS	   		;xoa man hinh
				CLR		RS			 	
				CALL	WRITE_OUT

				MOV		DPTR,#TAB_ERROR1
				CALL	PRINT_LINE

				MOV		A,#0C0H				;Chuyen con tro ve dau dong 2
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT

				MOV		DPTR,#TAB_ERROR2
				CALL	PRINT_LINE
				SETB	FLAG_7				;SET FLAG ANSWER
				JMP		LOOP_01				
				;------------------------
CHECK_EQUAL_2:	MOV		A,20H
				ANL		A,#00000111B
				CJNE	A,#03H,SPREAD_BCD_00
				SJMP	CHECK_EQUAL_1	
				;------------------------				
SPREAD_BCD_00:
				JMP		SPREAD_BCD														
 				;------------------------
CALCULATE:		
				MOV		A,30H
				CLR		ACC.7
				CJNE	A,#0AH,CALCULATE_1
				JMP		PLUS
CALCULATE_1:	CJNE	A,#0BH,CALCULATE_2
				JMP		MINUS
CALCULATE_2:	CJNE	A,#0CH,CALCULATE_3
				JMP		MULTIPLY
CALCULATE_3:	CJNE	A,#0DH,CALCULATE_4
				JMP		DIVIDE
				;-------------------------
CALCULATE_4:				
				MOV		41H,35H
				MOV		42H,36H
				MOV		43H,37H
				CALL 	PRINT_ANS
				JMP		LOOP_01
				;-------------------------------------------------
SAVE_PRINT:		JNB		ACC.7,NUM

OPERAND:		JNB		FLAG_1,ERROR	  	;MA LA TOAN HANG					   					
				JB		FLAG_2,ERROR					
				JB		FLAG_0,ERROR
				SETB	FLAG_0
				MOV		30H,A
				SJMP	OPERAND1
ERROR:			SETB	FLAG_5
OPERAND1:		CLR		ACC.7
				MOV		DPTR,#TAB_ASCII				
				CALL	PRINT_TAB
				JMP		LOOP_01	
							
				;-----------------------------------------------------
NUM:			JB		FLAG_0,KHOI2_00		   	;MA LA SO

KHOI1_00:		JNB		FLAG_3,KHOI1_01			;KHOI 1
				JMP		ERROR					;TRAN ROI

KHOI1_01:		SETB	FLAG_1
				MOV		R0,#31H
				CALL	SHIFT_3nibles
				PUSH	ACC
				ADD		A,31H
				MOV		31H,A
				DJNZ	R5,KHOI1_02
				SETB	FLAG_3
				SETB	FLAG_5
KHOI1_02:		POP		ACC	
				MOV		DPTR,#TAB_ASCII		
				CALL	PRINT_TAB
				JMP		LOOP_01
			   	;-----------------------
KHOI2_00:		JNB		FLAG_4,KHOI2_01			;KHOI 2
				JMP		ERROR					;TRAN ROI

KHOI2_01:		SETB	FLAG_2
				MOV		R0,#33H
				CALL	SHIFT_3nibles
				PUSH	ACC
				ADD		A,33H
				MOV		33H,A
				DJNZ	R4,KHOI2_02
				SETB	FLAG_4
				SETB	FLAG_5
KHOI2_02:		POP		ACC
				MOV		DPTR,#TAB_ASCII			
				CALL	PRINT_TAB
				JMP		LOOP_01

 				;-------------------------------------
PLUS:			MOV		R1,#35H
				MOV		R0,#39H
				CALL	ADD_4DIGITS
				;------------------
PLUS_1:			MOV		41H,35H
				MOV		42H,36H
				MOV		43H,37H
				MOV		44H,38H
				CALL 	PRINT_ANS
				JMP		LOOP_01
				;--------------------------------------
ADD_4DIGITS:	CLR		C			  	;CONG (R1+3)(R1+2)(R1+1)R1 <= (R1+3)(R1+2)(R1+1)R1 + (R1+3)(R0+2)(R0+1)R0 
									   	;KHONG TRAN VI 999*9 = 8991
				MOV		R6,#4
ADD_4DIGITS_1:	CALL	FULL_ADDER																		
				DJNZ	R6,ADD_4DIGITS_1
				RET	
				;---------------------			
FULL_ADDER:		MOV		A,@R1
				MOV		B,@R0
				ADDC	A,B
				DA		A
				CJNE	A,#10,$+3
				CPL		C
				ANL		A,#0FH
				MOV		@R1,A
				INC		R1
				INC		R0
				RET
				;-------------------------------------

MINUS:			MOV		R1,#38H
				MOV		R0,#3CH
				CALL	COMPARE_4DIGITS
				JC		POSITIVE
				;----------------------
				MOV		R1,#35H
				MOV		R0,#39H
				CALL	XCH_4DIGITS
				SETB	FLAG_9
				;-------------------
								
POSITIVE:		MOV		R1,#35H
				MOV		R0,#39H
				CALL	SUBB_4DIGITS								
				JMP		PLUS_1
				;----------------------
XCH_4DIGITS:
				MOV		R7,#4
XCH_4DIGITS_0:	MOV		A,@R1
				XCH		A,@R0
				MOV		@R1,A
				INC		R0
				INC		R1
				DJNZ	R7,XCH_4DIGITS_0
				RET
					
				;-----------------------
COMPARE_4DIGITS:	
				MOV		R2,#4
COM_0:			MOV		A,@R1		 			;S0 SANH 4DIGITS TU CAO DEN THAP, IF R1>=R0 THEN C=1, ELSE C=0
				CLR		C
				SUBB	A,@R0
				CJNE	A,#0,COM_1
				DEC		R0
				DEC		R1
				DJNZ	R2,COM_0
				SETB	C
				RET
COM_1:			JNB		ACC.7,COM_2
				CLR		C
				RET
COM_2:			SETB	C
				RET

				;-------------------------
SUBB_4DIGITS:							  			;SO LON - SO BE > 0
				CLR		C
				CALL	FULL_SUBTRACTOR
				CALL	FULL_SUBTRACTOR				
				CALL	FULL_SUBTRACTOR			
				CALL	FULL_SUBTRACTOR				
				RET
				;-------------------------
FULL_SUBTRACTOR:
				PUSH	PSW
				MOV		A,@R1
				MOV		B,@R0
				SUBB	A,B
				JB		ACC.7,F_S_0
				POP		PSW
				CLR		C
				SJMP	F_S_1
F_S_0:			MOV		A,@R1
				ADD		A,#10
				POP		PSW
				SUBB	A,B
				SETB	C
F_S_1:			MOV		@R1,A
				INC		R1
				INC		R0
				RET

				;--------------------------------------
MULTIPLY:		MOV		A,#0
				CJNE	A,31H,CHECK_ZERO
				CJNE	A,32H,CHECK_ZERO
ZERO:			CALL 	PRINT_ANS
				JMP		LOOP_01

CHECK_ZERO:		CJNE	A,33H,NON_ZERO_01
				CJNE	A,34H,NON_ZERO_01
				SJMP	ZERO
				;------------------------

NON_ZERO_01:	
				PUSH	3AH
				MOV		R7,39H
				MOV		R0,#41H
				CALL	SINGLE_MUL
				;-----------------
				POP		ACC
				MOV		R7,A
				CALL	SINGLE_MUL
				;-----------------
				MOV		R7,34H
				CALL	SINGLE_MUL
				;-----------------
				CALL	PRINT_ANS
				JMP		LOOP_01
			   	;-------------------
SINGLE_MUL:
				MOV		2FH,R0	  		;SAVE R0
				;-------------
				MOV		35H,#0
				MOV		36H,#0
				MOV		37H,#0
				MOV		38H,#0
				;--------------
				CJNE	R7,#0,SINGLE_MUL_0
				SJMP	SINGLE_MUL_2
				;--------------
SINGLE_MUL_0:	MOV		R0,#31H
				MOV		R1,#39H	
				CALL	SPREAD_BCD_01				
				;--------------
SINGLE_MUL_1:	MOV		R1,#35H
				MOV		R0,#39H
				CALL	ADD_4DIGITS
				DJNZ	R7,SINGLE_MUL_1
				;--------------
SINGLE_MUL_2:	MOV		R1,#35H
				MOV		R0,2FH			;LAY LAI R0
				CALL	ADD_4DIGITS
			   	
				MOV		R0,2FH
				MOV		@R0,35H
				INC		R0
				MOV		@R0,36H
				INC		R0
				MOV		@R0,37H
				INC		R0
				MOV		@R0,38H
				DEC		R0
				DEC		R0
				RET
							
				;---------------------------------------
DIVIDE:			MOV		A,#0
				CJNE	A,33H,NON_ZERO_02
				CJNE	A,34H,NON_ZERO_02
				JMP		CHECK_EQUAL_1
NON_ZERO_02:	CJNE	A,31H,NON_ZERO_03
				CJNE	A,32H,NON_ZERO_03
				SJMP	ZERO
				;-----------------------
NON_ZERO_03:		
				CALL	DIV_4DIGITS
				;-----------------------
				MOV		R7,#4
				MOV		R0,#35H
DIVIDE_0:		CJNE	@R0,#0,DIVIDE_1	   	;Remainder = 0?
				INC		R0
				DJNZ	R7,DIVIDE_0
				;------------------------
				MOV		R1,#3DH	 			;Remainder = 0 then PRINT_ANS
				MOV		R0,#41H
				CALL	XCH_4DIGITS
				CALL	PRINT_ANS
				JMP		LOOP_01
				;------------------------
DIVIDE_1:		
				MOV		R1,#3DH	 			;Remainder =! 0 
				MOV		R0,#4CH	
				CALL	XCH_4DIGITS	  		
				MOV		4BH,#0EH			;DAU '.' THAP PHAN
				;------------------------				
				MOV		R7,#11				;10 SO SAU DAU PHAY + 40H DE XET LAM TRON
				MOV		R0,#4AH
DIVIDE_2:		
				MOV		2FH,R0
				CALL	SHIFT_4DIGITS 		;REMAINDER X 10
				CALL	DIV_4DIGITS
				MOV		R0,2FH
				MOV		@R0,3DH
				DEC		R0
				DJNZ	R7,DIVIDE_2
				MOV		P3,41H
				;------------------
				MOV		A,3DH		   		;LAM TRON
				CJNE	A,#5,$+3
				CPL		C
				MOV		A,41H
				ADDC	A,#0
				MOV		41H,A
				;-----------------
				CALL	PRINT_DIV
				JMP		LOOP_01

			  	;---------------------------------
DIV_4DIGITS:	
				MOV		50H,#1
				MOV		3DH,#0
				MOV		3EH,#0
				MOV		3FH,#0
				MOV		40H,#0
				;----------------
				MOV		R1,#38H
				MOV		R0,#3CH
				CALL	COMPARE_4DIGITS
				JC		DIV_4DIGITS_1
				RET
				;-----------------
DIV_4DIGITS_1:
				MOV		R1,#3DH
				MOV		R0,#50H
				CALL	ADD_4DIGITS
				MOV		R1,#35H
				MOV		R0,#39H
				CALL	SUBB_4DIGITS
				;-------------------
				MOV		R1,#38H
				MOV		R0,#3CH
				CALL	COMPARE_4DIGITS
				JC		DIV_4DIGITS_1
				RET
				;------------------------------				
SHIFT_4DIGITS:								  ;NHAN 10 35H
				MOV		R0,#35H
				MOV		A,#0
				XCH		A,@R0
				INC		R0

				XCH		A,@R0
				INC		R0
				XCH		A,@R0
				INC		R0
				XCH		A,@R0
				RET

;----------------------------------------------
SPREAD_BCD:		
				MOV		R0,#31H
				MOV		R1,#35H
				CALL	SPREAD_BCD_01
				MOV		R0,#33H
				MOV		R1,#39H	
				CALL	SPREAD_BCD_01							
				JMP		CALCULATE

;===================================================================
SPREAD_BCD_01:	PUSH	ACC
				MOV		A,@R0
				ANL		A,#0FH
				MOV		@R1,A
				MOV		A,@R0
				ANL		A,#0F0H
				SWAP	A
				INC		R1
				MOV		@R1,A
				INC		R0
				MOV		A,@R0
				INC		R1
				MOV		@R1,A
				INC		R1
				MOV		@R1,#0
				POP		ACC
				RET

;===========================================================================
PRINT_ANS:		MOV		A,#0C0H				;Chuyen con tro ve dau dong 2
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT

				MOV		A,#0
				MOV		DPTR,#TAB_ANSWER
PRINT_ANS_0:	PUSH	ACC
				CALL	PRINT_TAB
				POP		ACC
				INC		A
				JNC		PRINT_ANS_0
				;--------------------------
				MOV		DPTR,#TAB_ASCII		 
				JNB		FLAG_9,PRINT_ANS_1	;Xet co negative answer
				MOV		A,#0BH
			    CALL	PRINT_TAB
				;---------------------------
PRINT_ANS_1:	MOV		R0,#46H
				MOV		R7,#5				;41H HIEN THI BANG TAY NEN 6 - 1 = 5
				CLR		FLAG_8
				;-----------------------				
PRINT_ANS_2:	
				MOV		A,@R0
				JB		FLAG_8,PRINT_ANS_3
				JZ		PRINT_ANS_4
PRINT_ANS_3:	CALL	PRINT_TAB
				SETB	FLAG_8
PRINT_ANS_4:	DEC		R0
				DJNZ	R7,PRINT_ANS_2
			
				MOV		A,41H
				CALL	PRINT_TAB
				SETB	FLAG_7 				;SET FLAG ANSWER
				RET

;=========================================================
PRINT_DIV:		MOV		A,#0C0H				;Chuyen con tro ve dau dong 2
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT

				MOV		A,#0
				MOV		DPTR,#TAB_DIV
PRINT_DIV_0:	PUSH	ACC
				CALL	PRINT_TAB
				POP		ACC
				INC		A
				JNC		PRINT_DIV_0
				;--------------------------------------
				MOV		DPTR,#TAB_ASCII		 
PRINT_DIV_1:	MOV		R0,#4FH
				MOV		R7,#3				;4CH HIEN THI BANG TAY
				CLR		FLAG_8
				;-----------------------				
PRINT_DIV_2:	
				MOV		A,@R0
				JB		FLAG_8,PRINT_DIV_3
				JZ		PRINT_DIV_4
PRINT_DIV_3:	CALL	PRINT_TAB
				SETB	FLAG_8
PRINT_DIV_4:	DEC		R0
				DJNZ	R7,PRINT_DIV_2
				;----------------
				MOV		A,4CH
				CALL	PRINT_TAB
				MOV		A,4BH
				CALL	PRINT_TAB
				;-----------------
				MOV		R7,#10
				MOV		R0,#41H

PRINT_DIV_5:	MOV		A,@R0
				JNZ		PRINT_DIV_6
				INC		R0
				DEC		R7
				JMP		PRINT_DIV_5
PRINT_DIV_6:	
				MOV 	R0,#4AH
PRINT_DIV_7:	MOV		A,@R0
				CALL	PRINT_TAB
				DEC		R0
				DJNZ	R7,PRINT_DIV_7

				SETB	FLAG_7 				;SET FLAG ANSWER
				RET
												
;====================================
START:			MOV		R5,#04H				;CAM SU DUNG R4, R5
				MOV		R4,#04H
				MOV		20H,#00H			;Xoa co FLAG
				MOV		21H,#00H
				MOV		R1,#48	   			;Xoa RAM noi tu 30H toi 5FH
				MOV		R0,#30H
CLR_REG:		MOV		@R0,#00H
				INC		R0
				DJNZ	R1,CLR_REG
				RET

;========================================
PRINT_LINE:		MOV		R7,#16
				MOV		A,#0
PRINT_LINE_1:	PUSH	ACC
				CALL	PRINT_TAB
				POP		ACC
				INC		A
				DJNZ	R7,PRINT_LINE_1
				RET

;=========================================
PRINT_TAB:		MOVC	A,@A+DPTR
				CJNE	A,#00H,PRINT_TAB1
				SETB	C
				SJMP	PRINT_TAB2
PRINT_TAB1:		CALL	DELAY_2MS
				SETB	RS
				CALL	WRITE_OUT
				CLR		C
PRINT_TAB2:		RET

;=========================================
CHECK_KEY:		MOV		A,#0EFH				
				MOV		R6,#4
CHECK_KEY1:		MOV		COLUMN,A
				MOV		22H,A
				MOV		A,ROW
				ANL		A,#0FH
				CJNE	A,#0FH,CHECK_KEY2
				MOV		A,22H
				RL		A
				DJNZ	R6,CHECK_KEY1
				CLR		C
				SJMP	CHECK_KEY3

CHECK_KEY2:		MOV		DPTR,#TAB1
				ADD		A,#-7
				MOVC	A,@A+DPTR
				PUSH	ACC

				MOV		A,22H
				ANL		A,#0F0H
				SWAP	A
				ADD		A,#-7
				MOVC	A,@A+DPTR
				RL		A
				RL		A
				POP		22H
				ORL		A,22H
				
				MOV		DPTR,#TAB_KEY
				MOVC	A,@A+DPTR
				SETB	C
CHECK_KEY3:		RET				
;--------------------------------------------------------------
TAB1:			DB	03H,0FFH,0FFH,0FFH,02H,0FFH,01H,00H
TAB_KEY:		DB	07H,04H,01H,8FH,08H,05H,02H,00H,09H,06H,03H,8EH,8DH,8CH,8BH,8AH
TAB_ASCII:		DB	'0123456789+-*/.'	 ;7FH = ma DEL
TAB_ERROR1:		DB	'  Syntax ERROR  '
TAB_ERROR2:		DB	'  OUT of RANGE  '
TAB_ANSWER:		DB	'        = ',00H
TAB_DIV:		DB	'= ',00H				;16 - 2 - 4 = 10 SO SAU DAU PHAY
;==========================================
SHIFT_3nibles:	PUSH	ACC				
				MOV		A,@R0
				SWAP	A
				INC		R0
				XCHD	A,@R0
				DEC		R0
				MOV		@R0,A
				POP		ACC
				RET	

;===========================================
INITIAL:		MOV		A,#38H			;Giao tiep 8bit, 2dong, 5x8dots
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT
				;----------------
				MOV		A,#01H			;Xoa man hinh
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT
				;----------------
				MOV		A,#0FH			;Hien man hinh, chop ky tu chi boi con tro
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT
				;----------------
				MOV		A,#06H			;Dich con tro sang phai (khi ghi/doc data)
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT
				;----------------
				RET
;---------------------------------------------------------------
DELAY_2MS:		MOV		TMOD,#00000001B
				MOV		TH0,#HIGH(-1989)		;2ms = 20000us
				MOV		TL0,#LOW(-1989)
				SETB	TR0
				JNB		TF0,$
				CLR		TR0
				CLR		TF0
				RET

;-----------------------------------------------------------------
WRITE_OUT:		MOV		DBUS,A
				CLR		RW
				SETB	E
				CLR		E
				RET

;==================================================================
EX0_ISR:		

				RETI
;=============================================
T0_ISR:							   

				RETI
;=============================================
EX1_ISR:	

				RETI
;=============================================				
SPI_ISR:	
			
				RETI
				END
