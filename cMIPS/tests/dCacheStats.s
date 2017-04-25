	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start: la   $15, x_DATA_BASE_ADDR
	addi $3,$0,-10
	ori  $4,$0,4
	nop
stores:	sw   $3, 0($15)
	addi $3,$3,1
	add  $15,$15,$4
        bne  $3,$0,stores
	nop  # flush pipe
	nop
	nop
	nop
	nop
	la   $15, x_DATA_BASE_ADDR
	la   $26, x_IO_BASE_ADDR
	addi $3,$0,-10
	ori  $4,$0,4
loads:	lw   $8, 0($15)
	add  $15,$15,$4
	sw   $8, 0($26)
	addi $3,$3,1
        bne  $3,$0,loads
        nop

	la   $12, x_IO_BASE_ADDR + 16*x_IO_ADDR_RANGE
	lw   $13, 0($12)
	lw   $14, 4($12)
	lw   $15, 8($12)
	lw   $16, 12($12)
	sw   $13, 0($26)
	sw   $14, 0($26)
	sw   $15, 0($26)
	sw   $16, 0($26)
	lw   $17, 16($12)
	lw   $18, 20($12)
	sw   $17, 0($26)
	sw   $18, 0($26)
	nop
	nop
	nop
	nop
        wait
	nop
	.end _start
