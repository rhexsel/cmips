	# mips-as -O0 -EL -mips32r2
	.include "cMIPS.s"
	.text
	.align 2
	.set noreorder
	.global _start, _exit,
	.ent    _start
_start: nop
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8

        ## set STATUS, cop0, no interrupts enabled, user mode
        li   $k0, 0x10000010
        mtc0 $k0, c0_status

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
	.end _start
	
        .set noreorder
        .set noat
	
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

	.org    x_EXCEPTION_0180,0 # exception vector_180
	.global excp_180
	.ent    excp_180
excp_180:
        li    $k0, '['              # to separate output
        sw    $k0, x_IO_ADDR_RANGE($14)
        li    $k0, '\n'
        sw    $k0, x_IO_ADDR_RANGE($14)

        mfc0  $k0, c0_cause
	sw    $k0, 0($14)       # print CAUSE

	mfc0  $k0, c0_epc       # fix return address
	sw    $k0, 0($14)       # print EPC
        addiu $k1, $zero, -4    # -4 = 0xffff.fffc
        and   $k1, $k1, $k0     # fix the invalid address
	mtc0  $k1, c0_epc

	li $k0, ']'              # to separate output
        sw $k0, x_IO_ADDR_RANGE($14)
        li $k0, '\n'
        sw $k0, x_IO_ADDR_RANGE($14)

	addiu $7, $7, -1
	eret
	.end excp_180

        .org x_EXCEPTION_0200,0
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
	## 
	##
	.org 0x00000800,0	# well above normal code start
main:	la $14, x_IO_BASE_ADDR  # used by handler
	la $15, x_IO_BASE_ADDR
	li $7, 3
	la $3, here		# address for misaligned fetches
	nop

here:	sw    $3, 0($15)
	nop                     # 4th jr is to this address
	beq   $7, $zero, end
	nop
	addiu $3, $3, 1
	nop			# do not stall on $3
	nop                     #   two nops needed here
	jr    $3		# jump to misaligned addresses
	nop
	nop
	nop
end:	j exit
	nop
