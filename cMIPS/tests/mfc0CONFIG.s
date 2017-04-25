	# mips-as -O0 -EL -mips32r2
	.include "cMIPS.s"
	.text
	.align 2
	.set noreorder
	.global _start, _exit
	
	.ent    _start
_start: nop
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8
	nop
	j    main
	nop
exit:	
_exit:	nop	     # flush pipeline
	nop
	nop
	nop
	nop
	wait 0 # then stop VHDL simulation
	nop
	nop
	.end _start
	
	.org x_EXCEPTION_0180,0  # exception vector_180
	.ent _excp_180
_excp_180:
        mfc0  $k0, c0_cause
	sw    $k0, 0($15)        # print CAUSE
	addiu $7, $7, -1
	li    $k0, 0x10000300    # disable interrupts
        mtc0  $k0, c0_status
	eret
	.end _excp_180


	.org x_ENTRY_POINT,0	# normal code start
main:	la $15, x_IO_BASE_ADDR
	nop
	mfc0 $6, c0_status
	sw   $6, 0($15)
	nop
	mfc0 $6, c0_cause
	sw   $6, 0($15)
	nop
	mfc0 $6, c0_config,0
	sw   $6, 0($15)
	nop
	mfc0 $6, c0_config,1
	li   $7, 0x8000007f    # mask off TLB/cache configuration
	and  $6, $6, $7        #  so changes in TLB/caches won't break this
	sw   $6, 0($15)

	j exit
	nop

