	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start: la   $15, x_DATA_BASE_ADDR
	addi $3,$0,-10
	ori  $4,$0,1
	nop
stores:	sb   $3, 0($15)
	addi $3,$3,1
	add  $15,$15,$4
        bne  $3,$0,stores
	nop  # flush pipe
	nop
	nop
	nop
	nop
	la   $15, x_DATA_BASE_ADDR
	la   $26, x_IO_BASE_ADDR
	addi $3,$0,-10
	ori  $4,$0,1
loads:	lb   $8, 0($15)
	add  $15,$15,$4
	sb   $8, 0($26)
	addi $3,$3,1
	add  $26,$26,$4
        bne  $3,$0,loads
        nop
	nop
	nop
	nop
	nop
        wait
        nop
	nop
	.end _start
