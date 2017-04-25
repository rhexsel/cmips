# Objective: test function to print "kernel messages" to stdout
#
#  void cmips_kmsg( $k1 )
#
	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.set noreorder
	.global _start
	.global _exit

        .set c0_cause_rst, 0x0880007c # disable counter, separate IntVector
	
_start: nop
        li   $k0, c0_status_reset # RESET, kernel mode, all else disabled
        mtc0 $k0, c0_status
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8
        li   $k0, 0x1000ff01      # RESET_STATUS, kernel mode, interr enabled
        mtc0 $k0, c0_status
        li   $k0, c0_cause_rst    # RESET, disable counter
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
	mfc0  $k0, c0_cause	# read CAUSE and
	nop
	sw    $k0, 0($15)      	# print it, should never get to this point

	li    $k0, 0x1000f001   # CP0active, enable COUNT interrupts
        mtc0  $k0, c0_status
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
	.extern cmips_kmsg
	
	.org x_ENTRY_POINT,0
main:	la    $15, x_IO_BASE_ADDR

	jal   cmips_kmsg
 	li    $k1, 0
	
	jal   cmips_kmsg
	li    $k1, 1
	
	nop
	nop
	j     exit
	nop


	.include "handlers.s"