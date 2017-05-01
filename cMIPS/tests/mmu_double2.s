	##
	## Cause a TLB miss on a fetch, on an invalid mapping,
	##   refill handler causes double fault, then fix it at
	##   general exception handler
	##
	## Ensures LW in delay slot, prior to fault, completes
	##
        ## In order: (i) main causes a TLBmiss on fetching destination of JAL
        ##               instruction in JAL's delay slot must complete
        ##           (ii) main made TLB entry for PageTable invalid
        ##                TLBmiss handler goes into double fault
        ##           (iii) general exception handler fixes mapping for PT
        ##           (iv) after eret, fetch at JAL's destination completes 
        ##
	##
	## EntryHi     : EntryLo0           : EntryLo1
	## VPN2 g ASID : PPN0 ccc0 d0 v0 g0 : PPN1 ccc1 d1 v1 g1

	.include "cMIPS.s"

        # New entries cannot overwrite TLB[0,1] which map base of ROM, I/O
	.set MMU_WIRED,  2  ### do not change mapping for base of ROM, I/O


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

	## set STATUS, cop0, no interrupts enabled
_start:	li   $k0, 0x10000000
        mtc0 $k0, c0_status
	li   $k0, MMU_WIRED
        mtc0 $k0, c0_wired

	j main
	nop
	.end _start
	
	##
        ##================================================================
        ## exception vector_0000 TLBrefill, from See MIPS Run pg 145
        ##
        .org x_EXCEPTION_0000,0
        .ent _excp_000
        .set noreorder
        .set noat

_excp_000:  mfc0 $k1, c0_context
        lw   $k0, 0($k1)           # k0 <- TP[Context.lo]
        lw   $k1, 8($k1)           # k1 <- TP[Context.hi]
        mtc0 $k0, c0_entrylo0    # EntryLo0 <- k0 = even element
        mtc0 $k1, c0_entrylo1    # EntryLo1 <- k1 = odd element
        ehb
        tlbwi                      # write indexed for not overwriting PTable
	li   $30, 't'
	sw   $30, x_IO_ADDR_RANGE($20)	# then\n
	li   $30, 'h'
	sw   $30, x_IO_ADDR_RANGE($20)	
	li   $30, 'e'
	sw   $30, x_IO_ADDR_RANGE($20)	
	li   $30, 'n'
	sw   $30, x_IO_ADDR_RANGE($20)	
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($20)

	eret
        .end _excp_000


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
        .ent _excp_180
        .set noreorder
        .set noat

	##
        ## EntryHi holds VPN2(31..13), probe the TLB for the offending entry
	## VPN2 g ASID : PPN0 ccc0 d0 v0 g0 : PPN1 ccc1 d1 v1 g1
	##
_excp_180: tlbp			# probe for the guilty entry
        tlbr			# it will hit, just use Index to point at it
        mfc0 $k1, c0_entrylo0
        ori  $k1, $k1, 0x0002   # make V=1
        mtc0 $k1, c0_entrylo0
        tlbwi                   # write entry back

        li   $30, 'h'			# here\n
        sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, 'e'
        sw   $30, x_IO_ADDR_RANGE($20)
        li   $30, 'r'
        sw   $30, x_IO_ADDR_RANGE($20)
        li   $30, 'e'
        sw   $30, x_IO_ADDR_RANGE($20)
        li   $30, '\n'
        sw   $30, x_IO_ADDR_RANGE($20)

        eret			# return to the EPC saved on the first fault
        .end _excp_180		#   the second fault refills TLB


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
	##   Context pointing to that address range

	.set PTbase, x_DATA_BASE_ADDR
	.ent main
main:	la   $20, x_IO_BASE_ADDR
	
	la   $4, PTbase		# base of RAM
	mtc0 $4, c0_context	# load Context with PTbase
	
	##
	## setup a PageTable
	##
	## 16 bytes per entry:  
	## EntryLo0           : EntryLo1
	## PPN0 ccc0 d0 v0 g0 : PPN1 ccc1 d1 v1 g1
	##

	li   $5, 0 		# 1st ROM mapping
	mtc0 $5, c0_index
	nop
	tlbr

	mfc0 $6, c0_entrylo0
	mfc0 $7, c0_entrylo1

	# 1st entry: PPN0 & PPN1 ROM
	sw  $6, 0($4)
	sw  $0, 4($4)
	sw  $7, 8($4)
	sw  $0, 0xc($4)

	li $5, 2              	# 2nd ROM mapping
	mtc0 $5, c0_index
	nop
	tlbr

	mfc0 $6, c0_entrylo0
	mfc0 $7, c0_entrylo1

	# 2nd entry: PPN2 & PPN3 ROM
	sw  $6, 0x10($4)
	sw  $0, 0x14($4)
	sw  $7, 0x18($4)
	sw  $0, 0x1c($4)


	## change mapping for 2nd ROM TLB entry, thus causing a miss

	li   $9, 0x2000
	sll  $9, $9, 8

	mfc0 $8, c0_entryhi
	add  $8, $9, $8     # change tag
	mtc0 $8, c0_entryhi

	tlbwi		    # and write it back to TLB


	##
	## make invalid TLB entry mapping the page table
	##
        ## read tlb[4] (1st RAM mapping) and clear the V bit
	##
fix5:	li $5, 4
        mtc0 $5, c0_index

        tlbr

        mfc0 $6, c0_entrylo0

        addi $7, $zero, -3      # 0xffff.fffd = 1111.1111.1111.1101
        and  $8, $7, $6         # clear V bit

        mtc0 $8, c0_entrylo0

        tlbwi                   # write entry back to TLB

	nop
	nop
	nop

	## 
	## set LW_SW address away from PageTable at base of RAM
	##
	.set datum,(x_DATA_BASE_ADDR + 4*4096)
	
write:	la   $18, datum
	li   $19, 't'		# first letter of "there"
	sw   $19, 0($18)
	nop
	nop
	nop

	##
	## cause a TLB miss on a fetch, LW in delay slot MUST complete
	##
	
jump:	jal  there
	lw   $19, 0($18)	# this instruction must complete
	
	li   $19, 'a'		# and back again\n\n
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, 'n'
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, 'd'
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, ' '
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, 'b'
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, 'a'
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, 'c'
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, 'k'
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, ' '
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, 'a'
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, 'g'
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, 'a'
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, 'i'
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, 'n'
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, '\n'
	sw   $19, x_IO_ADDR_RANGE($20)
	sw   $19, x_IO_ADDR_RANGE($20)

	
_exit:	nop
	nop
        nop
	nop
	nop
        nop
        wait
	nop
	nop

	
	.org (x_INST_BASE_ADDR + 2*4096),0

there:	# li   $19, 't'  # this instr went to de delay slot
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, 'h'
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, 'e'
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, 'r'
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, 'e'
	sw   $19, x_IO_ADDR_RANGE($20)
	li   $19, '\n'
	sw   $19, x_IO_ADDR_RANGE($20)

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

	
