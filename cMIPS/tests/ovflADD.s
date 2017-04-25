	###	
	### cannot be run on processor that traps on overflow
	###
	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.globl _start
	.ent _start
_start: nop
	la  $15, x_IO_BASE_ADDR
	# no overflow
	li  $3,0x7FFFFFFF
	li  $4,0x00000001
	add $5,$3,$4
	nop
	sw  $5, 0($15)		# 0x8000.000
	nop
	nop
	li   $6,0xFFFFFFFe
	addi $7,$6,1
	nop
	sw   $7, 0($15)		# 0xffff.ffff
	nop
	sw  $0, 0($15)
	sw  $0, 0($15)
	nop
	# no overflow
	li   $3,0x7FFFFFFF
	li   $4,0x00000001
	addu $5,$3,$4
	nop
	sw   $5, 0($15)		# 0x8000.000
	nop
	nop
	li    $6,0xFFFFFFFe
	addiu $7,$6,1
	nop
	sw    $7, 0($15)	# 0xffff.ffff
	nop
	sw  $0, 0($15)
	sw  $0, 0($15)
	# overflow, signed
	li   $3,0xFFFFFFFF
	li   $4,0x00000001
	add  $5,$3,$4
	nop
	sw   $5, 0($15)		# 0x0000.0000
	nop
	nop
	li   $6,0xFFFFFFFe
	addi $7,$6,2
	nop
	sw   $7, 0($15)		# 0x0000.0000
	nop
	sw  $0, 0($15)
	sw  $0, 0($15)
	# overflow, unsigned
	li   $3,0xFFFFFFFF
	li   $4,0x00000001
	addu $5,$3,$4
	sw   $5, 0($15)		# 0x0000.000
	nop
	nop
	li    $6,0xFFFFFFFe
	addiu $7,$6,2
	sw    $7, 0($15)	# 0x0000.0000
	nop
	sw  $0, 0($15)
	sw  $0, 0($15)
	nop
	nop
	nop
	nop
	wait
	nop
	.end _start

	