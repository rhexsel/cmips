##
## Test if multiplications are cancelled if and interrupt is taken
##
##
	
# Testing the internal counter is difficult because it counts clock cycles
# rather than instructions -- if the I/O or memory latencies change then
# the simulation output also changes and comparisons are impossible.

	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.set noreorder

	.global _start
	.global _exit

	.set TRUE,  1
	.set FALSE, 0

	.equ  numCy,0xc0000000	# enable counter
	
	.equ  PRINT,$15
	.equ  STDOUT,$17
	.equ  COUNT,$16
	.equ  NL,$13
	
_start: nop
        li   $k0, c0_status_reset # RESET, kernel mode, all else disabled
        mtc0 $k0, c0_status
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8
        li   $k0, 0x1800ff01  # RESET_STATUS, kernel mode, interr enabled
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
	##
	## stop the counter, print EPC, and return
	##
	.org x_EXCEPTION_0200,0
_excp_200:
	lw    $k0,  0(COUNT)	# read the counter and disable counting
	la    $k1, 0x3ffffff
	and   $k0, $k1, $k0
	sw    $k0, 0(COUNT)	# stop the counter
	
	mfc0  $k1, c0_epc  	# read EPC -- this is a "return value", keep it!
	# sw    $k1, 0(PRINT)
	addi  $k0, $k1, 4	# skip interrupted instruction
	nop
	mtc0  $k0, c0_epc  	# write new EPC
	ehb

	eret
	#
	# end of  interrupt handler ----------------------------------------
	#
	
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
        ## main -----------------------------------------------------------
        ##
	.org x_ENTRY_POINT,0
main:	la    PRINT, x_IO_BASE_ADDR
	la    STDOUT, (x_IO_BASE_ADDR + 1 * x_IO_ADDR_RANGE)
	la    COUNT, HW_counter_addr
 	li    NL, '\n'

	sw   NL, 0(STDOUT)	# print a new line
	##
	## counter will interrupt right on the MULT instruction
	##   MULT is cancelled by the interrupt
	##   handler skips the interrupted instruction
	##   result of the anulled MULT must be zero, as it was cancelled
	##
	li   $20, 2		# multiply 2x3
	li   $21, 3
	mtlo $zero		# clear LO
	
	li   $5, (numCy+4)  	# interrupt in 4+4 cycles
	sw   $5, 0(COUNT)	# it takes four cycles to start counting
	nop			# 4 pipestages
	nop
	nop

	nop			# counter starts counting
	nop
	nop
_mult:	mult $20, $21		# interrupts on the 4th cycle
				# this MULT is cancelled by the handler
	mflo $22
	sw   $22, 0(PRINT)	# should print zero

	la   $4, _mult
	nop
	nop
	bne  $4, $k1, _err1	# error if EPC != _mult
	nop

	jal  ok
	nop
	
	nop			# clear out the pipeline
	nop
	nop
	nop
	nop
	

	##
	## counter will interrupt right on the MTC0 instruction
	##   the MTC0 disables the interrupts 
	##   MTC0 is NOT cancelled by the interrupt
	##   handler skips the interrupted instruction
	##   STATUS.IE must be zero and interrupt is cancelled
	##
        li   $6, c0_status_reset # RESET, kernel mode, all else disabled
	
	li   $5, (numCy+4)  	# interrupt in 4+4 cycles
	sw   $5, 0(COUNT)	# it takes four cycles to start counting
	nop			# 4 pipestages
	nop
	nop

	nop			# counter starts counting

				# change to STATUS must be in EXEC pipestage
_mtc0:	mtc0 $6, c0_status	# this MUST NOT be cancelled by the interrupt

	nop
	nop
	lw   $7, 0(COUNT)	# was the IRQ taken?  If so, 
	la   $4, (numCy+4)	# value in count must be 0xc000.0004
	nop
	nop
	bne  $4, $7, _err2	# error if COUNTER != 4
	nop

	jal  ok
	nop
	
here:	j exit
	nop

	

_err1:	# interrupt was on the wrong instruction
	li   $30, 'n'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 't'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'M'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'U'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'L'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'T'
        sw   $30, x_IO_ADDR_RANGE($15)
        j exit
        sw   NL,  x_IO_ADDR_RANGE($15) # print a newline

_err2:	# interrupt was on the wrong instruction
	li   $30, 'w'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'a'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 's'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, ' '
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'I'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'R'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'Q'
        sw   $30, x_IO_ADDR_RANGE($15)
        j exit
        sw   NL,  x_IO_ADDR_RANGE($15) # print a newline


        # nothing wrong
ok:     li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'k'
        sw   $30, x_IO_ADDR_RANGE($15)
        sw   $13, x_IO_ADDR_RANGE($15) # print a newline
        jr   $ra
        sw   $13, x_IO_ADDR_RANGE($15) # print a newline
