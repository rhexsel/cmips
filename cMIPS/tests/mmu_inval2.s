	##
	## Perform a store to an invalid page, then set the mapping valid
	##
	##
	## EntryHi     : EntryLo0           : EntryLo1
	## VPN2 g ASID : PPN0 ccc0 d0 v0 g0 : PPN1 ccc1 d1 v1 g1

	.include "cMIPS.s"

	.set MMU_WIRED,    2  ### do not change mapping for base of ROM, I/O

        # New entries cannot overwrite tlb[0,1] which map base of ROM, I/O

        # EntryHi cannot have an ASID different from zero, otw TLB misses
        .set entryHi_1,  0x00012000 #                 pfn0  zzcc cdvg
        .set entryLo0_1, 0x0000091b #  x0 x0 x0 x0 x0 1001  0001 1011 x91b
        .set entryLo1_1, 0x00000c1b #  x0 x0 x0 x0 x0 1100  0001 1011 xc1b

        .set entryHi_2,  0x00014000 #                 pfn0  zzcc cdvg
        .set entryLo0_2, 0x00001016 #  x0 x0 x0 x0 x1 0000  0001 0110 x1016
        .set entryLo1_2, 0x0000141e #  x0 x0 x0 x0 x1 0100  0001 1110 x141e

        .set entryHi_3,  0x00016000 #                 pfn0  zzcc cdvg
        .set entryLo0_3, 0x0000191f #  x0 x0 x0 x0 x1 1001  0001 1111 x191f
        .set entryLo1_3, 0x00001d3f #  x0 x0 x0 x0 x1 1101  0011 1111 x1d3f

        .set entryHi_4,  0x00018000 #                 pfn0  zzcc cdvg
        .set entryLo0_4, 0x00000012 #  x0 x0 x0 x0 x0 0000  0001 0010 x12
        .set entryLo1_4, 0x00000412 #  x0 x0 x0 x0 x0 0100  0001 0010 x412

	.text
	.align 2
	.set noreorder
	.set noat
	.org x_INST_BASE_ADDR,0
	.globl _start,_exit
	.ent _start

	## set STATUS, cop0, no interrupts enabled, UM=0, EXL=0
_start:	li   $k0, 0x10000000
        mtc0 $k0, c0_status

	j main
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
        ##================================================================
        ## general exception vector_0180
        ##
        .org x_EXCEPTION_0180,0
        .ent _excp
        .set noreorder
        .set noat

excp:			# EntryHi holds VPN2(31..13)
_excp:	tlbp		# probe for the guilty entry
	nop
	tlbr		# it will surely hit, just use Index to point at it
	mfc0 $k1, c0_entrylo0
	ori  $k1, $k1, 0x0002		# make V=1
	mtc0 $k1, c0_entrylo0
	tlbwi				# write entry back

	li   $30, 't'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'h'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'e'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'r'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'e'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($20)

	eret
        .end _excp



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
        ##================================================================
        ## normal code starts here
	##
        .org x_ENTRY_POINT,0

	.ent main
main:	la   $20, x_IO_BASE_ADDR

        li   $k0, MMU_WIRED
        mtc0 $k0, c0_wired    # Wire to the TLB entries 0 (ROM) and 1 (IO)

	
	## read tlb[5] (2nd RAM mapping) and clear the V bit
	li $5, 5
	mtc0 $5, c0_index

	tlbr

	mfc0 $6, c0_entrylo0
	
	addi $7, $zero, -3      # 0xffff.fffd = 1111.1111.1111.1101
	and  $8, $7, $6		# clear D bit
	mtc0 $8, c0_entrylo0

	mfc0 $9, c0_entryhi

	tlbwi			# write entry back to TLB
	
	## cause an exception by writing to that same page 
	
	la  $10, 0xffffe000	# mask off non-VPN bits
	and $10, $10, $9
	bne $10, $zero, dest	# cause exception at branch delay slot
	sw  $1, 16($10)

	li   $30, '@'
	sw   $30, x_IO_ADDR_RANGE($20)
	sw   $30, x_IO_ADDR_RANGE($20)
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($20)

	nop
dest:	nop
	
	
	li   $30, 'a'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'n'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'd'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, ' '
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'b'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'a'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'c'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'k'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, ' '
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'a'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'g'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'a'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'i'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'n'
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($20)
	sw   $30, x_IO_ADDR_RANGE($20)

	
_exit:	nop
	nop
        nop
	nop
	nop
        nop
        wait
	nop
	nop

	.end main

