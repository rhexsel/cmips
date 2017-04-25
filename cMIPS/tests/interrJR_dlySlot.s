# Testing the internal counter is difficult because it counts clock cycles
# rather than instructions -- if the I/O or memory latencies change then
# the simulation output also changes and comparisons may be impossible.

	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.set noreorder
	.set numCy, 64
	.global _start
	.global _exit

_start: nop
        li   $k0, c0_status_reset # RESET, kernel mode, all else disabled
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

	#----------------------------------------------------------------
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
	#----------------------------------------------------------------
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
	#----------------------------------------------------------------
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
	# interrupt handler =============================================
	#
	.org x_EXCEPTION_0200,0
_excp_200:
	mfc0  $k1, c0_count  	# read current COUNT
	sw    $k1, 0($15)	#   and print it

	mfc0  $k0, c0_cause	# read CAUSE
	sw    $k0, 0($15)      	#   and print it
        li    $k0, 0            # remove IRQ
        mtc0  $k0, c0_compare

	move  $19, $24		# write part of JALR performed?
	
	li    $k0, 0x10008003   # CP0active, enable COUNT irq, EXL=1
        mtc0  $k0, c0_status
	eret
	#
	#================================================================
	#


	#----------------------------------------------------------------	
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
	li    $11, 0		# used with the identifiable NOPs

	##
	## let us cause an interrupt on a stalled JALR
	##   interrupt MUST occur on the dly-slot caused by a previous LOAD
	## JALR must be restarted and return address cannot be saved by JALR
	##   since that instruction was neither started nor completed
	##
	
	.set numCy, 12		# magic number: cycles needed to ensure
				#   interrupt hits the JALR
	
two_instr:
	li    $5, numCy  	# interrupt again in numCy cycles
	mtc0  $5, c0_compare

	# enable Counter
	mfc0  $5, c0_cause
	li    $6, 0xf7ffffff   	# CAUSE.DisableCount <= false
	and   $5, $5, $6
	mtc0  $5, c0_cause   	# enable counter
	nop

	li    $24, 0
	la    $20, x_DATA_BASE_ADDR
	la    $21, one_instr
	la    $12, err0
	sw    $12, 4($20)	# write error message to memory
	nop			# align COUNT==COMPARE with JR
	nop
	sw    $21, 0($20)	# store jump target
	li    $11, 0   		# this is a NOP
	li    $11, 1   		# this is a NOP
        lw    $23, 0($20)	# load target address to cause delay slot
	li    $11, 2   		# this is a NOP in the 2-cycle delay slot
        jalr  $24, $23		# save ra in $24
	li    $11, 3   		# this is a NOP
two:	li    $11, 4   		# this is a NOP, return address from jalr
	li    $11, 5   		# this is a NOP

one_instr:
	li    $11, 6		# this is a NOP
	
				# $19 must be zero
				# handler copies $24 -> $19
	nop			#   to ensure JALR did not change $24
	bne   $zero, $19, err2	# check if return address was changed
	nop
	
	
	##
	## let us cause an interrupt on a JR, delayed by a LW
	##
	
	.set numCy, 22		# magic number: cycles needed to ensure
				#   interrupt hits the JALR
	
	mfc0  $6, c0_count
	addiu $5, $6, numCy  	# interrupt again in numCy cycles
	mtc0  $5, c0_compare
	move  $9, $5
	
	# enable Counter
	mfc0  $5, c0_cause
	li    $6, 0xf7ffffff   	# CAUSE.DisableCount <= false
	and   $5, $5, $6
	mtc0  $5, c0_cause   	# enable counter
	nop
	nop			# align interr with JALR

	sw    $9, 0($15)     	# show old+numCycles

	li    $24, 0
	la    $20, x_DATA_BASE_ADDR
	la    $21, zero_instr
	la    $12, err0
	sw    $12, 4($20)	# write error message to memory
	sw    $21, 0($20)	# store jump target
	li    $11, 10  		# this is a NOP
	li    $11, 11  		# this is a NOP
	li    $11, 12  		# this is a NOP
        lw    $23, 0($20)	# load target address to cause 2x delay slots
        jalr  $24, $23		# save ra in $24
	li    $11, 13     	# this is a NOP
one:	li    $11, 14     	# this is a NOP, return address from jalr
	li    $11, 15     	# this is a NOP

zero_instr:
	li    $11, 16		# this is a NOP
	
				# $19 must be zero
				# handler copies $24 -> $19
	nop			#   to ensure JALR did not change $24
	bne   $zero, $19, err1	# check if return address was changed
	nop

	li    $11, 16		# this is a NOP
	li    $11, 17		# this is a NOP

	nop
	wait 0xff		# end of test
	nop
	

err2:	li   $30, 'E'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'R'
        sw   $30, x_IO_ADDR_RANGE($15)
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, ' '
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 't'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'w'
	sw   $30, x_IO_ADDR_RANGE($15)
	li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($15)
	li   $30, '\n'
	j    exit
	sw   $30, x_IO_ADDR_RANGE($15) # print a newline

err1:	li   $30, 'E'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'R'
        sw   $30, x_IO_ADDR_RANGE($15)
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, ' '
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'n'
	sw   $30, x_IO_ADDR_RANGE($15)
	li   $30, 'e'
        sw   $30, x_IO_ADDR_RANGE($15)
	li   $30, '\n'
	j    exit
	sw   $30, x_IO_ADDR_RANGE($15) # print a newline

err0:	li   $30, 'E'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'R'
        sw   $30, x_IO_ADDR_RANGE($15)
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, ' '
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'v'
	sw   $30, x_IO_ADDR_RANGE($15)
	li   $30, 'r'
        sw   $30, x_IO_ADDR_RANGE($15)
	li   $30, 'w'
        sw   $30, x_IO_ADDR_RANGE($15)
	li   $30, '\n'
	j    exit
	sw   $30, x_IO_ADDR_RANGE($15) # print a newline


