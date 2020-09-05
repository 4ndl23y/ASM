				PRESERVE8						; 8-битное выравнивание стека
				THUMB							; Режим Thumb (AUL) инструкций
					
				GET	stm32f10x.s	
					
STACK_TOP	EQU	0x20000100		; Вершина стека
DELAY_VAL	EQU 0x1000		; Величина задержки
	
FT1				EQU	0x20000200	;консанты 
FT2				EQU	0X20000204
FT3				EQU	0X20000208
FT4				EQU	0X2000020C
P1				EQU	0X20000202
P2				EQU	0X20000206
P3				EQU	0X2000020A
P4				EQU	0X2000020E			
				
				AREA RESET, CODE, READONLY
												; Таблица векторов прерываний
				DCD STACK_TOP					; Указатель на вершину стека
				DCD Reset_Handler				; Вектор сброса
				
				ENTRY							; Точка входа в программу

Reset_Handler	PROC							; Вектор сброса
				EXPORT  Reset_Handler			; Делаем Reset_Handler видимым вне этого файла


main			PROC							; Основная подпрограмма
				
				MOV32	R5, #FT1
				MOV		R1, #2;				;задаем значения F
				STRH 	R1, [R5]
				MOV		R1, #50;			;F1 = 50, можно подставить свои значения
				STRH 	R1, [R5, #0x04]
				MOV		R1, #100;			;F2...
				STRH 	R1, [R5, #0x08]
				MOV		R1, #250;
				STRH 	R1, [R5, #0x0C]
				
				MOV		R1, #47;			;задаем значения P
				STRH 	R1, [R5, #0x02]
				MOV		R1, #23;			;P1...
				STRH 	R1, [R5, #0x06]
				MOV		R1, #211;
				STRH 	R1, [R5, #0x0A]
				MOV		R1, #5;
				STRH 	R1, [R5, #0x0E]
				
				MOV		R4, #0				;сбросим значение R4
				MOV		R0, #100			;задаем частоту мощность на которой нужно получить в ответе F1 <= f <= F4
				
				BL 		ampFreqFunc
;loop
;				;BL 		ampFreqFunc
;				NOP
;				B		loop	
				
				ENDP	
;__________________________________________________________________________________					
					
					
					
					

ampFreqFunc 	PROC
				PUSH 	{R1-R3, R5, R6}	; сохранить в стек используемые регистры
				
				;считаем значения из таблицы
				MOV32	R5, #FT1
				LDRSH	R1, [R5]		;SH=полуслово со знаком 
				LDRSH	R2,	[R5, #0x04]
				LDRSH	R3,	[R5, #0x08]
				LDRSH	R6,	[R5, #0x0C]
				
				;найдем 2 ближайшие точки в таблице к заданной F
				; и загрузим в R5 адрес меньшей точки 
				MOV32 	R5, #FT1
				CMP 	R0, R2			;if(Fr <= FT2)		ITE
					ADDLE	R5, #0x00	;FT1
					BLE		break
				CMPGT	R0, R3			;else if(Fr <= FT3)	ITE
					ADDLE	R5, #0x04	;FT2
					BLE		break
				CMPGT	R0, R6			;else if(Fr <= FT4)	IT
					ADDLE 	R5, #0x08	;FT3						
break

				;R5 = адрес FT1(меньшей точки), возьмем значения из таблицы
				LDRSH	R1, [R5]			;FT1
				LDRSH 	R2, [R5, #0x04]		;FT2 = FT1 + 4
				LDRSH	R3, [R5, #0x02]		;P1 = FT1 + 2
				LDRSH	R6, [R5, #0x06]		;P2 = FT1 + 6
				
				;найдем R4 = P1 + (P2-P1)*(FR-FT1)/(FT2-FT1) 					
				SUB 	R5, R6, R3		;R5 = P2 - P1
				SUB 	R4, R0, R1		;R4 = FR - FT1
				MUL 	R6, R5, R4		;R6 = R5 * R4 = (P2-P1)*(FR-FT1)
				SUB 	R5, R2, R1		;R5 = FT2 - FT1
				SDIV 	R4, R6, R5		;R4 = R6 / R5 = (P2-P1)*(FR-FT1)/(FT2-FT1) деление с учетом знака
				ADD 	R4, R4, R3		;R4 = R4 + P1
				
				POP 	{R1-R3, R5, R6}	; выгрузить из стека
				BX 		LR				; возврат из подпрограммы
				ENDP
;_____________________________________________________________________________________
			END