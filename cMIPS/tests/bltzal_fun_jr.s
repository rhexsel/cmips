	.include "cMIPS.s"
	.text
	.align 2
	.globl _start
	.ent _start
_start: nop
	la $15,x_IO_BASE_ADDR
	li $3,1
	li $4,5
	li $20,-10
	move $8,$zero
itera:	bltzal $20, fun
	#sw   $31, 0($15) # $31 <- 0,fun+4
	bgez  $20, end
	j itera
	nop
fun:	add  $8,$8,$3    # $8 <-  1, 7,13,19,25,31,
	add  $8,$8,$4    # $8 <-  6,12,18,24,30,36,
	add  $9,$8,$8    # $9 <- 12,24,36,48,60,72,84,96,108,120
	sw   $9, 0($15)  # $9 <- c,18,24,30,3c,48,54,60,6c,78
	addi $20,$20,1
	jr $31
	nop
end:	nop
	wait
	nop
	.end _start
