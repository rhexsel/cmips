	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start: la    $15, 0		# start
	la    $29, 0x40		# end
	la    $16, x_IO_BASE_ADDR
	la    $14, x_DATA_BASE_ADDR
	addi  $3, $0, -16
	addi  $5, $0, 2
	nop

snd:	add  $3, $5, $3
	sw   $3, 0($14)		# mem[i] <= count
	addi $14, $14, 4	# i++
	lw   $3, -4($14)	# $3 <= mem[i-1]
	addi $15, $15, 4	# limit += 4
	sw   $3, 0($16)		# print count
	slt  $30, $15, $29	# limit = 0x40 ?
	bne  $30, $0, snd	#   no, continue
	nop
	wait
	nop
	.end _start
	

# fffffff2 fffffff4 fffffff6 fffffff8 fffffffa fffffffc fffffffe 00000000 00000002 00000004 00000006 00000008 0000000a 0000000c 0000000e 00000010
