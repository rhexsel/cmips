##
## test if CP0 register COUNT counts monotonically and
##	if interrupts are generated when COUNT == COMPARE
##
	
# Testing the internal counter is difficult because it counts clock cycles
# rather than instructions -- if the I/O or memory latencies change then
# the simulation output also changes and comparisons are impossible.

	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.set noreorder
	.set numCy, 64
	.global _start
	.global _exit

_start: nop
        li   $k0, c0_status_reset # RESET, user mode, all else disabled
        mtc0 $k0, c0_status
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8
        li   $k0, 0x1000ff01  # RESET_STATUS, kernel mode, interr enabled
        mtc0 $k0, c0_status
        li   $k0, c0_cause_reset  # RESET, disable counter
        mtc0 $k0, c0_cause

	la   $15,x_IO_BASE_ADDR
	nop
	j    main
	nop
exit:	
_exit:	nop	# flush pipeline
	nop
	nop
	nop
	nop
	wait	# then stop VHDL simulation
	nop
	nop

	
        .org x_EXCEPTION_0000,0
_excp_0000:
        la   $k0, x_IO_BASE_ADDR
        mfc0 $k1, c0_cause
        sw   $k1, 0($k0)        # print CAUSE, flush pipe and stop simulation
        nop
        nop
        nop
        wait 0x01
        nop
        .org x_EXCEPTION_0100,0
_excp_0100:
        la   $k0, x_IO_BASE_ADDR
        mfc0 $k1, c0_cause
        sw   $k1, 0($k0)        # print CAUSE, flush pipe and stop simulation
        nop
        nop
        nop
        wait 0x02
        nop
	.org x_EXCEPTION_0180,0
_excp_180:
        la   $k0, x_IO_BASE_ADDR
        mfc0 $k1, c0_cause
        sw   $k1, 0($k0)        # print CAUSE, flush pipe and stop simulation
        nop
        nop
        nop
        wait 0x03
	nop

	#
	# interrupt handler ------------------------------------------------
	#
	.org x_EXCEPTION_0200,0
_excp_200:
	mfc0  $k1, c0_count  	# read current COUNT
	#sw    $k1, 0($15)
	addi  $22, $22, numCy   # interval elapsed?
	#sw    $22, 0($15)     	# show old+numCycles
	slt   $k0, $22, $k1     # COUNT >= old+numcy ?
	beq   $k0, $zero, err3
	nop

	addiu $k1, $k1, numCy 	# interrupt again in numCy cycles
	mtc0  $k1, c0_compare   # write to COMPARE clears the interrupt
	#sw    $k1, 0($15)      	# show new limit
	
	li    $30, 'i'
        sw    $30, x_IO_ADDR_RANGE($15)
	li    $30, 'n'
        sw    $30, x_IO_ADDR_RANGE($15)
	li    $30, 't'
        sw    $30, x_IO_ADDR_RANGE($15)
	sw    $13, x_IO_ADDR_RANGE($15) # blank line

	mfc0  $k0, c0_cause	# read CAUSE and
	lui   $k1, 0x7fff	#   mask-off branch-delay bit
	ori   $k1, $k1, 0xffff
	and   $k0, $k0, $k1
	sw    $k0, 0($15)      	# print CAUSE
	
	eret
	nop
	nop
err3:	
	li    $30, 'i'
        sw    $30, x_IO_ADDR_RANGE($15)
	li    $30, 'n'
        sw    $30, x_IO_ADDR_RANGE($15)
	li    $30, 't'
        sw    $30, x_IO_ADDR_RANGE($15)
	li    $30, 'E'
        sw    $30, x_IO_ADDR_RANGE($15)
	li    $30, 'r'
        sw    $30, x_IO_ADDR_RANGE($15)
	li    $30, 'r'
        sw    $30, x_IO_ADDR_RANGE($15)
	sw    $13, x_IO_ADDR_RANGE($15) # blank line
	sw    $22, 0($15)

	mfc0  $k0, c0_status
	li    $k1, 0xfffffffe   	# disable interrupts
	and   $k0, $k0, $k1
        mtc0  $k0, c0_status
	ehb
	eret
	nop
	nop
	

        .org x_EXCEPTION_BFC0,0
_excp_BFC0:
        la   $k0, x_IO_BASE_ADDR
        mfc0 $k1, c0_cause
        sw   $k1, 0($k0)        # print CAUSE, flush pipe and stop simulation
        nop
        nop
        nop
        wait 0x04
        nop


        ##
        ##-----------------------------------------------------------------
        ##
	.set TRUE,  1
	.set FALSE, 0
	
	.org x_ENTRY_POINT,0
main:	la    $15, x_IO_BASE_ADDR
 	li    $13, '\n'

	addiu $5,$zero, numCy  	# interrupt again in numCy cycles
	mtc0  $5,c0_compare

	# enable Counter
	mfc0  $5,c0_cause
	li    $6,0xf7ffffff    	# CAUSE(DisableCount) <= 0
	and   $5,$5,$6
	mtc0  $5,c0_cause   	# enable counter

	li    $20, TRUE		# counting is monotonic?
	li    $21, 0		# old value
	li    $22, 0		# old value for interrupts
	
	addiu $11,$12,1        	# this is a NOP

	#
	# check if counting increases monotonically
	#
here:	addiu $11, $12, 2	# this is a NOP
	mfc0  $16, c0_count   # read current COUNT
	#sw    $16, 0($15)	# print current COUNT
	slt   $1, $21, $16	# old < new?
	beq   $1, $zero, err1	# no, stop simulation
	nop

	move  $21, $16          # old <- new
	
	slti  $1, $16, 0x200   	# COUNT > 0x200 => stop counter and program
	beq   $1, $zero, there
	addiu $11,$12,3		# this is a NOP
	addiu $11,$12,4		# this is a NOP
	b here
	addiu $11,$12,5		# this is a NOP

	#
	# check if the counter stops
	#
there:	sw    $13, x_IO_ADDR_RANGE($15) # print a newline
	mfc0  $5,c0_cause
	lui   $6,0x0880        	# CAUSE(DisableCount) <= 1
	or    $5, $5, $6
	mtc0  $5, c0_cause   	# disable counter
	addiu $11,$12,6		# this is a NOP
	mfc0  $18, c0_count  	# print current COUNT
	#sw    $18, 0($15)
	addiu $11,$12,7		# this is a NOP
	addiu $11,$12,8		# this is a NOP
	addiu $11,$12,9		# this is a NOP
	addiu $11,$12,10	# this is a NOP
	mfc0  $19, c0_count  	# print current COUNT
	#sw    $19, 0($15)
	bne   $18, $19, err2    # did counter stop?
	nop

	# nothing wrong
ok:	li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'k'
        sw   $30, x_IO_ADDR_RANGE($15)
	sw   $13, x_IO_ADDR_RANGE($15) # print a newline
	j exit
	sw   $13, x_IO_ADDR_RANGE($15) # print a newline

	
	# non-monotonic
err1:	li   $30, 'n'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'n'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'M'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'n'
        sw   $30, x_IO_ADDR_RANGE($15)
	j exit
	sw   $13, x_IO_ADDR_RANGE($15) # print a newline

	
	# counter did not stop
err2:	li   $30, 'n'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 't'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'S'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 't'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'p'
        sw   $30, x_IO_ADDR_RANGE($15)
	j exit
	sw   $13, x_IO_ADDR_RANGE($15) # print a newline

