	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.set noreorder
	.globl _start
	.ent _start
	
_start: nop
	la $15,x_IO_BASE_ADDR
	li $3,1
	li $4,5
	la $29, (x_DATA_BASE_ADDR + 1024)	# space for stack
	
	li  $9,1
	li  $19, 100
	
itera:	jal fun
	sw   $31, 0($15) # $31 <- 0,fun+4
	slt  $18, $9, $19
        bne  $18, $0, itera
	nop
	j    end
	nop

fun:	addiu $sp, $sp, -8
	sw    $ra, 0($sp)
	add   $9, $9, $9
	move  $ra, $zero
	addiu $sp, $sp, +8
	lw    $ra, -8($sp)
	jr    $ra
	sw    $9, 0($15)

	
end:	nop
	nop
	nop
	nop
	nop
	wait 
	nop
	nop
	.end _start
