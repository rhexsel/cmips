	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.globl _start
	.ent _start
_start: la $16, x_IO_BASE_ADDR
	la $15,(x_DATA_BASE_ADDR+0x10)

	##
	## let's check stalls for add r1 ; jr r1
	##

	la $5, snd
	li $3, 1
	li $4, 5
	addi  $29, $0, 100
	move  $8, $zero
snd:	#sw   $31, 0($16)  # $31 <- 0,snd+4
	add  $8, $8, $3    # $8  <-  1, 7,13,19,25,31,
	add  $8, $8, $4    # $8  <-  6,12,18,24,30,36,
	add  $9, $8, $8    # $9  <- 12,24,36,48,60,72,
	sw   $9, 0($16)
	slt  $28, $9, $29
        beq  $28, $0, trd
	nop
	add  $9, $0, $5
	jr   $9
	nop

	##
	## now let's check stalls for lw r1 ; jr r1
	##
trd:	la   $20, x_IO_BASE_ADDR	# print out a separator
        li   $19, '\n'
        sw   $19, x_IO_ADDR_RANGE($20)

	la   $10, loop	# start of loop address
	la   $11, addr	# keep it in in memory
	sw   $10, 0($11)
	move $8, $zero
	li   $3, 1
	li   $4, 5
	
loop:	
	add  $8, $8, $3    # $8  <-  1, 7,13,19,25,31,
	add  $8, $8, $4    # $8  <-  6,12,18,24,30,36,
	add  $9, $8, $8    # $9  <- 12,24,36,48,60,72,
	sw   $9, 0($16)
	slt  $28, $9, $29
        beq  $28, $0, four
	nop
	la   $11, addr	# keep it in in memory
	lw   $9, 0($11)
	jr   $9
	nop


four:	la   $20, x_IO_BASE_ADDR	# print out a separator

	la   $10, f4	# destination address
	la   $11, addr	# keep it in in memory
	sw   $10, 0($11)
	nop

	lw    $12, 0($11)
	addiu $12, $12, 4
	addiu $12, $12, -4
	nop
	jr $12
	nop
	.align 8,0

f4:	li   $19, 'o'
        sw   $19, x_IO_ADDR_RANGE($20)
        li   $19, 'k'
        sw   $19, x_IO_ADDR_RANGE($20)
        li   $19, '\n'
        sw   $19, x_IO_ADDR_RANGE($20)


five:	la   $20, x_IO_BASE_ADDR	# print out a separator

	la   $10, f5	# destination address
	la   $11, addr	# keep it in in memory
	sw   $10, 0($11)
	nop

	lw    $12, 0($11)
	addiu $12, $12, 4
	addiu $12, $12, -4
	jr $12
	nop
	.align 8,0

f5:	li   $19, 'o'
        sw   $19, x_IO_ADDR_RANGE($20)
        li   $19, 'k'
        sw   $19, x_IO_ADDR_RANGE($20)
        li   $19, '\n'
        sw   $19, x_IO_ADDR_RANGE($20)


six:	la   $20, x_IO_BASE_ADDR	# print out a separator

	la    $10, f6	# destination address
	la    $11, addr	# keep it in in memory
	addiu $10, $10, 4
	sw    $10, 0($11)
	nop

	lw    $12, 0($11)
	addiu $12, $12, -4
	jr $12
	nop
	.align 4,0

f6:	li   $19, 'o'
        sw   $19, x_IO_ADDR_RANGE($20)
        li   $19, 'k'
        sw   $19, x_IO_ADDR_RANGE($20)
        li   $19, '\n'
        sw   $19, x_IO_ADDR_RANGE($20)

seven:	la   $20, x_IO_BASE_ADDR	# print out a separator

	la    $10, f7	# destination address
	la    $11, addr	# keep it in in memory
	sw    $10, 0($11)
	nop

	lw    $12, 0($11)
	jr $12
	nop
	.align 4,0

f7:	li   $19, 'o'
        sw   $19, x_IO_ADDR_RANGE($20)
        li   $19, 'k'
        sw   $19, x_IO_ADDR_RANGE($20)
        li   $19, '\n'
        sw   $19, x_IO_ADDR_RANGE($20)


	
	.align 4,0
_end:	nop
	nop
	wait
	nop
	.end _start

	
	.data
	.align 4
	.space 128
addr:	.word  0 
