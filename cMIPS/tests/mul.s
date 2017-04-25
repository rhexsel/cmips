	##
	## test instruction MUL: R[rd] <= R[rs] * R[rt]
	##
	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.globl _start
	.ent _start
_start: la $20, x_IO_BASE_ADDR
	
	##
	## let's check the simple ones: 1*5, 5*1, 1*0, 0*1
	##

	li  $3, 1
	li  $4, 5
	li  $5, (5*1)
	mul $6, $4, $3
	li  $30, '1'
	#sw  $6, 0($20)
	
	bne $5, $6, error
	nop

	li  $3, 5
	li  $4, 1
	li  $5, (5*1)
	mul $6, $4, $3
	li  $30, '2'
	#sw  $6, 0($20)
	
	bne $5, $6, error
	nop

	li  $3, 1
	li  $4, 0
	li  $5, (1*0)
	mul $6, $4, $3
	li  $30, '3'
	#sw  $6, 0($20)
	
	bne $5, $6, error
	nop

	li  $3, 0
	li  $4, 1
	li  $5, (0*1)
	mul $6, $4, $3
	li  $30, '4'
	#sw  $6, 0($20)
	
	bne $5, $6, error
	nop

	##
	## let's check the limits: 1*ffff.ffff, ffff.ffff*1
	##
	li  $3, 1
	li  $4, -1
	li  $5, (-1*1)
	mul $6, $4, $3
	li  $30, '5'
	#sw  $6, 0($20)
	
	bne $5, $6, error
	nop

	li  $3, -1
	li  $4, 1
	li  $5, (-1*1)
	mul $6, $4, $3
	li  $30, '6'
	#sw  $6, 0($20)
	
	bne $5, $6, error
	nop

	li  $3, 2
	li  $4, -1
	li  $5, (2 * -1)
	mul $6, $4, $3
	li  $30, '7'
	#sw  $6, 0($20)
	
	bne $5, $6, error
	nop

	li  $3, -1
	li  $4, 2
	li  $5, (-1 * 2)
	mul $6, $4, $3
	li  $30, '8'
	#sw  $6, 0($20)
	
	bne $5, $6, error
	nop

	li  $3, -1
	li  $4, -1
	li  $5, (-1 * -1)
	mul $6, $4, $3
	li  $30, '9'
	#sw  $6, 0($20)
	
	bne $5, $6, error
	nop

	li  $3, -1
	li  $4, -1
	li  $5, (-1 * -1)
	mul $6, $4, $3
	li  $30, 'a'
	#sw  $6, 0($20)
	
	bne $5, $6, error
	nop


ok:	li   $19, 'o'
        sw   $19, x_IO_ADDR_RANGE($20)
        li   $19, 'k'
        sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, '\n'
        sw   $19, x_IO_ADDR_RANGE($20)

	j _end
	
error:	
	li   $19, 'e'
        sw   $19, x_IO_ADDR_RANGE($20)
        li   $19, 'r'
        sw   $19, x_IO_ADDR_RANGE($20)
	sw   $19, x_IO_ADDR_RANGE($20)
        sw   $30, x_IO_ADDR_RANGE($20)
	li   $19, '\n'
        sw   $19, x_IO_ADDR_RANGE($20)

	
_end:	nop
	nop
	nop
	nop
	wait
	nop
	.end _start

	
