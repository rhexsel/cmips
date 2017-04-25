	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start: la   $15, x_IO_BASE_ADDR
	la   $14, x_DATA_BASE_ADDR	# table
	addi $16,$0,16*4
	add  $5,$0,$0

	la    $8, x_DATA_BASE_ADDR
	li    $9, 0xfffffff2
	li    $10, 16
fill:	sw    $9, 0($8)
	addiu $10,$10,-1
	addiu $9,$9,2
	addiu $8,$8,4
	bne   $10,$zero, fill
	nop	
	nop
	nop
snd:	add  $3,$5,$14
	lw   $6, 0($3)
	addi $5,$5,4
	sw   $6, 0($15)
	slt  $30,$5,$16
	bne  $30,$0,snd
	nop
	wait
	nop
	.end _start
# 	.data
#       .align  2
# 	
# table:	.word 0xfffffff2
# 	.word 0xfffffff4
# 	.word 0xfffffff6
# 	.word 0xfffffff8
# 	.word 0xfffffffa
# 	.word 0xfffffffc
# 	.word 0xfffffffe
# 	.word 0x00000000
# 	.word 0x00000002
# 	.word 0x00000004
# 	.word 0x00000006
# 	.word 0x00000008
# 	.word 0x0000000a
# 	.word 0x0000000c
# 	.word 0x0000000e
# 	.word 0x00000010
