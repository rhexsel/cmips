	# mips-as -O0 -EL -mips32r2
	.include "cMIPS.s"
	.text
	.align 2
	.set noreorder
	.global _exit, _start
	.ent    _start
_start: nop
        li   $k0, 0x10000002  # RESET_STATUS, kernel mode, all else disabled
        mtc0 $k0, c0_status
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8
	li   $k0, 0x0000007c  # CAUSE_STATUS, no exceptions 
        mtc0 $k0, c0_cause  # clear CAUSE
	nop
	j    main
	nop
exit:	
_exit:	nop	# flush pipeline
	nop
	nop
	nop
	nop
	wait  	# then stop VHDL simulation
	nop
	nop
	.end _start

	
	.org x_EXCEPTION_0180,0 # exception vector_180
	.ent _excp_180
_excp_180:
        mfc0  $k0, c0_cause
	sw    $k0,0($15)        # print CAUSE
	addiu $7,$7,-1
	li    $k0, 0x10000310   # disable interrupts except SW0,1, user mode
        mtc0  $k0, c0_status
	mtc0  $zero, c0_cause # clear CAUSE
	eret
	.end _excp_180


	.org x_ENTRY_POINT,0	# normal code start
main:	la $15,x_IO_BASE_ADDR
	li $7,4                	# do four rounds
	li $5,0
here:	sw $5, 0($15)

	li   $6, 0x10000302   	# kernel mode, disable interrupts
	mtc0 $6,c0_status
	li   $6, 0x0000ffff   	# write garbage to CAUSE, assert sw interr 0,1
	mtc0 $6,c0_cause

	addiu $5,$5,2
	
	li   $6, 0x10000311   	# user mode, enable sw interrupts
	mtc0 $6,c0_status
	nop
	nop
	nop
	nop		      	# wait for software interrupt
	
	bne   $7,$zero, here
	nop
	
	j exit
	nop
