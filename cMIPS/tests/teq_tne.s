	# mips-as -O0 -EL -mips32r2
	.include "cMIPS.s"
	.text
	.align 2
	.set noreorder        # assembler should not reorder instructions
	.global _start,_exit
	
	.ent _start

	##
	## reset leaves processor in kernel mode, all else disabled
	##
_start: nop
	li   $sp,(x_DATA_BASE_ADDR+4096-8) # initialize SP: fstPageTop-8

        ## set STATUS, cop0, no interrupts enabled
	li   $k0, 0x10000000
        mtc0 $k0, c0_status
	
	j   main 
	nop
exit:	
_exit:	nop	 # flush pipeline
	nop
	nop
	nop
	nop
	wait     #   and then stop VHDL simulation
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
	##
	## print CAUSE, skip over TRAP instruction
	##
        mfc0  $k0, c0_cause
	andi  $k1, $k0, 0x0030
	srl   $k1, $k1, 4
	addi  $k1, $k1, '0'
	sw    $k1, x_IO_ADDR_RANGE($15)
	andi  $k1, $k0, 0x000f		# keep only exception code
	addi  $k1, $k1, '0'
	sw    $k1, x_IO_ADDR_RANGE($15) # print CAUSE.exCode
	li    $k1, '\n'
	sw    $k1, x_IO_ADDR_RANGE($15)
	li    $5, 0
	addiu $7, $7, -1        	# decrement iteration control

	mfc0  $k1, c0_epc		# move EPC forward to next instruction
	addi  $k1, $k1, 4
	mtc0  $k1, c0_epc
	
	mfc0  $k0, c0_status		# go back to user mode, EXL=0
	li    $k1, -16                  # ffff.fff0
	and   $k0, $k0, $k1
	mtc0  $k0, c0_status

	eret
	.end _excp_180


	.org x_EXCEPTION_0200,0
	.ent _excp_200
_excp_200:
	##
	## this exception should not happen
	##
	li   $28,-1
	sw   $28, 0($15)       # signal WRONG exception to std_out
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

	mfc0  $k1, c0_epc    # move EPC forward to next instruction
	addi  $k1, $k1, 4
	mtc0  $k1, c0_epc

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


	
	.org x_ENTRY_POINT,0
main:	la    $15, x_IO_BASE_ADDR # print out address (simulator's stdout)
	li    $7, 3
	li    $6, 10		# limit = 10
	li    $5, 0             # value to print

	##
	## print sequence 2,4,6,8,cause=34, three times
	##
here:	sw    $5, 0($15)        # print out value: 3 times (0,2,4,6,8,34)
	addiu $5, $5, 2         # value += 2
	addiu $31, $zero,31     # do not cause TRAP to stall on $5
	teq   $5, $6            # trap if value = 10, handler does $7--
	beq   $7, $zero, there  # if done 3 rounds, go on to next test
	nop
	b here
	nop

	## print out '\n' to separate tests
there:	li    $28, '\n'
	sw    $28, x_IO_ADDR_RANGE($15)

	##
	## print sequence 4,cause,3,cause,2,cause,1,cause
	##
	li    $7, 4             # will do 4 traps/exceptions

then:	sw   $7, 0($15)         # print out number of rounds to do: (4,3,2,1)
	tne  $5, $7             # trap if value != 4, $7--
	bnez $7, then
	nop

	## print out '\n' to separate tests	
	li    $28, '\n'
	sw    $28, x_IO_ADDR_RANGE($15)

	##
	## print sequence a,8,6,4,cause=34
	##
	li    $7, 1
	li    $6, 10
	nop
here2:	sw    $6, 0($15)        # print out values: (a,8,6,4,34)
	teqi  $6,4		# decrement $7 when $6=4 (do trap)
	beq   $7,$zero, there2  # 
	addiu $6,$6,-2          # decrement in branch delay slot
	b     here2
	nop

	## print out '\n' to separate tests	
there2:	li    $28, '\n'
	sw    $28, x_IO_ADDR_RANGE($15)     # print out '\n' to separate tests
	
	##
	## print sequence  5,cause,4,cause,3,cause,2,cause,1,cause=34
	##
	li   $7, 5		# will do 5 rounds
then2:	sw   $7, 0($15)         # print out values: (5,34,4,34,3,34,2,34,1,34)
	tnei $7, 0              # trap handler decreases $7
	bnez $7, then2
	nop

	j _exit
	nop
