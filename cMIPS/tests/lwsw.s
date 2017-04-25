	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start:	la    $15, (x_DATA_BASE_ADDR+0x10)
	la    $16, x_IO_BASE_ADDR
	addi  $3, $0, -10
	ori   $5, $0, 4
	nop
	
snd:	sw   $3, 4($15)
	addi $3, $3, 1
	lw   $4, 4($15)
	add  $15, $15, $5
	sw   $4, 0($16)
	bne  $3, $0, snd
	nop
	wait
	nop
	nop
	.end _start

	# fffffff6 fffffff7 fffffff8 fffffff9 fffffffa fffffffb fffffffc fffffffd fffffffe ffffffff

