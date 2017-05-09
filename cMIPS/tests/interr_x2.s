# Objective: test two more or less simultaneous interrupts, one by internal
#  counter and one by the external counter.
#
# 1st test: hi priority (internal cntr) arrives first
# 2nd test: lo priority (external cntr) arrives first 
#           then the two alternate
#
# Testing the counters is difficult because they count clock cycles
# rather than instructions -- if the I/O or memory latencies change then
# the simulation output also changes and comparisons to the expected values
# may/will fail.


	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.set noreorder
	.set numCy, 64
	.global _start
	.global _exit

	.set ext_restart, 0xc0000000  # start ext_counter, intrr enable
	
_start: nop
        li   $k0, c0_status_reset # RESET, kernel mode, all else disabled
        mtc0 $k0, c0_status
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8
        li   $k0, 0x1000ff01      # RESET_STATUS, kernel mode, interr enabled
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
	nop
	wait	# then stop VHDL simulation
	nop


	#----------------------------------------------------------------
        .org x_EXCEPTION_0000,0
_excp_0000:        wait 0x01
        la   $k0, x_IO_BASE_ADDR
        mfc0 $k1, c0_cause
        sw   $k1, 0($k0)        # print CAUSE, flush pipe and stop simulation
        nop
        nop
        nop
        wait 0x01
        nop
	#----------------------------------------------------------------
        .org x_EXCEPTION_0100,0
_excp_0100:        wait 0x02
        la   $k0, x_IO_BASE_ADDR
        mfc0 $k1, c0_cause
        sw   $k1, 0($k0)        # print CAUSE, flush pipe and stop simulation
        nop
        nop
        nop
        wait 0x02
        nop
	#----------------------------------------------------------------
	.org x_EXCEPTION_0180,0
_excp_180:        wait 0x03
        la   $k0, x_IO_BASE_ADDR
        mfc0 $k1, c0_cause
        sw   $k1, 0($k0)        # print CAUSE, flush pipe and stop simulation
        nop
        nop
        nop
        wait 0x03
	nop

	
	
	#
	# interrupt handler =============================================
	#
	.org x_EXCEPTION_0200,0
_excp_200:
        nop			# wait a looong time to ensure both
        nop			#  interrupts are signalled
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop

	mfc0  $k0, c0_cause	# read CAUSE and
	nop
	nop # sw    $k0, 0($15)      	# print it

	andi  $k1, $k0, 0x8000  # is hi_priority active?

	beq   $k1, $zero, lo_pri # YES, handle it
	nop

hi_pri:	mtc0  $zero, c0_compare # remove IRQ

	mfc0  $k1, c0_count  	# read current COUNT
	nop # sw   $k1, 0($15)

	sll   $k0, $20, 1	# add some random-ness (main loop counter)
	addi  $k1, $k1, numCy  	# interrupt again in numCy cycles
	add   $k1, $k1, $k0
	mtc0  $k1, c0_compare

	li    $k1, 'C'		# tell it was Counter
	
	j     rf_irq		#   and return
	nop
	
lo_pri: lui   $k0, %hi(ext_restart)
	ori   $k0, $k0, numCy	# interrupt again in numCy cycles
	lui   $k1, %hi(HW_counter_addr)
	ori   $k1, $k1,%lo(HW_counter_addr)
	sw    $zero, 0($k1)	# remove IRQ
	nop
	sw    $k0, 0($k1)	# restart external counter
	li    $k1, 'e'		# tell it was external counter
	
rf_irq:	sw    $k1, 0x20($15)	# print IRQ source
	sw    $13, 0x20($15)
	
	eret
	#
	#================================================================
	#


	#----------------------------------------------------------------	
	.org x_EXCEPTION_BFC0,0
_excp_BFC0:        wait 0x04
        la   $k0, x_IO_BASE_ADDR
        mfc0 $k1, c0_cause
        sw   $k1, 0($k0)        # print CAUSE, flush pipe and stop simulation
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
	li    $11, 0		# used with the identifiable NOPs

	#
	# let us cause two interrupts
	#

	li    $5, numCy  	# interrupt again in numCy cycles
	mtc0  $5, c0_compare

	# enable Counter
	mfc0  $5, c0_cause
	li    $6, 0xf7ffffff   	# CAUSE.DisableCount <= false
	and   $5, $5, $6
	mtc0  $5, c0_cause   	# enable counter

	# start external counter
	lui   $5, %hi(ext_restart)
	ori   $5, $5, (numCy-4)  	# interrupt in numCy cycles
	lui   $6, %hi(HW_counter_addr)	#   AFTER Count=Compare interrupt
	ori   $6, $6, %lo(HW_counter_addr)
	sw    $5, 0($6)		# restart external counter

	nop

	# lets do nothing for a long time.

	li    $20, 0
	li    $21, 80

loop:	addi  $20, $20, 1
	li    $2, 1
	li    $2, 2
	li    $2, 3
	li    $2, 4
	li    $2, 5
	li    $2, 6
	bne   $20, $21, loop
	nop

	nop
	j     exit
	nop
	
	
