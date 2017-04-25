	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start: la    $15, x_DATA_BASE_ADDR
	la    $16, x_IO_BASE_ADDR
	addi  $3,$0, 138
	addi  $20,$0, 124
	addi  $9,$0,5
	ori   $5,$0,4
	nop
snd:	sb   $3, 0($15)
	sb   $9, 1($15)
	addi $3,$3,-1
	addi $9,$3,-16
	lb   $4, 0($15)
	lb   $8, 1($15)
	addi $15,$15,1
	sw   $4, 0($16)
	sw   $8, 4($16)
	bne  $3,$20,snd
	nop
	nop
	nop
	nop
	wait
	nop
	.end _start

	#lbu   $4, 0($15)

# ffffff8a 00000005 ffffff89 00000079 ffffff88 00000078 ffffff87 00000077 ffffff86 00000076 ffffff85 00000075 ffffff84 00000074 ffffff83 00000073 ffffff82 00000072 ffffff81 00000071 ffffff80 00000070 0000007f 0000006f 0000007e 0000006e 0000007d 0000006d

	