	##
	## Test the TLB as if it were just a memory array
	## Perform a series of indexed writes, then a series of probes
	##   the first two fail, next two succeed
	##
        ##
	## EntryHi     : EntryLo0           : EntryLo1
	## VPN2 g ASID : PPN0 ccc0 d0 v0 g0 : PPN1 ccc1 d1 v1 g1

	.include "cMIPS.s"

	.set MMU_CAPACITY, 8
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
	.globl _start
	.ent _start
_start:	la   $31, x_IO_BASE_ADDR

        li   $2, c0_status_reset
        addi $2, $2, -2
        mtc0 $2, c0_status ### make sure CPU is not at exception level

	## load into MMU(3)
	li   $1, 3
	mtc0 $1, c0_index
	la   $2, entryHi_3
	mtc0 $2, c0_entryhi
	la   $3, entryLo0_3
	mtc0 $3, c0_entrylo0
	la   $4, entryLo1_3
	mtc0 $4, c0_entrylo1
	tlbwi

	## check first record was written
	ehb
	
	mtc0 $zero, c0_entryhi
	mtc0 $zero, c0_entrylo0
	mtc0 $zero, c0_entrylo1
	
	tlbr 			# read TLB from index = 3
	mfc0 $23, c0_entryhi
	sw   $23, 0($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)


	## load into MMU(2)
	addiu $1, $1, -1
	mtc0 $1, c0_index
	la   $5, entryHi_2
	mtc0 $5, c0_entryhi
	la   $6, entryLo0_2
	mtc0 $6, c0_entrylo0
	la   $7, entryLo1_2
	mtc0 $7, c0_entrylo1
	tlbwi

	tlbr 			# read TLB from index = 2
	mfc0 $23, c0_entryhi
	sw   $23, 0($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)

	
	## load into MMU(5)
	li   $1, 5
	mtc0 $1, c0_index
	la   $8, entryHi_1
	mtc0 $8, c0_entryhi
	la   $9, entryLo0_1
	mtc0 $9, c0_entrylo0
	la   $10, entryLo1_1
	mtc0 $10, c0_entrylo1
	tlbwi

	
	## load into MMU(4)
	li   $1, 4
	mtc0 $1, c0_index
	la   $11, entryHi_4
	mtc0 $11, c0_entryhi
	la   $12, entryLo0_4
	mtc0 $12, c0_entrylo0
	la   $13, entryLo1_4
	mtc0 $13, c0_entrylo1
	tlbwi

	li $30, '\n'
	sw $30, x_IO_ADDR_RANGE($31)

	##
	## and now probe two entries that will surely miss
	##

	## make a copy of entryHi_3 and change  VPN to force a miss
vpn:	la   $14, entryHi_3
	ori  $14, $14, 0x8000   # change VPN w.r.t tlb(3)
	mtc0 $14, c0_entryhi
	sw   $14, 0($31)

	ehb 	# clear all hazards
	
	tlbp    # and probe the tlb

	mfc0 $15, c0_index    # check for bit31=1
	sw   $15, 0($31)

	slt  $16, $15, $zero    # $16 <- (bit31 = 1)
	beq  $16, $zero, asid
	nop

	li   $30, 'm'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)
	nop
	sw   $30, x_IO_ADDR_RANGE($31)

	
	## make a copy of entryHi_2 and change ASID to force a miss
	##
	## cannot change ASID at EntryHi as this will always cause misses
	##  and we do not care for TLB misses here
	##

asid:	la  $18, entryHi_2
	ori $18, $18, 0x88      # change ASID w.r.t tlb(2)

#	mtc0 $18, c0_entryhi
#	sw   $18, 0($31)

#	ehb 	# clear all hazards
	
#	tlbp    # and probe the tlb

#	mfc0 $19, c0_index    # check for bit31=1
#	sw   $19, 0($31)

#	slt  $20, $19, $zero    # $20 <- (bit31 = 1)
#	beq  $20, $zero, hits
#	nop

#	li   $30, 'm'
#	sw   $30, x_IO_ADDR_RANGE($31)
#	li   $30, '\n'
#	sw   $30, x_IO_ADDR_RANGE($31)
#	nop
#	sw   $30, x_IO_ADDR_RANGE($31)

	##
	## and now probe two entries that will surely hit
	##

	## make a copy of entryHi_1 to force a hit
hits:	la  $18, entryHi_1

	mtc0 $18, c0_entryhi
	sw   $18, 0($31)

	ehb 	# clear all hazards
	
	tlbp    # and probe the tlb

	mfc0 $19, c0_index    # check for bit31=1
	#sw   $19, 0($31)

	slt  $20, $19, $zero    # $20 <- (bit31 = 1)
	beq  $20, $zero, hit1
	nop

	li   $30, 'm'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)


hit1:	li   $30, 'h'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)
	nop
	sw   $30, x_IO_ADDR_RANGE($31)
	

	## make a copy of entryHi_4 to force a hit
	la  $18, entryHi_4

	mtc0 $18, c0_entryhi
	sw   $18, 0($31)

	ehb 	# clear all hazards
	
	tlbp    # and probe the tlb

	mfc0 $19, c0_index    # check for bit31=1
	#sw   $19, 0($31)

	slt  $20, $19, $zero    # $20 <- (bit31 = 1)
	beq  $20, $zero, hit0
	nop

	li   $30, 'm'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)

hit0:	li   $30, 'h'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)
	
	nop
	nop
        nop
	nop
	nop
        nop
        wait
	nop
	nop
	.end _start

	
