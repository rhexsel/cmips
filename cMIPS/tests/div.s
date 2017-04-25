	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start: nop
	la   $15,x_IO_BASE_ADDR
	li   $3,3
	li   $4,3
rep:	sw   $4, 0($15)           # IO[0]=3,5,7,9,11,13,15
	div  $0,$4,$3
	nop
	nop
	mflo $5
	sw   $5, 0($15)  # QUOC IO[0]=1,1,2,3,3,4,5
	mfhi $6
	sw   $6, 4($15)  # REM  IO[60]=0,2,1,0,2,1,0
	addi $4,$4,2
	slti $22,$4,16
	bne  $22,$0,rep
	nop
	nop
	nop
	nop
	wait
	.end _start
