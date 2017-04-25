	# mips-as -O0 -EL -mips32r2
	.include "cMIPS.s"
	.text
	.align 2
	.set noreorder
	.global _start
	.global _exit
	.global exit
	.ent    _start

        ##
        ## reset leaves processor in kernel mode, all else disabled
        ##
_start: nop
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8
        la   $k0, main
        mtc0 $k0, c0_epc
	li   $k1, 2
        mtc0 $k1, c0_wired
        nop
        eret     # go into user mode, all else disabled
        nop
exit:	
_exit:	nop	 # flush pipeline
	nop
	nop
	nop
	nop
	wait     # then stop VHDL simulation
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
	.global _excp_180
	.ent _excp_180
_excp_180:

        li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'v'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'e'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'r'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'f'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'l'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'w'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, '\n'
        sw   $30, x_IO_ADDR_RANGE($15)

	li    $k1, 0x18000008     # disable interrupts, go into user level

        mfc0  $k0, c0_cause     # ovfl was in a delay slot?
	srl   $k0, $k0, 31        #   YES: add 8 to EPC to skip offending add

	mtc0  $k1, c0_status

	beq   $k0, $zero, plus4
	mfc0  $k1, c0_epc
plus8:	j     return
	addiu $k1, $k1, 8	  # fix EPC to jump over 2 instr: branch & add
plus4:	addiu $k1, $k1, 4	  # fix EPC to jump over offending instruction
	
return: mtc0  $k1, c0_epc
	eret
	.end _excp_180




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
	##----------------------------------------------------------------
	##
	.org x_ENTRY_POINT,0    # user code starts here
main:	la $15, x_IO_BASE_ADDR
	la $16, x_IO_BASE_ADDR+x_IO_ADDR_RANGE
	li $17, '\n'

	# signed overflow       
	li  $3, 0x7FFFFFFF	# positive +s positive -> positive
	li  $4, 0x00000001
	add $5, $3, $4
	nop			# handler skips add on returning, otw loops
	sw  $5, 0($15)		# ===exception=== 0x8000.0000 == negative
	sw  $17, 0($16)
	
	# add signed, no overflow
	li   $6, 0xFFFFFFFe     # negative + positive -> no overflow
	addi $7, $6, 3
	nop
	sw   $7, 0($15)		# 0xffff.ffff == negative
	sw   $17, 0($16)
	
	# add unsigned, no overflow
	li   $3, 0x7FFFFFFF     # positive +u positive -> positive
	li   $4, 0x00000001
	addu $5, $3, $4
	nop
	sw   $5, 0($15)		# 0x8000.0000 == unsigned positive
	sw   $17, 0($16)
	
	# add unsigned, no overflow
	li    $6, 0xFFFFFFFe	# negative +u positive -> positive
	addiu $7, $6, 3
	nop
	sw    $7, 0($15)	# 0xffff.ffff == unsigned positive
	sw    $17, 0($16)
	
	# add signed, no overflow
	li   $3, 0xFFFFFFFF	# negative +s positive -> negative 
	li   $4, 0x00000001
	add  $5, $3, $4
	nop
	sw   $5, 0($15)		# 0x0000.0000
	sw   $17, 0($16)
	
	# add signed, overflow
	li   $6, 0x80000000     # negative -s negative -> negative
	addi $7, $6, -1
	nop
	sw   $7, 0($15)		# ===exception=== 0x7fff.ffff == positive
	sw   $17, 0($16)
	
	# add unsigned, no overflow
	li    $6, 0x80000000    # positive -u negative -> positive
	addiu $7, $6, -1
	nop
	sw    $7, 0($15)	# 0x7fff.ffff == positive
	sw    $17, 0($16)
	
	# no overflow, unsigned
	li   $3, 0xFFFFFFFF     # positive +u positive -> positive
	li   $4, 0x00000001
	addu $5, $3, $4
	nop
	sw   $5, 0($15)		# 0x0000.0000  ok since instr is an addU
	sw   $17, 0($16)
	
	# add signed, overflow 
	li    $6,0x7FFFFFFe	# positive +s positive -> positive
	addi  $7,$6,2
	nop
	sw    $7, 0($15)	# ===exception=== 0x8000.0000 == negative
	sw    $17, 0($16)

	# signed, overflow, same as last, add is on a branch delay slot
	li    $6,0x7FFFFFFe	# positive +s positive -> positive
	nop			# remove stall on $6
	beq   $6, $zero, there  
	addi  $7,$6,2
	nop			# handler will return here: EPC += 8
	sw    $7, 0($15)	# ===exception=== 0x8000.0000 == negative
	sw    $17, 0($16)

	j exit
	nop


there:  li   $30, 'e'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'r'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'r'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, '\n'
        sw   $30, x_IO_ADDR_RANGE($15)
	
end:	j exit
	nop
