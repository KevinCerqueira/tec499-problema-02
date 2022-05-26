.include "file_read.s"

@ MI DE SISTEMAS DIGITAIS, PROBLEMA 1, TURMA 2
@ ALUNOS: ESDRAS ABREU, GUILHERME NOBRE, KEVIN CERQUEIRA
@ testado na pi 104

@ constantes para mapeamento de memoria

.equ pagelen, 4096                @ tamanho de uma página de memoria
.equ sys_mmap2, 192               @ numero de serviço linux

.equ uart_offset, 0x20201         @ endereço base dos registradores da uart (dividido por 4096)
.equ PROT_RD, 0x1		  @ parâmetro para segurança de leitura
.equ PROT_WR, 0x2		  @ parâmetro para segurança de escrita
.equ MAP_SHARED, 1		  @ parâmetro para mapeamento da memória compartilhado

.global map_mem


map_mem: openFile devmem, S_RDWR
		mov	r4, r0 @ Movendo a leitura de arquivo para r4

		ldr r5, =uartaddr           
		ldr r5, [r5]		      
		mov r1, #pagelen
		mov r2, #(PROT_RD + PROT_WR)
		mov r3, #MAP_SHARED
		mov r0, #0

		@ mmap2 service
		mov r7, #sys_mmap2
		svc 0

		@ keep virtual address
		mov	r5,	r0	
    		bx lr

.data
devmem: .asciz "/dev/mem"
uartaddr: .word uart_offset
