	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.globl _start
	.ent _start
_start: la    $15, (x_DATA_BASE_ADDR+0x10)
	la    $16, x_IO_BASE_ADDR
	addi  $3, $0, 10
	ori   $5, $0, 2		# count = 2
        addi  $29, $0, 800
	sw    $5, -4($15)	# mem[i-1] <= count
	nop
snd:	add  $3, $5, $3		# $3 <= count + 10
	sw   $3, 4($15)		# mem[i+1] <= $3
	lw   $4, -4($15)	# $4 <= mem[i-1]
	lw   $9, 4($15)		# $9 <= mem[i+1]
	add  $5, $5, $5		# count *= 2 : 2,4,8,16,32,64,128,256,512,1024
	sw   $9, 0($16)		# print: 10,12,16,24,40,72,136,264,520,1032
        slt  $28, $9, $29	# less than 800?
        bne  $28, $0, snd	#   yes, continue
	nop
	nop
	nop
	wait
	nop	
	.end _start

# 0000000c 00000010 00000018 00000028 00000048 00000088 00000108 00000208 00000408
