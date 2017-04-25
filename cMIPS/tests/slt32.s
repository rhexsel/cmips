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
	li   $k0, 0x0000007c # CAUSE_STATUS, no exceptions 
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
	sw    $k0, 0($15)       # print CAUSE = 0000.0030
	sw    $k0, 0($15)
	sw    $k0, 0($15)
	li    $k0, 0x18000300   # disable interrupts
        mtc0  $k0, c0_status
	mfc0  $k0, c0_epc       # skip exception instruction (add)
	addiu $k0,$k0,4
	mtc0  $k0, c0_epc
	mtc0  $zero, c0_cause   # clear CAUSE
	eret
	.end _excp_180


	.org x_ENTRY_POINT,0
main:	la $20,x_DATA_BASE_ADDR # fill up memory
	la $21,0x40c15130
	sw $21,0($20)

	la $21,0x5d21660e
	sw $21,4($20)

	la $21,0xbdfac89e
	sw $21,8($20)

	la $21,0xa18ed853
	sw $21,12($20)

	la $21,0xf5fa8a27
	sw $21,16($20)
	
	la $15,x_IO_BASE_ADDR
	move $16,$20
	nop
	lw $5,0($16) 		# 4 < 5
	lw $6,4($16)
	nop
	slt $9,$5,$6
	sw  $5,0($15)
	sw  $6,0($15)
	sw  $9,0($15)

	# overflow
	lw $5,4($16) 		# 5 < 4
	lw $6,0($16)
	nop
	slt $9,$5,$6		# === overflow ===
	sw  $5,0($15)
	sw  $6,0($15)
	sw  $9,0($15)

	lw $5,0($16)
	lw $6,8($16)		# 4 < b
	nop
	slt $9,$5,$6		# === overflow ===
	sw  $5,0($15)
	sw  $6,0($15)
	sw  $9,0($15)

	lw $5,8($16)
	lw $6,0($16)		# b < 4
	nop
	slt $9,$5,$6
	sw  $5,0($15)
	sw  $6,0($15)
	sw  $9,0($15)

	lw $5,8($16)
	lw $6,12($16)		# b < a
	nop
	slt $9,$5,$6
	sw  $5,0($15)
	sw  $6,0($15)
	sw  $9,0($15)

	lw $5,12($16)
	lw $6,8($16)		# a < b
	nop
	slt $9,$5,$6
	sw  $5,0($15)
	sw  $6,0($15)
	sw  $9,0($15)

	lw $5,16($16)
	lw $6,4($16)		# f < 5
	nop
	slt $9,$5,$6
	sw  $5,0($15)
	sw  $6,0($15)
	sw  $9,0($15)

	lw $5,4($16)
	lw $6,16($16)		# 5 < f
	nop
	slt $9,$5,$6
	sw  $5,0($15)
	sw  $6,0($15)
	sw  $9,0($15)

	j exit

	