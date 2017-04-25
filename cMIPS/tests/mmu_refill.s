	##
	## Cause a TLB miss on a fetch, then copy a mapping from page table
	##
	##
	## This test breaks if the base of RAM is below 0x0001.0000 since	
	##   c0_context maps only addresses ABOVE 0x0000.ffff
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
	.globl _start
	.ent _start

	## set STATUS, cop0, no interrupts enabled, EXL=0
_start:	li   $k0, 0x10000000
        mtc0 $k0, c0_status

	j main
	nop
	.end _start
	
	##
        ##================================================================
        ## exception vector_0000 TLBrefill, from See MIPS Run pg 145
        ##
        .org x_EXCEPTION_0000,0
        .ent _excp
        .set noreorder
        .set noat

excp:
_excp:  mfc0 $k1, c0_context
        lw   $k0, 0($k1)           # k0 <- TP[Context.lo]
        lw   $k1, 8($k1)           # k1 <- TP[Context.hi]
        mtc0 $k0, c0_entrylo0    # EntryLo0 <- k0 = even element
        mtc0 $k1, c0_entrylo1    # EntryLo1 <- k1 = odd element
        ehb
        tlbwr                      # update TLB
	li   $30, 'e'
	sw   $30, x_IO_ADDR_RANGE($20)	
	li   $30, 'x'
	sw   $30, x_IO_ADDR_RANGE($20)	
	li   $30, 'c'
	sw   $30, x_IO_ADDR_RANGE($20)	
	li   $30, 'p'
	sw   $30, x_IO_ADDR_RANGE($20)	
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($20)	
	eret
        .end _excp


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
        .org x_EXCEPTION_0180,0
_excp_0180:
        la   $k0, x_IO_BASE_ADDR
        mfc0 $k1, c0_cause
        sw   $k1, 0($k0)        # print CAUSE, flush pipe and stop simulation
        nop
        nop
        nop
        wait 0x02
        nop
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

	
	## dirty trick: there is not enough memory for a full PT, thus
	##   we set the PT at the bottom of RAM addresses and have
	##   Context pointing into that address range

	.set PTbase, x_DATA_BASE_ADDR
	.ent main
main:	la   $20, x_IO_BASE_ADDR

	li   $k0, MMU_WIRED
	mtc0 $k0, c0_wired    # Wire to the TLB entries 0 (ROM) and 1 (IO)
	
	
	##
	## setup a PageTable
	##
	## 16 bytes per entry:  
	## EntryLo0           : EntryLo1
	## PPN0 ccc0 d0 v0 g0 : PPN1 ccc1 d1 v1 g1
	##

	la  $4, PTbase

	li   $5, 0            # 1st ROM mapping
	mtc0 $5, c0_index
	nop
	tlbr

	mfc0 $6, c0_entrylo0
	# sw   $6, 0($20)
	mfc0 $7, c0_entrylo1
	# sw   $7, 0($20)

	# 1st entry: PPN0 & PPN1 ROM
	sw  $6, 0($4)
	sw  $0, 4($4)
	sw  $7, 8($4)
	sw  $0, 12($4)


	li   $5, 2            # 2nd ROM mapping on 2nd PT element
	mtc0 $5, c0_index
	nop
	tlbr

	mfc0 $6, c0_entrylo0
	# sw   $6, 0($20)
	mfc0 $7, c0_entrylo1
	# sw   $7, 0($20)


	# 2nd entry:  PPN2 & PPN3 I/O
	sw  $6, 16($4)
	sw  $0, 20($4)
	sw  $7, 24($4)
	sw  $0, 28($4)

	
	li $5, 3             # 3rd ROM mapping on 3rd PT element
	mtc0 $5, c0_index
	nop
	tlbr

	mfc0 $6, c0_entrylo0
	# sw   $6, 0($20)
	mfc0 $7, c0_entrylo1
	# sw   $7, 0($20)

	# 2nd entry: PPN4 & PPN5 ROM
	sw  $6, 32($4)
	sw  $0, 36($4)
	sw  $7, 40($4)
	sw  $0, 44($4)

	# load Context with PTbase
	mtc0 $4, c0_context
	

	## change mapping for 2nd ROM TLB entry, thus causing a miss

	li   $5, 2          # 2nd ROM mapping
	mtc0 $5, c0_index

	li   $9, 0x2000
	sll  $9, $9, 8

	mfc0 $8, c0_entryhi
	
	add  $8, $9, $8     # change tag

	mtc0 $8, c0_entryhi
	
	tlbwi		    # and write it back to TLB

	nop
	nop
	nop
	
	## cause a TLB miss

	jal  there
	nop
	
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

	
	nop
	nop
        nop
	nop
	nop
        nop
        wait
	nop
	nop

	
	.org (x_INST_BASE_ADDR + 2*4096), 0

there:	li   $30, 't'
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

	jr   $31
	nop
	
	

	
	nop
	nop
        nop
	nop
	nop
        nop
        wait
	nop
	nop
	.end main

