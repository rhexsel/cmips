	# mips-as -O0 -EL -mips32r2
	.include "cMIPS.s"
	.text
	.align 2
	.set noreorder        # assembler should not reorder instructions
	.global _start
	.global _exit
	.global exit
	.ent    _start

	##
	## reset leaves processor in kernel mode, all else disabled
	##
_start: nop
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8

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
excp_180:	
_excp_180:
	##
	## print CAUSE
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

	mfc0  $k1, c0_epc		# move EPC beyond the JAL
	addi  $k1, $k1, 8
	mtc0  $k1, c0_epc
	
	mfc0  $k0, c0_status		# go back to user mode, EXL=0
	li    $k1, -16                  # ffff.fff0
	and   $k0, $k0, $k1
	mtc0  $k0, c0_status

	eret
	.end _excp_180


	.org x_EXCEPTION_0200,0
	.ent _excp_200
excp_200:			
_excp_200:
	##
	## this exception should not happen
	##
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
	##================================================================
	##
	.org x_ENTRY_POINT,0
main:	la    $15, x_IO_BASE_ADDR # print out address (simulator's stdout)
	##
	## does a JAL behave?  Is $ra updated or the instruction is anulled?
	##
	li    $9, '\n'
	sw    $9, x_IO_ADDR_RANGE($15)     # print out '\n' to separate tests
	li  $31, '!'		# put wrong return address in $31
	teq $0,$0		#  then trap
	jal wrong1		#    then DO NOT execute the JAL
	nop			#    as handler skips that instruction
	nop
	nop
	nop
	nop
	nop
	nop

check3: li  $9, '!'
	bne $31, $9, wrong1
	nop
	li  $9,  'o'
	sw  $9,  x_IO_ADDR_RANGE($15)
	li  $9,  'k'
	sw  $9,  x_IO_ADDR_RANGE($15)
	sw  $31, x_IO_ADDR_RANGE($15)     # print out '\n' to separate tests
	li  $9, '\n'
	sw  $9,  x_IO_ADDR_RANGE($15)
	j   exit
	sw  $9,  x_IO_ADDR_RANGE($15)
	
	
wrong1: sw  $31,  0($15)
	li  $9, 'e'
	sw  $9, x_IO_ADDR_RANGE($15)
	li  $9, 'r'
	sw  $9, x_IO_ADDR_RANGE($15)
	sw  $9, x_IO_ADDR_RANGE($15)
	li  $9, '\n'
	sw  $9,  x_IO_ADDR_RANGE($15)
	j   exit
	sw  $9,  x_IO_ADDR_RANGE($15)

