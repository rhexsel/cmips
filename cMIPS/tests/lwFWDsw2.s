	.include "cMIPS.s"
	.text
	.align 2
	.set noreorder
	
	.globl _start
	.ent _start
_start:	nop
	la    $17, x_DATA_BASE_ADDR # base address of RAM
	move  $30, $17		  # keep safe copy of base address
	addiu $15, $17, 4*4       # $15 <- &RAM[4]
	la    $16, x_IO_BASE_ADDR # address to print out results
	addi  $3, $0, -10         # value to print = -10
	addi  $5, $0, 4           # scan from RAM[4]..RAM[24]
        addi  $9, $0, 10          # stop when done 20 loops = +10
	sw    $15, 0($17)         # save pointer to RAM[0]
	xor   $15, $15, $30	  # mask off address, keep least sign bits
	sw    $15, 0($16)         #  and print it out
	nop
	
snd:	lw   $15, 0($17)          # reload pointer from RAM
	sw   $3, 4($15)           # store value to RAM[i+1]
	addi $3, $3, 1            # increment value
	lw   $4, 4($15)           # load back and print out value
	sw   $4, 0($16)		  #   forwarding $4
	add  $15, $15, $5         # advance pointer
	sw   $15, 0($17)          # store pointer to RAM[0]
	nop
	nop
	lw   $15, 0($17)          # reload pointer, forwarding $15
	sw   $15, 0($15)          # store pointer to RAM[i]
	nop
	lw   $15, 0($15)          # reload pointer from RAM[i]
	xor  $15, $15, $30	  # mask off address, keep least sign bits
	sw   $15, 0($16)          #  and print it out
	nop
	slt  $8,$3,$9             # done?
        bne  $8,$0,snd
	nop
	nop
	nop
        nop
        wait
        nop
	.end _start
