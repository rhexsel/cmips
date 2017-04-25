	# mips-as -O0 -EL -mips32r2
	.include "cMIPS.s"
	.text
	.align 2
	.set noreorder
	.global _start
	.global _exit
	.global exit
	.ent    _start
        ##
        ## reset leaves processor in kernel mode, all else disabled
        ##
_start: nop
	li $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8

        ## set STATUS, cop0, no interrupts enabled
        li   $k0, 0x10000000
        mtc0 $k0, c0_status

	j  main
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
	.ent _excp_180
_excp_180:
        mfc0  $k0, c0_cause
	li    $k1, 0x18000310   # disable interrupts, user level
	sw    $k0,0($15)        # print CAUSE
        mtc0  $k1, c0_status
	mfc0  $k0, c0_epc	# advance EPC to next instruction
	addi  $k0, $k0, 4
	addiu $7,$7,-1
	mtc0  $k0, c0_epc
	eret
	.end _excp_180


_excp_0200:
        la   $k0, x_IO_BASE_ADDR
        mfc0 $k1, c0_cause
        sw   $k1, 0($k0)        # print CAUSE, flush pipe and stop simulation
        nop
        nop
        nop
        wait 0x03
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
	##===============================================================
	##
	.org x_ENTRY_POINT,0	# normal code start
main:	la $15, x_IO_BASE_ADDR
	li $7, 4
	li $5, 0

here:	sw $5, 0($15)
	addiu $5, $5, 2
	syscall
	bne   $7, $zero, here
	nop
	
	j exit
	nop
