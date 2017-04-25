	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start: li   $5, 3
	li   $6, 0x11001100
	la   $15, x_IO_BASE_ADDR
	nop
lasso:	mtc0 $6,c0_epc
	addiu $5,$5,-1
	mfc0  $8,c0_epc
	sw    $8, 0($15)
	sll   $6,$6,1
	bne   $5,$0,lasso
	nop
	nop
        nop
        wait
	nop
	nop
	.end _start

# 11001100
# 22002200
# 44004400
	
