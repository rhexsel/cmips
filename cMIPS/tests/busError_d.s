	##
	## generate and handle (??) a data reference bus error
	## the error occurs on an attempt to load from non-exixting RAM
	##
	.include "cMIPS.s"
	.text
	.align 2
	.set noreorder
	.global _start, _exit
	.ent    _start
_start: nop
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8) # initialize SP: ramTop-8

        ## set STATUS, cop0, no interrupts enabled, user mode
        li   $k0, 0x10000010
        mtc0 $k0, c0_status

	j    main
        nop

exit:	
_exit:	nop	# flush pipeline
	nop
	nop
	nop
	nop
	wait	# then stop VHDL simulation
	nop
	nop
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

	##
	## handle bus error exception
	##
	.org    x_EXCEPTION_0180,0 # exception vector_180
	.global excp_180
	.ent    excp_180
excp_180:
        li   $k0, '\n'
        sw   $k0, x_IO_ADDR_RANGE($14)
        mfc0 $k0, c0_cause
	# andi $k0, $k0, 0x007f	# mask off cause of exception
	sw   $k0, 0($14)        # print CAUSE
        li   $k0, '\n'
        sw   $k0, x_IO_ADDR_RANGE($14)

	li   $k0, 0x10000010	# clear status of exception
        mtc0 $k0, c0_status
	
	j    apocalipse 	# and print a message
	nop

	wait 			# ought not to be executed, never
				# stop simulation if get to here
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
	## 
	##
main:	la $14, x_IO_BASE_ADDR  # used by handler

	## to cause a bus error, the faulting page MUST be mapped on the TLB
	##   else, there will be a TLB miss at stage EXEC, before the
	##   busError, which is detected at the MEM stage.

	# set mapping two pages beyond the top of existing RAM
	.set ram_displ,(x_DATA_BASE_ADDR + x_DATA_MEM_SZ + 2*4096)
	# la $2, ram_displ
	# sw $2, 0($14)
	
	li   $8, (ram_displ & 0xfffff000) # keep VPN2
	mtc0 $8, c0_entryhi
	# sw   $8, 0($14)
	
	li   $6, ( ((ram_displ >>12) <<6) | 0b000111 ) # PPN0
	mtc0 $6, c0_entrylo0
        # sw   $6, 0($14)

	li   $7, ( (((ram_displ+4096) >>12) <<6) | 0b000111 ) # PPN1
        mtc0 $7, c0_entrylo1
        # sw   $7, 0($14)

        li   $5, 7           # read TLB(7)
        mtc0 $5, c0_index
	ehb
        tlbwi
	
	## address above valid instruction addresses
	la $15, ram_displ
	nop
	lw $16, 4($15)		# reference the invalid address
	nop

	## program ought to die at this point, and DO NOT print msg below
zombie:	la  $19, x_IO_BASE_ADDR
	li  $20, '\n'
        sw  $20, x_IO_ADDR_RANGE($19)
	li  $20, 'z'
        sw  $20, x_IO_ADDR_RANGE($19)
	li  $20, 'o'
        sw  $20, x_IO_ADDR_RANGE($19)
        li  $20, 'm'
        sw  $20, x_IO_ADDR_RANGE($19)
	li  $20, 'b'
        sw  $20, x_IO_ADDR_RANGE($19)
	li  $20, 'i'
        sw  $20, x_IO_ADDR_RANGE($19)
        li  $20, 'e'
        sw  $20, x_IO_ADDR_RANGE($19)
	li  $20, '\n'
	j   _exit
        sw  $20, x_IO_ADDR_RANGE($19)

	## this message should be printed
apocalipse:
	la  $19, x_IO_BASE_ADDR
	li  $20, 'b'
        sw  $20, x_IO_ADDR_RANGE($19)
	li  $20, 'u'
        sw  $20, x_IO_ADDR_RANGE($19)
        li  $20, 's'
        sw  $20, x_IO_ADDR_RANGE($19)
	li  $20, ' '
        sw  $20, x_IO_ADDR_RANGE($19)
	li  $20, 'e'
        sw  $20, x_IO_ADDR_RANGE($19)
        li  $20, 'r'
        sw  $20, x_IO_ADDR_RANGE($19)
        sw  $20, x_IO_ADDR_RANGE($19)
        li  $20, 'o'
        sw  $20, x_IO_ADDR_RANGE($19)
        li  $20, 'r'
        sw  $20, x_IO_ADDR_RANGE($19)
	li  $20, '\n'
        sw  $20, x_IO_ADDR_RANGE($19)
	j   _exit
	sw  $20, x_IO_ADDR_RANGE($19)
