	# mips-as -O0 -EL -mips32r2
	.include "cMIPS.s"
	.text
	.align 2
	.set noreorder
	.global _start
	.global _exit
	.global exit
	.ent    _start
_start: nop
        li   $k0, 0x18000002  # RESET_STATUS, kernel mode, all else disabled
        mtc0 $k0, c0_status
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8
	li   $k0, 0x0000007c  # CAUSE_STATUS, no exceptions 
        mtc0 $k0, c0_cause  # clear CAUSE

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
	.set noreorder	
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
	mtc0  $zero, c0_cause # clear CAUSE
	eret
	.end _excp_180


	.set noat
	.set noreorder
	.org x_ENTRY_POINT,0
main:	la  $15,x_IO_BASE_ADDR

	la  $10, 0x80000000		# UNSIGNED
	la  $11, 0x80000001		# UNSIGNED

	sltu $1,$10,$11 		# $1 <- 1 as $10 < $11
	nop
	beq $1, $zero, error1
	nop

	sltu $1,$11,$10 		# $1 <- 0 as $10 !< $11
	nop
	bne $1, $zero, error2
	nop

	
	la  $10, 0x7ffffffe		# UNSIGNED
	la  $11, 0x7fffffff		# UNSIGNED

	sltu $1,$10,$11 		# $1 <- 1 as $10 < $11
	nop
	beq $1, $zero, error3
	nop

	sltu $1,$11,$10 		# $1 <- 0 as $10 !< $11
	nop
	bne $1, $zero, error4
	nop

	jal     to_stdout
	li $4, 'o'
	jal     to_stdout
	li $4, 'k'
	jal     to_stdout
	li $4, '\n'

	j exit
	nop
	
error1:	jal     to_stdout
	li $4, 'e'
	jal     to_stdout
	li $4, '1'
	jal     to_stdout
	li $4, '\n'
	j exit
	nop

error2:	jal     to_stdout
	li $4, 'e'
	jal     to_stdout
	li $4, '2'
	jal     to_stdout
	li $4, '\n'
	j exit
	nop

error3:	jal     to_stdout
	li $4, 'e'
	jal     to_stdout
	li $4, '3'
	jal     to_stdout
	li $4, '\n'
	j exit
	nop

error4:	jal     to_stdout
	li $4, 'e'
	jal     to_stdout
	li $4, '4'
	jal     to_stdout
	li $4, '\n'
	j exit
	nop


	.set IO_STDOUT_ADDR,(x_IO_BASE_ADDR + 1 * x_IO_ADDR_RANGE)
	
to_stdout:
        .set    noreorder
        .set    nomacro
        andi    $4,$4,0x00ff
        li      $2,x_IO_BASE_ADDR
        jr      $31
        sw      $4,32($2)

	