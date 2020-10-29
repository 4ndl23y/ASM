            PRESERVE8                           ; 8-битное выравнивание стека
            THUMB                               ; Режим Thumb (AUL) инструкций

            GET    config.s                     ; include-файлы
            GET    stm32f10x.s    

            AREA RESET, CODE, READONLY
                                                ; Таблица векторов прерываний
            DCD STACK_TOP                       ; Указатель на вершину стека
            DCD Reset_Handler                   ; Вектор сброса
                
            ENTRY                               ; Точка входа в программу

Reset_Handler PROC                              ; Вектор сброса
            EXPORT  Reset_Handler               ; Делаем Reset_Handler видимым вне этого файла


main                                            ; Основная подпрограмма
            
RCC_enable
            MOV32   R0, PERIPH_BB_BASE + \
                    RCC_APB2ENR * 32 + \
                    2 * 4                       ; включить тактирование GPIOA; BitAddress = BitBandBase + (RegAddr * 32) + BitNumber * 4
            MOV     R1, #1                      ; пишем '1`
            STR     R1, [R0]                    ; загружаем значение
            
            MOV32   R0, PERIPH_BB_BASE + \
                    RCC_APB2ENR * 32 + \
                    3 * 4                       ; включить тактирование GPIOB; BitAddress = BitBandBase + (RegAddr * 32) + BitNumber * 4
            MOV     R1, #1                      ; пишем '1`
            STR     R1, [R0]                    ; загружаем значение

set_mode            
            ;___indicator_______________________
            MOV32   R0, GPIOB_CRL               ;
            MOV     R1, #0x33                   ;0x33 = 0011 0011
            LDR     R2, [R0]
            BFI     R2, R1, #24, #8             ;PB7, PB6
            STR     R2, [R0]
            
            MOV32   R0,  GPIOB_CRH              ; PB15-PB8
            MOV32   R1, #0x33333333             ; 32-битная маска настроек для Output mode 50mHz, Push-Pull ("0011 0011 0011 ...")
            STR     R1, [R0]                    ; загрузить в регистр настройки порта
            
            MOV32   R0, GPIOB_ODR    ;
            MOV     R1, #0x00                                    
            STR     R1, [R0]
            ;___indicator_end___________________
            
            ;___buttons_________________________
            MOV32   R0, GPIOA_CRL               ;
            MOV     R1, #0x08                   ;0x08 = 1000
            LDR     R2, [R0]
            BFI     R2, R1, #0, #4              ;A0
            STR     R2, [R0]
            
            MOV32   R0, GPIOA_CRH               ;
            MOV     R1, #0x08                   ;0x08 = 1000
            LDR     R2, [R0]
            BFI     R2, R1, #4, #4              ;A9
            STR     R2, [R0]
            ;___buttons_end_____________________
            
            
            ;___loop____________________________
loop                                            ; Бесконечный цикл
            MOV32   R0, GPIOA_IDR               ; регистр чтения 
            LDR     R1, [R0]                    ; загружаем значение из регистра чтения в R1
            TST     R1, #(PIN0)                 ; сравниваем                         
            BLEQ    increment                   ; если значение совпало (выставлен флаг) переходим в подпрограмму
            BLEQ    delay                       ; задержка
            
            MOV32   R0, GPIOA_IDR               ; регистр чтения 
            LDR     R1, [R0]                    ; загружаем значение из регистра чтения в R1
            TST     R1, #(PIN9)                 ; сравниваем                         
            BLEQ    decrement                   ; если значение совпало (выставлен флаг) переходим в подпрограмму    
            BLEQ    delay                       ; задержка
            
            B       loop                        ; возвращаемся к началу цикла
            
            ENDP
            ;___loop_end________________________


            ;__delay()__________________________
delay       PROC                                ; Подпрограмма задержки
            PUSH    {R0}                        ; Загружаем в стек R0, т.к. его значение будем менять
            LDR     R0, =DELAY_VAL              ; псевдоинструкция Thumb (загрузить константу в регистр)
delay_loop
            SUBS    R0, #1                      ; SUB с установкой флагов результата
            BNE     delay_loop                  ; переход, если Z==0 (результат вычитания не равен нулю)
            POP     {R0}                        ; Выгружаем из стека R0
            BX      LR                          ; выход из подпрограммы (переход к адресу в регистре LR - вершина стека)
            ENDP
            ;__delay()_end______________________
     
     
            ;__increment()_decrement()__________
increment   PROC                                ;GPIOB->ODR = (GPIOB->ODR << 1) + GPIO_ODR_ODR6;        
            MOV32   R0, GPIOB_ODR                
            LDR     R1, [R0]                    ; чтение
            LSL     R1, #1                      ; сдвигаем на 1 бит влево 
            ORR     R1, #0x40                   ; + 0010 0000  (PIN6) 
            STR     R1, [R0]                    ; загружаем в порт

            BX      LR                          ; возврат в основной цикл
            ENDP
                
                
decrement   PROC                                ;GPIOB->ODR = (GPIOB->ODR & ~GPIO_ODR_ODR6) >> 1;
            MOV32   R0, GPIOB_ODR                
            LDR     R1, [R0]                    ; чтение
            BFC     R1, #6, #1                  ; сброс 1 бита (6 со стороны младшего) 
            LSR     R1, #1                      ; сдвигаем на 1 бит вправо
            STR     R1, [R0]                    ; загружаем в порт
            
            BX      LR                          ; возврат в основной цикл
            ENDP      
            ;__increment()_decrement()_end______
            
            END
            