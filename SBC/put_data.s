@ constantes para endereços de registradores da UART

.equ UART_IBRD, 0x24     @ divisor inteiro da baude raute (taxa de transmissão)
.equ UART_FBRD, 0x28     @ divisor fracionário da baude raute (taxa de transmissão)
.equ UART_LCRH, 0x2C     @ registrador de linha de controle 
.equ UART_IMSC, 0x38     @ registrador de máscara
.equ UART_CR, 0x30       @ registrador de controle
.equ UART_FR, 0x18       @ registrador de flag
.equ UART_DR, 0x0        @ registrador de dados

@ baud rate setup

.equ IBDRT, 0b1111101000

@ lcrh setup

.equ UART_WLEN1, (1<<6)   @ MSB de comprimento de palavra
.equ UART_WLEN0, (1<<5)   @ LSB de comprimento de palavra
.equ UART_FEN, (1<<4)     @ Habilitando a FIFO
.equ STP2, (1<<3)         @ Uso de 2 bits de paradas (stop bit)

@ cr setup

.equ UART_RXE, (1<<9)       @ Habilitando recebimento de dados (RX)
.equ UART_TXE, (1<<8)	    @ Habilitando transmissão de dados (TX)
.equ UART_UARTEN, (1<<0)    @ Habilitando a UART

@ fr setup

.equ UART_TXFF, (1<<7)      @ Transmissão FIFO
.equ UART_RXFE, (1<<4)      @ Recepção FIFO

.equ BITS, (UART_WLEN1|UART_WLEN0|UART_FEN|STP2) 
.equ FINAL_BITS, (UART_RXE|UART_TXE|UART_UARTEN)

.global put_data

put_data:
		@ ldr r2, [r5, #UART_FR]
		@ tst r2, #UART_TXFF
		@ bne put_loop
		
		@ uart info is stored in r6
		mov r6, #4
		str r6, [r5, #UART_DR]
		
		bx lr

		@ b end_uart

		@ get_loop:

		@ ldr r2, [r5, #UART_FR]
		@ tst r2, #UART_RXFE
		@ bne get_loop

		ldr r3, [r5, #UART_DR]
