	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start: li   $5, 3
	li   $6, 0x11001100
	la   $15, x_IO_BASE_ADDR
	nop
lasso:	mtc0 $6,c0_status
	ei   $8
	sw    $8, 0($15)
	mfc0  $6,c0_status
	sll   $6,$6,1
	addiu $5,$5,-1
	bne   $5,$0,lasso
	nop
	li   $5, 3
	move $8,$6
	nop
	nop
lacco:	ori  $8,$8,1
	mtc0 $8,$12
	di
	mfc0 $9,c0_status
	addiu $5,$5,-1
	sw    $9, 56($15)
	sll   $8,$9,1
	bne   $5,$0,lacco
	nop
        nop
        wait
	nop
	nop
	.end _start

# 11001100
# 22002202
# 44004406
# 8800880e
# 1001101c
# 20022038
