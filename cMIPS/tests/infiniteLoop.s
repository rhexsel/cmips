	# mips-as -O0 -EL -mips32r2
	.include "cMIPS.s"
	.text
	.align 2
	.global _start
	.global _exit
	.global exit
	.ent    _start
_start: nop
        li   $k0, 0x18000002  # RESET_STATUS, kernel mode, all else disabled
        mtc0 $k0, c0_status
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8
	li   $k0, 0x0000007c # CAUSE, no exceptions 
        mtc0 $k0, c0_cause # clear CAUSE

	nop
	jal main
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
	
	.org x_EXCEPTION_0180,0 # exception vector_180 at 0x00000060
	.global _excp_180
	.global excp_180
	.ent _excp_180
excp_180:	
_excp_180:
        mfc0  $k0, c0_cause
	sw    $k0,0($14)        # print CAUSE
	mfc0  $k0, c0_epc     # 
	sw    $k0,0($14)        # print EPC
	addiu $7,$7,-1
	addiu $15,$15,-1	# fix the invalid address
	li    $k0, 0x18000300   # disable interrupts
        mtc0  $k0, c0_status
	mfc0  $k0, c0_epc     # fix the return address
	srl   $k0,$k0,2
	sll   $k0,$k0,2
	mtc0  $k0, c0_epc
	mtc0  $zero, c0_cause # clear CAUSE
	eret
	.end _excp_180


	.org x_ENTRY_POINT,0    # normal code starts at 0x0000.0160
main:	nop
	j main
	nop
	
end:	j exit
	nop
	