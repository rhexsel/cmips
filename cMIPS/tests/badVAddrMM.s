	# mips-as -O0 -EL -mips32r2
	.include "cMIPS.s"
	.text
	.set noreorder
	.align 2
	.global _start, _exit
	.ent    _start
_start: nop
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8

        ## set STATUS, cop0, no interrupts enabled, user mode
        li   $k0, c0_status_normal
        mtc0 $k0, c0_status

        j    main
        nop

exit:	
_exit:	nop	# flush pipeline
	nop
	nop
	nop
	nop
	wait    # then stop VHDL simulation
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


	.org x_EXCEPTION_0180,0  # exception vector_180
	.global excp_180
	.ent    excp_180
excp_180:
	li $k0, '['              # to separate output
	sw $k0, x_IO_ADDR_RANGE($14)
	li $k0, '\n'             # to separate output
	sw $k0, x_IO_ADDR_RANGE($14)
	
        mfc0  $k0, c0_cause      # print CAUSE
	sw    $k0, 0($14)

	mfc0  $k0, c0_epc      	 # print EPC
	sw    $k0, 0($14)

	mfc0  $k0, c0_badvaddr   # print BadVAddr
	xor   $k0, $k0, $30	 # mask off top address bits,
	sw    $k0, 0($14)	 #    show only bits that differ

	addiu $k1, $zero, -4	 # -4 = 0xffff.fffc
	and   $15, $15, $k1	 # fix the invalid address

	li $k0, ']'              # to separate output
	sw $k0, x_IO_ADDR_RANGE($14)
	li $k0, '\n'             # to separate output
	sw $k0, x_IO_ADDR_RANGE($14)
	
	addiu $7, $7, -1	 # repetiton counter
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
	##==============================================================
	##
	.org 0x00000800,0	# well above normal code 
	##
	##
	## do 4 stores: 1st aligned, 2nd, 3rd, 4th misaligned,
	##   hence 3 exceptions of type AddrError store=x14
	##
	
main:	la $14, x_IO_BASE_ADDR  # used by exception handler
	move $30, $14		# keep safe copy of base address for handlr
	la $15, x_IO_BASE_ADDR  # used to generate misaligned references
	li $7, 3                # do 4 rounds for each type of exception
	li $3, 0                # exception handler decreaments $7
	nop

here:	nop
	sw    $3, 0($15)        # causes 3 exceptions: addr&{01,10,11}
	addiu $3, $3, 1         # 1st is aligned, 2nd,3rd,4th misaligned
	beq   $7, $zero, next
	nop
	j here
	addu  $15, $15, $3

	
next:	li $29, '\n'            # to separate output
	sw $29, x_IO_ADDR_RANGE($14)
	sw $29, x_IO_ADDR_RANGE($14)


	##
	## do 4 loads, 1st aligned, 2nd, 3rd, 4th misaligned
	##   hence 3 exceptions of type AddrError if/ld=x10
	##
	
	la $15, x_DATA_BASE_ADDR
	move $30, $15		# keep safe copy of base address for handlr
	la $18, x_IO_BASE_ADDR
	li $7, 3                # do 3 rounds
	li $3, 0
	sw $7, 0($15)
	nop

there:	nop
	lw    $5, 0($15)      	# causes 3 exceptions: addr&{01,10,11}
	sw    $7, 0($18)	# print value changed by handler
	# sw    $5, 0($18)	# print value read from memory
	addiu $3, $3, 1
	beq   $7, $zero, after
	nop
	j     there
	addu  $15, $15, $3

	
after:	li $29, '\n'           	# to separate output
	sw $29, x_IO_ADDR_RANGE($14)
	sw $29, x_IO_ADDR_RANGE($14)
	

	##
	## do 4 half-word stores: 1st,3rd aligned, 2nd,4th misaligned,
	##   hence 3 exceptions of type AddrError store=x14
	##
	
	la $14, x_IO_BASE_ADDR  # used by exception handler
	move $30, $14		# keep safe copy of base address for handlr
	la $15, x_IO_BASE_ADDR
	li $7, 3
	li $3, 0
	nop

here2:	sh    $3, 0($15)	# causes no exception: addr & 00
	addiu $15, $15, 1      	#   of type AddrError store=x14
	addiu $3 , $3,  1
	sh    $3, 0($15)	# causes exception: addr & 01
	addiu $15, $15, 2       # handler fixes $15 to addr & 00
	addiu $3 , $3,  1
	sh    $3, 0($15)	# causes no exception: addr & 10
	addiu $15, $15, 1
	addiu $3 , $3,  1
	sh    $3, 0($15)	# causes exception: addr & 10


	
next2:	li $29, '\n'            # to separate output
	sw $29, x_IO_ADDR_RANGE($14)
	sw $29, x_IO_ADDR_RANGE($14)
	la $15, x_DATA_BASE_ADDR
	move $30, $15		# keep safe copy of base address for handlr
	la $18, x_IO_BASE_ADDR
	li $7, 3
	la $3, 0
	sw  $7, 0($15)
	nop

	
	##
	## do 4 half-word loads: 1st,3rd aligned, 2nd,4th misaligned,
	##   hence 3 exceptions of type AddrError if/ld=x10
	##
		
there2:	lh    $3, 0($15)	# causes no exception: addr & 00
	sw    $7, 0($18)
	addiu $15, $15, 1
	addiu $3 , $3,  1
	lh    $3, 0($15)	# causes exception: addr & 01
	sw    $7, 0($18)
	addiu $15, $15, 2       # handler fixes $15 to addr & 00
	addiu $3 , $3,  1
	lh    $3, 0($15)	# causes no exception: addr & 10
	sw    $7, 0($18)
	addiu $15, $15, 1
	addiu $3 , $3,  1
	lh    $3, 0($15)	# causes exception: addr & 10
	sw    $7, 0($18)
	
end:	j exit
	nop
