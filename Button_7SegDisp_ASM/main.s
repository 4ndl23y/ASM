			PRESERVE8							; 8-битное выравнивание стека
			THUMB								; Режим Thumb (AUL) инструкций

			GET	config.s						; include-файлы
			GET	stm32f10x.s	

			AREA DATA, READONLY
				
number		DCD	 	0xFC 						; 0 начало таблицы
			DCD		0x60 						; 1
			DCD		0xDA 						; 2
			DCD	 	0xF2 						; 3
			DCD		0x66 						; 4
			DCD	 	0xB6	  					; 5
			DCD	 	0xBE						; 6
			DCD		0xE0 						; 7
			DCD	 	0xFE 						; 8
			DCD		0xF6 						; 9
number_End										; конец таблицы

			AREA RESET, CODE, READONLY
												; Таблица векторов прерываний
			DCD STACK_TOP						; Указатель на вершину стека
			DCD Reset_Handler					; Вектор сброса
				
			ENTRY								; Точка входа в программу

Reset_Handler	PROC							; Вектор сброса
			EXPORT  Reset_Handler				; Делаем Reset_Handler видимым вне этого файла


main											; Основная подпрограмма
			MOV		R7, #0x30					; 
			LDR		R8, =number					; чтение из таблицы
			LDR		R10, [R8]					; запись из таблицы 
			LDR		R9, =number					; чтение из таблицы
			LDR		R11, [R9]					; запись из таблицы 
			
RCC_enable
			MOV32	R0, PERIPH_BB_BASE + \
					RCC_APB2ENR * 32 + \
					2 * 4						; GPIOA (SEG SELECT PA8, PA9); BitAddress = BitBandBase + (RegAddr * 32) + BitNumber * 4
			MOV		R1, #1						; пишем '1`
			STR 	R1, [R0]					; загружаем значение
			
			MOV32	R0, PERIPH_BB_BASE + \
					RCC_APB2ENR * 32 + \
					3 * 4						; GPIOB (7-SEG INDICATOR: PB8-PB15, BUTTON: PB5); BitAddress = BitBandBase + (RegAddr * 32) + BitNumber * 4
			MOV		R1, #1						; пишем '1`
			STR 	R1, [R0]					; загружаем значение

set_mode			
			MOV32	R0, GPIOA_CRH				;PA8, PA9 - segment select
			MOV		R1, #0x33					;маска настроек для Output mode 50mHz, Push-Pull ("0011 0011")
			LDR		R2,	[R0]
			BFI		R2, R1, #0, #8				;PA8, PA9	!todo
			STR		R2, [R0]					;
			
			MOV32	R0,  GPIOB_CRH				; адрес порта
			MOV32	R1, #0x33333333				; 32-битная маска настроек для Output mode 50mHz, Push-Pull ("0011 0011 0011 ...")
			STR		R1, [R0]					; загрузить в регистр настройки порта
			
			MOV32	R0, GPIOB_CRL				;PB5 - button
			MOV		R1, #0x08					;0x08 = 1000	input mode
			LDR		R2, [R0]
			BFI		R2, R1, #20, #4				;PB5
			STR		R2, [R0]		

loop											; Бесконечный цикл
			MOV32	R0, GPIOA_BSRR				; адрес регистра сброса/записи 
			MOV32 	R1, #0x01000200				; установка бит для записи первого разряда (SET)
			STR 	R1, [R0]					; загружаем в порт
			
			MOV32	R0, GPIOB_ODR				; регистр записи
			LSL		R2, R10, #8					; копируем значение и сдвигаем на 8 бит влево (PIN8-15) (RESET)
			STR		R2, [R0]					; загружаем в порт
			
			BL		delay						; задержка
			
			MOV32	R0, GPIOA_BSRR				; адрес регистра сброса/записи 
			MOV32 	R1, #0x02000100				; установка бит для записи второго разряда
			STR 	R1, [R0]					; загружаем в порт
			
			MOV32	R0, GPIOB_ODR				; регистр записи
			LSL		R2, R11, #8 				; копируем значение и сдвигаем на 8 бит влево (PIN8-15)
			STR		R2, [R0]					; загружаем в порт
		
			MOV32	R0, GPIOB_IDR				; регистр чтения 
			LDR		R1, [R0]					; загружаем значение из регистра чтения в R1
			TST		R1, #(PIN5)					; сравниваем					
			BLEQ	increment					; если значение совпало (выставлен флаг) переходим в подпрограмму
			
			LDR		R10, [R8]					;записать значение из таблицы в первый разряд
			LDR		R11, [R9]					;записать значение из таблицы во второй разряд
			
			BL		delay						; задержка
			
			B 		loop						; возвращаемся к началу цикла
			
			ENDP


delay		PROC								; Подпрограмма задержки
			PUSH	{R0}						; Загружаем в стек R0, т.к. его значение будем менять
			LDR		R0, =DELAY_VAL				; псевдоинструкция Thumb (загрузить константу в регистр)
delay_loop
			SUBS	R0, #1						; SUB с установкой флагов результата
			IT 		NE
			BNE		delay_loop					; переход, если Z==0 (результат вычитания не равен нулю)
			POP		{R0}						; Выгружаем из стека R0
			BX		LR							; выход из подпрограммы (переход к адресу в регистре LR - вершина стека)
			ENDP
			
			
increment 	PROC
			SUBS	R7, #1						; задержка ;вычитаем из R7 единицу и выставляем флаг результата
			MOVEQ	R7,	#0x30					; сброс счетчика
			ADDEQ	R8, #0x04				    ; увеличить число в первом разряде на 1	
			
			CMP		R10, #0xF6					; если число в первом разряде дошло до 9
			LDREQ	R8, =number					; сбросить на 0 (начало таблицы)
			ADDEQ	R9, #0x04 					; увеличить число во втором разряде на 1

			CMP		R11, #0xDA					; если число во втором разряде дошло до 2
			LDREQ	R8, =number					; сбросить на 0
			LDREQ	R9, =number					; сбросить на 0
			
			BX 		LR							; возврат в основной цикл
			ENDP
				

			END