	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start: la    $15, x_DATA_BASE_ADDR
	la    $26, x_IO_BASE_ADDR
	addi  $3,$0, -16
	nop
snd:	sh   $3, 0($15)
	addi $3,$3,1
	lhu  $4, 0($15)
	addi $15,$15,2
	sw   $4, 0($26)
	bne  $3,$0,snd
	nop
	nop
	nop
	nop
	wait
	nop
	.end _start

	#lbu   $4, 0($15)



	