	.include "cMIPS.s"
	.text
	.align 2
	.set noreorder
	.globl _start
	.ent _start

_start:	nop
	la    $15, x_DATA_BASE_ADDR
	la    $16, x_IO_BASE_ADDR
	addi  $3, $0, -10
	ori   $5, $0, 4
        addi  $9, $0, 10
	nop

snd:	sw   $3, 4($15)		# mem[i+1] <= count
	addi $3, $3, 1		# count ++
	lw   $4, 4($15)		# $4 <= mem[i+1]
	sw   $4, 0($16)		# print $4
	add  $15, $15, $5	# i++
	slt  $8, $3, $9		# reached 10 rounds?
        bne  $8, $0, snd	#    no, continue
        nop

	nop
	nop
	nop
	nop
        wait
        nop
	.end _start
