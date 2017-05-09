	##
	## generate and handle (??) an instruction fetch bus error
	## the error occurs on an attempt to fetch from non-exixting ROM
	##
	## one TLB entry must point into the non-existing ROM address to
	##   avoid a TLBmiss exception.
	##
	## ignore VHDL complaints about "romRDindex out of bounds"
	##   ROM _must_ be indexed out of bounds for this test
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

	.set bad_address, (x_INST_BASE_ADDR + x_INST_MEM_SZ + 4096)
	
        # get physical page number for 2 pages above top of ROM
        #   then write it to TLB[3]

        li    $a0, ( bad_address >>12 )
        sll   $a2, $a0, 12      # tag for RAM[8,9] double-page
        mtc0  $a2, c0_entryhi

        li    $a0, ((bad_address + 0*4096) >>12 )
        sll   $a1, $a0, 6       # ROM_top+4096 (even)
        ori   $a1, $a1, 0b00000000000000000000000000000111 # ccc=0, d,v,g1
        mtc0  $a1, c0_entrylo0

        li    $a0, ((bad_address + 1*4096) >>12 )
        sll   $a1, $a0, 6       # ROM_top+8192 (odd)
        ori   $a1, $a1, 0b00000000000000000000000000000111 # ccc=0, d,v,g1
        mtc0  $a1, c0_entrylo1

        # and write it to TLB[3]
        li    $k0, 3
        mtc0  $k0, c0_index
        tlbwi 

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
	## handle the bus error exception
	##
	.org    x_EXCEPTION_0180,0 # exception vector_180
	.global excp_180
	.ent    excp_180
excp_180:
        li   $k0, '\n'
        sw   $k0, x_IO_ADDR_RANGE($14)
        mfc0 $k0, c0_cause
	sw   $k0, 0($14)        # print CAUSE
        li   $k0, '\n'
        sw   $k0, x_IO_ADDR_RANGE($14)

	li   $k0, 0x10000010	# clear status of exception
        mtc0 $k0, c0_status
	
	j    apocalipse 	# and print a message
	nop

	eret 			# ought not to be executed, never
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

	## address above valid instruction addresses
	la $15, (x_INST_BASE_ADDR + x_INST_MEM_SZ + 4)
	nop
	jr $15			# jump to the invalid address
	nop

	## program ought to die at this point, and DO NOT print msg below

	la  $19, x_IO_BASE_ADDR
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
