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
	.ent    _start

        ##
        ## reset leaves processor in kernel mode, all else disabled
        ##
_start: nop
        li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8

        la   $k0, c0_status_reset # go into user mode
        addi $k0, $k0, -2
        addi $k0, $k0, 0b10000
        mtc0 $k0, c0_status

        j   main 
        nop

exit:	
_exit:	nop	# flush pipeline
	nop
	nop
	nop
	nop
	wait	# and then stop VHDL simulation
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
        ##
        ## print CAUSE, reset counter, decrement iteration control
        ##
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
        li    $5, 0
        addiu $7, $7, -1                # decrement iteration control

        mfc0  $k1, c0_epc             # move EPC forward to next instruction
        addi  $k1, $k1, 4
        mtc0  $k1, c0_epc
        mfc0  $k0, c0_status          # go back into user mode
        ori   $k0, $k0, 0x0010
        mtc0  $k0, c0_status
excp_180ret:
        eret
        .end _excp_180

	
        .org x_EXCEPTION_0200,0 # exception vector_200
        .ent _excp_200
excp_200:
_excp_200:
        ##
        ## this exception should not happen
        ##
        mfc0 $k0, c0_cause	# signal exception to std_out
        li   $k1, 'e'
        sw   $k1, x_IO_ADDR_RANGE($15)
        li   $k1, 'r'
        sw   $k1, x_IO_ADDR_RANGE($15)
        li   $k1, 'r'
        sw   $k1, x_IO_ADDR_RANGE($15)
        li   $k1, '\n'
        sw   $k1, x_IO_ADDR_RANGE($15)
        sw   $k0, 0($15)       # print CAUSE
        eret                   #   and return
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
	.org x_ENTRY_POINT,0    # normal code
main:	la   $15,x_IO_BASE_ADDR # simulator's stdout
	
	la   $18, 0x80000000	# signed largest negative
	la   $19, 0x80000001 	# signed largest negative but one
	li   $7,4
	
	sw   $18, 0($15)
	sw   $19, 0($15)
	
	li   $28, '\n'
        sw   $28, x_IO_ADDR_RANGE($15)     # print out '\n' to separate tests

xTLTn:	nop
	tlt  $19, $18		# signed: 0x80000001 < 0x80000000 == FALSE
	sw   $7, 0($15)         # print out 4 since no trap
	
	li   $28, '\n'
        sw   $28, x_IO_ADDR_RANGE($15)     # print out '\n' to separate tests

xTLTUn:	nop
	tltu $19, $18		# unsigned: 0x80000001 < 0x80000000 == FALSE
	sw   $7, 0($15)         # print out 4 since no trap
	
	li   $28, '\n'
        sw   $28, x_IO_ADDR_RANGE($15)     # print out '\n' to separate tests


xTLTy:	nop
	tlt  $18, $19		# signed: 0x80000000 < 0x80000001 == TRUE
	sw   $7, 0($15)         # print out 3 since handler decrements $7
	
	li   $28, '\n'
        sw   $28, x_IO_ADDR_RANGE($15)     # print out '\n' to separate tests

xTLTUy:	nop
	tltu $18, $19		# unsigned: 0x80000000 < 0x80000001 == TRUE
	sw   $7, 0($15)         # print out 2 as handler decrements $7
	
	li   $28, '\n'
        sw   $28, x_IO_ADDR_RANGE($15)     # print out '\n' to separate tests

	
xTGEy:	nop
	tge  $19, $18		# signed: 0x80000001 >= 0x80000000 == TRUE
	sw   $7, 0($15)         # print out 1 as handler decrements $7
	
	li   $28, '\n'
        sw   $28, x_IO_ADDR_RANGE($15)     # print out '\n' to separate tests

xTGEUy:	nop
	tgeu $19, $18		# unsigned: 0x80000001 >= 0x80000000 == TRUE
	sw   $7, 0($15)         # print out 0 as handler decrements $7
	
	li   $28, '\n'
        sw   $28, x_IO_ADDR_RANGE($15)     # print out '\n' to separate tests


xTGEn:	nop
	tge  $18, $19		# signed: 0x80000000 >= 0x80000001 == FALSE
	sw   $7, 0($15)         # print out 0 since no trap
	
	li   $28, '\n'
        sw   $28, x_IO_ADDR_RANGE($15)     # print out '\n' to separate tests

xTGEUn:	nop
	tgeu $18, $19		# unsigned: 0x80000000 >= 0x80000001 == FALSE
	sw   $7, 0($15)         # print out 0 since no trap

 	j exit
 	nop
