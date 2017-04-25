	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.globl _start
	.ent _start
_start: nop
	la $15,x_IO_BASE_ADDR
	li $3,1
	li $4,5
	addi  $29,$0,100
	la $18,fun
	move $8,$zero
	nop
itera:	jalr $18
	sw   $31, 0($15) # $31 <- 0,fun+4
	slt  $28,$9,$29
        bne  $28,$0,itera
	j    end
fun:	add  $8,$8,$3    # $8 <-  1, 7,13,19,25,31,
	add  $8,$8,$4    # $8 <-  6,12,18,24,30,36,
	add  $9,$8,$8    # $9 <- 12,24,36,48,60,72,
	sw   $9, 4($15)
	nop
	jr $31
	nop
end:	nop
	nop
	nop
	wait
	nop
	.end _start
