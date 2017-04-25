	# mips-as -O0 -EL -mips32r2
	.include "cMIPS.s"
	.text
	.align 2
	.set noreorder
	.global _start, _exit
	.ent    _start

        ##
        ## reset leaves processor in kernel mode, all else disabled
        ##
_start: nop
	li  $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8
	nop

        ## set STATUS, cop0, no interrupts enabled, user mode
        li   $k0, 0x10000010
        mtc0 $k0, c0_status

	j   main
	nop
exit:	
_exit:	nop	 # flush pipeline
	nop
	nop
	nop
	nop
	wait     # then stop VHDL simulation
	nop
	nop
	.end _start



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


	
	.org x_EXCEPTION_0180,0 # exception vector_180
	.global _excp_180, excp_180
	.ent _excp_180
excp_180:	
_excp_180:
        mfc0  $k0, c0_cause
	sw    $k0, 0($15)       # print CAUSE
        li    $k0, '\n'
	sw    $k0, x_IO_ADDR_RANGE($15)  # print new-line
        mfc0  $k1, c0_epc     # advance EPC to next instruction
        addi  $k1, $k1, 4
        mtc0  $k1, c0_epc
        addiu $7, $7, -1
	eret
	.end _excp_180

	.org x_EXCEPTION_0200,0 # exception vector_200
	.global _excp_200, excp_200
	.ent _excp_200
excp_200:
_excp_200:
        ##
        ## this exception should not happen
        ##
        mfc0  $k0, c0_cause
	sw    $k0,0($15)        # print CAUSE
        li    $k1, 'e'
        sw    $k1, x_IO_ADDR_RANGE($15)
        li    $k1, 'r'
        sw    $k1, x_IO_ADDR_RANGE($15)
        li    $k1, 'r'
        sw    $k1, x_IO_ADDR_RANGE($15)
        li    $k1, '\n'
        sw    $k1, x_IO_ADDR_RANGE($15)
	eret
	.end _excp_200

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
	##=================================================================
	##
	.org x_ENTRY_POINT	# normal code start
main:	la $15,x_IO_BASE_ADDR
	li $7,4
	li $5,0
here:	sw $5, 0($15)
	addiu $5, $5,2

	break 15

	bne   $7, $zero, here
	nop

	j exit
	nop
