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


	.org x_ENTRY_POINT,0
main:	la $14,x_IO_BASE_ADDR
	la $15,x_DATA_BASE_ADDR
	li $7,4
	la $3,0
	nop
	la $4, 0x00102030
	la $6, 0x40506070
	la $7, 0x11223344
	la $8, 0x55667788
	
	sw $4, 0($15)   # data[0] = 0010.2030
	sw $6, 4($15)   # data[1] = 4050.6070
	sw $7, 8($15)   # data[2] = 1122.3344
	sw $8, 12($15)  # data[3] = 5566.7788

	li $10, 0x01020304
	sw $10, 0($14)
	lwl $10, 8($15)  # $10 <- 4402.0304
	nop
	sw  $10, 0($14)

	
	li $10, 0x01020304
	sw $10, 0($14)
	lwl $10, 9($15)  # $10 <- 3344.0304
	nop
	sw  $10, 0($14)


	li $10, 0x01020304
	sw $10, 0($14)
	lwl $10, 10($15)  # $10 <- 2233.4404
	nop
	sw  $10, 0($14)

	
	li $10, 0x01020304
	sw $10, 0($14)
	lwl $10, 11($15)  # $10 <- 1122.3344
	nop
	sw  $10, 0($14)


	sw $zero, 0($14)
	sw $zero, 0($14)

	
	li  $10, 0x01020304
	sw  $10, 0($14)
	lwr $10, 8($15)  # $10 <- 1122.3344
	nop
	sw  $10, 0($14)

	
	li  $10, 0x01020304
	sw  $10, 0($14)
	lwr $10, 9($15)  # $10 <- 0111.2233
	nop
	sw  $10, 0($14)


	li  $10, 0x01020304
	sw  $10, 0($14)
	lwr $10, 10($15)  # $10 <- 0102.1122
	nop
	sw  $10, 0($14)

	
	li  $10, 0x01020304
	sw  $10, 0($14)
	lwr $10, 11($15)  # $10 <- 0102.0311
	nop
	sw  $10, 0($14)


	sw  $zero, 0($14)
	sw  $zero, 0($14)

	
	li  $10, 0x01020304
	lwr $10, 6($15)  # $10 <- 0102.5566
	nop
	sw  $10, 0($14)
	lwl $10, 1($15)  # $10 <- 3344.5566
	nop
	sw  $10, 0($14)


	li  $10, 0x01020304
	lwl $10, 1($15)  # $10 <- 3344.5566
	nop
	sw  $10, 0($14)
	lwr $10, 6($15)  # $10 <- 0102.5566
	nop
	sw  $10, 0($14)

	
end:	j exit
	nop
	