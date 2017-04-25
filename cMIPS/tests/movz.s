	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.globl _start
	.ent _start
_start: nop
        la $18, x_IO_BASE_ADDR
	li $3,1
	li $4,0xff
	li $27,-10
	move $8,$zero
snd:	add  $8,$8,$3      # $8 <-  1, 1, 1, 1,
	movn $12,$4,$8
	sw   $12, 0($18)   # $12 <- ram[0]=255,255,255,255,
	sub  $8,$8,$3      # $8 <-  0, 0, 0, 0,
	movz $16,$0,$8
	sw   $16, 4($18)   # $16 <- ram[32]=0,0,0,0,0,
	addi $27,$27,1
	slt  $28,$27,$zero # 29
        bne  $28,$0,snd
        nop
        wait
        nop

	j    snd
	nop
	.end _start
