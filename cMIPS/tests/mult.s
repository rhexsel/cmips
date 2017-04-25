	.include "cMIPS.s"
	.text
	.align 2
        .set noreorder
	.globl _start,_exit
	.ent _start

_start: nop
	la   $15, x_IO_BASE_ADDR
	li   $3, 0
	li   $4, 2
incr:	mult $3, $4
	mflo $5
	sw   $5, 0($15) # print=2,4,6,8,...,x20,x22,x24,x26,x28
	addi $3,  $3, 1
	slti $22, $5, 40
	bne  $22, $0, incr 
	nop

	li   $19, '\n'
        sw   $19, x_IO_ADDR_RANGE($15)
 
multii:	addi $4, $zero, 1
        mul  $4, 4		# translates to MULT + MFLO
        sw   $4, 0($15)

	li   $19, '\n'
        sw   $19, x_IO_ADDR_RANGE($15)
 
sllii:	addi $4, $zero, 1
        sll  $5, $4, 4
        sw   $4, 0($15)
	sw   $5, 0($15)

_exit:	nop
	nop
	nop
	nop
	wait
	.end _start
