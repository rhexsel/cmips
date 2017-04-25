	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start: li   $5, 3
	la   $15, x_IO_BASE_ADDR
	.equ tgt,(.+4+8)
	la   $6, tgt
	nop
	li   $4, 255
	nop
lasso:	mtc0  $6,c0_epc
	move  $8,$6
	sw    $8, 0($15)
	addiu $5,$5,-1
	beq   $5,$0,end
	nop
	eret
        addiu $4,$zero,4444
	j end2
	nop
end:	nop
        nop
	nop
	nop
        wait
        nop
	nop
	nop
end2:	wait 0xff
	nop
	nop
	.end _start

# 00000014
# 00000014
# 00000014
