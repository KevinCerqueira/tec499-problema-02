@ constantes para endereços de registradores da UART

.equ UART_IBRD, 0x24     @ divisor inteiro da baude raute (taxa de transmissão)
.equ UART_FBRD, 0x28     @ divisor fracionário da baude raute (taxa de transmissão)
.equ UART_LCRH, 0x2C     @ registrador de linha de controle 
.equ UART_IMSC, 0x38     @ registrador de máscara
.equ UART_CR, 0x30       @ registrador de controle
.equ UART_FR, 0x18       @ registrador de flag
.equ UART_DR, 0x0        @ registrador de dados

@ baud rate setup

.equ IBDRT, 0b1111101000 @ 1000 em binário

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

.global set_uart

set_uart:
		mov r1, #0
		str r1, [r5, #UART_CR]

		@ CLEAR_FIFO
		
		ldr r1, [r5, #UART_LCRH]
		mov r0, #1
		lsl r0, #4
		bic r1, r0
		str r1, [r5, #UART_LCRH]
		
		@ set parity, word length, stop bits

		mov r1, #BITS
		str r1, [r5, #UART_LCRH]

		@ mask interrupts

		mov r1, #0
		str r1, [r5, #UART_IMSC]

		@ set baud rate

		mov r1, #IBDRT
		lsl r1, #3

		str r1, [r5, #UART_IBRD]
		mov r1, #0
		str r1, [r5, #UART_FBRD]

		@ set rxe and txe

		ldr r1, =FINAL_BITS
		str r1, [r5, #UART_CR]
		bx lr
