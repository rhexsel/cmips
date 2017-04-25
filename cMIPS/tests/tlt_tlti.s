        ##
        ## this test is run in User Mode
        ##
 	# mips-as -O0 -EL -mips32r2
	.include "cMIPS.s"
	.text
	.align 2
	.set noreorder        # assembler should not reorder instructions

	.global _start
	.global _exit
	.global exit
	
	##
	## reset leaves processor in kernel mode, all else disabled
	##
	.ent    _start
_start: nop
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8

        ## set STATUS, cop0, no interrupts enabled
        li   $k0, 0x10000000
        mtc0 $k0, c0_status

        j   main 
        nop
exit:	
_exit:	nop	# flush pipeline
	nop
	nop
	nop
	nop
	wait 	# and then stop VHDL simulation
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


        ##
        ## print CAUSE, decrement iteration control
        ##
	.org x_EXCEPTION_0180,0 	# exception vector_180
	.ent _excp_180
_excp_180:
        mfc0  $k0, c0_cause
        andi  $k1, $k0, 0x0030
        srl   $k1, $k1, 4
        addi  $k1, $k1, '0'
        sw    $k1, x_IO_ADDR_RANGE($15)
        andi  $k1, $k0, 0x000f          # keep only exception code
        addi  $k1, $k1, '0'
        sw    $k1, x_IO_ADDR_RANGE($15) # print CAUSE.exCode
        li    $k1, '\n'
        sw    $k1, x_IO_ADDR_RANGE($15)
        addiu $7, $7, -1                # decrement iteration control

        mfc0  $k1, c0_epc             # move EPC forward to next instruction
        addi  $k1, $k1, 4
        mtc0  $k1, c0_epc

        mfc0  $k0, c0_status          # go back to user mode, EXL=0
        li    $k1, -16                  # ffff.fff0
        and   $k0, $k0, $k1
        mtc0  $k0, c0_status
excp_180ret:
        eret
        .end _excp_180

	
        ##
        ## this exception should not happen
        ##
        .org x_EXCEPTION_0200,0
        .ent _excp_200
_excp_200:
        li   $28,-1
        sw   $28, 0($15)       # signal exception to std_out
        mfc0 $k0, c0_cause
        li    $k1, 'e'
        sw    $k1, x_IO_ADDR_RANGE($15)
        li    $k1, 'r'
        sw    $k1, x_IO_ADDR_RANGE($15)
        li    $k1, 'r'
        sw    $k1, x_IO_ADDR_RANGE($15)
        li    $k1, '\n'
        sw    $k1, x_IO_ADDR_RANGE($15)
        sw   $k0, 0($15)       # print CAUSE
        eret                   #   and return
        nop
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
	##=======================================================
	##
	.org x_ENTRY_POINT,0	# normal code start
main:	la   $15, x_IO_BASE_ADDR # simulator's stdout
	li   $7, 4		# do loop 4 times
	li   $6, 10		# limit = 10
	li   $5, 0		# value to print

        ##
        ## print sequence 0,34, 2,34, 4,34, 6,cause=34
        ##
here:	sw    $5, 0($15)
	addiu $5, $5, 2
	addi  $31, $0, 31	# so trap will not stall on $5
	tlt   $5, $6
	beq   $7,$zero, there
	nop
	b     here
	nop

        ## print out '\n' to separate tests
there:  li    $28, '\n'
        sw    $28, x_IO_ADDR_RANGE($15)     
	
        ##
        ## print sequence 2,34, 4,34, 6,34, 8,cause=34, 0
        ##
	li   $5, 0
	li   $7, 4
then:	sw   $5, 0($15)
	addiu $5, $5, 2
	addi  $31, $0, 31	# so trap will not stall on $5
	tlti  $5, 10
	bnez  $7, then
	nop
	sw    $7, 0($15)

        ## print out '\n' to separate tests
	li    $28, '\n'
        sw    $28, x_IO_ADDR_RANGE($15)     
	
        ##
        ## print sequence 6,34, 4,34, 2,34, 1
        ##
	li    $5, 1
	li    $7, 4
	li    $6, 6
here2:	sw    $6, 0($15)
	tge   $6, $5
	addiu $6, $6, -2
	beq   $6, $zero, there2
	nop
	b     here2
	nop

there2:	sw    $7, 0($15)	# trapped 3 times: 4-3=1
	
        ## print out '\n' to separate tests
	li    $28, '\n'
        sw    $28, x_IO_ADDR_RANGE($15)     

        ##
        ## print sequence a,34, 8,34, 6,34, 4,cause=34
        ##
	li    $6, 10
	li    $7, 4
then2:	sw    $6, 0($15)
	addi  $31, $0, 31	# so trap will not stall on $5
	tgei  $6, 1
	addiu $6, $6, -2
	bnez  $7, then2
	nop

	sw    $7, 0($15)
	j     exit
	nop
