	##
	## Test the TLB as if it were just a memory array
	## Perform a random write, then probe for it
	##   writes are such thar first two probes fail, next two succeed
	## Because of timing, only one WRITE -> PROBE can be tested
	##   "deterministically" as any change in core timing breaks the test
	##
	
	## EntryHi     : EntryLo0           : EntryLo1
	## VPN2 g ASID : PPN0 ccc0 d0 v0 g0 : PPN1 ccc1 d1 v1 g1

	## TLB(i): VPN2 g ASID : PFN0 ccc0 d0 v0 : PFN1 ccc1 d1 v1
	## TLB(0): 0    0 00   : x00  010  0  1  : x11  010  0  1
	## TLB(1): 1    1 ff   : x21  011  0  1  : x31  011  0  1
	## TLB(2): 2    0 77   : x41  010  1  1  : x51  011  1  1
	## TLB(3): 3    1 01   : x61  011  1  1  : x71  111  1  1

	.include "cMIPS.s"

	.set MMU_CAPACITY, 4
	.set MMU_WIRED,    0

	.set entryHi_0,  0x00000000 #                    pfn0  cc cdvg
	.set entryLo0_0, 0x00000012 #  x0 x0 x0 x0 x0 00 00 00 01 0010 x12
	#.set entryLo1_0, 0x00000052 #  x0 x0 x0 x0 x0 00 00 01 01 0010 x52

	.set entryHi_1,  0x00000400 #                    pfn0  cc cdvg
	.set entryLo0_1, 0x00000052 #  x0 x0 x0 x0 x0 00 00 01 01 0010 x52
	#.set entryLo1_1, 0x0000035b #  x0 x0 x0 x0 x0 00 00 11 01 0010 x35b

	.set entryHi_2,  0x00000800 #                    pfn0  cc cdvg
	.set entryLo0_2, 0x00000092 #  x0 x0 x0 x0 x0 00 00 10 01 0010 x92
	#.set entryLo1_2, 0x0000145e #  x0 x0 x0 x0 x0 01 00 01 01 1110 x145e

	.set entryHi_3,  0x00000c00 #                    pfn0  cc cdvg
	.set entryLo0_3, 0x000000d2 #  x0 x0 x0 x0 x0 00 00 11 01 0010 xd2
	#.set entryLo1_3, 0x00001c7f #  x0 x0 x0 x0 x1 11 00 01 11 1111 x1c7f

	# initialize TLB with these
        .set entryHi_i,  0x00ffffff #                    pfn0  cc cdvg
        .set entryLo0_i, 0x0fff185f #  x0 x0 x0 xf xf 11 11 11 00 0000 xfffc0
        .set entryLo1_i, 0x0fff1c7f #  x0 xf xf xf xf 11 11 11 00 0000 xfffc0

	
	.text
	.align 2
	.set noreorder
	.set noat
	.globl _start
	.ent _start
_start:	la   $31, x_IO_BASE_ADDR

	mtc0 $zero, c0_wired   # make sure all TLB entries are usable
	
	## initialize TLB with entries that will not match in tests below
	## NOTE: this is strictly forbidden as all entries are equal
	##       we only do this while testing the TLB

	la   $2, entryHi_0
	mtc0 $2, c0_entryhi
	la   $3, entryLo0_0
	mtc0 $3, c0_entrylo0
	#la   $4, entryLo1_0
	#mtc0 $4, c0_entrylo1

	li   $5, 0
	mtc0 $5, c0_index
	tlbwi


	la   $2, entryHi_1
	mtc0 $2, c0_entryhi
	la   $3, entryLo0_1
	mtc0 $3, c0_entrylo0
	#la   $4, entryLo1_1
	#mtc0 $4, c0_entrylo1
	li   $5, 1
	mtc0 $5, c0_index
	tlbwi



	la   $2, entryHi_2
	mtc0 $2, c0_entryhi
	la   $3, entryLo0_2
	mtc0 $3, c0_entrylo0
	#la   $4, entryLo1_2
	#mtc0 $4, c0_entrylo1
	li   $5, 2
	mtc0 $5, c0_index
	tlbwi

	
	la   $2, entryHi_3
	mtc0 $2, c0_entryhi
	la   $3, entryLo0_3
	mtc0 $3, c0_entrylo0
	#la   $4, entryLo1_3
	#mtc0 $4, c0_entrylo1
	li   $5, 3
	mtc0 $5, c0_index
	tlbwi
	
	li   $5,2
	mtc0 $5, c0_wired      # pin down entries with startup code

	
	mfc0 $19, c0_random    # check for randomness
	sw   $19, 0($31)
	mfc0 $19, c0_random    # check for randomness
	sw   $19, 0($31)
	nop
	mfc0 $19, c0_random    # check for randomness
	sw   $19, 0($31)
	mfc0 $19, c0_random    # check for randomness
	sw   $19, 0($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)


	## write to a random location
	la   $2, entryHi_3
	mtc0 $2, c0_entryhi
	la   $3, entryLo0_3
	mtc0 $3, c0_entrylo0
	#la   $4, entryLo1_3
	#mtc0 $4, c0_entrylo1

	tlbwr # write 0x00006001, 0x0000185f, 0x00001c7f to TLB, ranndom loc

	nop
	nop
	nop
	nop
	
	## check first record was written
	## make sure it will miss by probing for 0,0,0
	## 
	mtc0 $zero, c0_entryhi
	mtc0 $zero, c0_entrylo0
	#mtc0 $zero, c0_entrylo1

	nop
	nop
	
	tlbp
	
	mfc0 $19, c0_index    # check for bit31=1
	sw   $19, 0($31)

	slt  $20, $19, $zero    # $20 <- (bit31 = 1)
	beq  $20, $zero, hit3
	nop

miss3:	li   $30, 'm'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)
	j    next2
	nop

hit3:	li   $30, 'h'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '='
	sw   $30, x_IO_ADDR_RANGE($31)
	andi $30, $19, (MMU_CAPACITY - 1)
	addi $30, $30, '0'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)
	nop
	nop
	sw   $30, x_IO_ADDR_RANGE($31)


	
next2:	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)

	# write into another randomly selected entry
	la   $5, entryHi_2
	mtc0 $5, c0_entryhi
	la   $6, entryLo0_2
	mtc0 $6, c0_entrylo0
	#la   $7, entryLo1_2
	#mtc0 $7, c0_entrylo1
	nop

	tlbwr
	
	nop
	nop

	## check second record was written
	## make sure it will miss by probing for 0,0,0
	## 
	mtc0 $zero, c0_entryhi
	mtc0 $zero, c0_entrylo0
	#mtc0 $zero, c0_entrylo1

	nop
	nop
	
	tlbp

	ehb
	
	mfc0 $19, c0_index    # check for bit31=1
	sw   $19, 0($31)

	slt  $20, $19, $zero    # $20 <- (bit31 = 1)
	beq  $20, $zero, hit2
	nop

miss2:	li   $30, 'm'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)
	j    next1
	nop
	

hit2:	li   $30, 'h'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '='
	sw   $30, x_IO_ADDR_RANGE($31)
	andi $30, $19, (MMU_CAPACITY - 1)
	addi $30, $30, '0'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)
	nop
	nop
	sw   $30, x_IO_ADDR_RANGE($31)


	
next1:	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)

	## now check for last entry written -- must be a hit
	la   $5, entryHi_2
	mtc0 $5, c0_entryhi

	nop
	nop
	nop

	tlbp
	
	mfc0 $19, c0_index    # check for bit31=1
	sw   $19, 0($31)

	slt  $20, $19, $zero    # $20 <- (bit31 = 1)
	beq  $20, $zero, hit1
	nop

miss1:	li   $30, 'm'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)
	j    next0

hit1:	li   $30, 'h'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '='
	sw   $30, x_IO_ADDR_RANGE($31)
	andi $30, $19, (MMU_CAPACITY - 1)
	addi $30, $30, '0'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)

		
next0:	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)

	## now check for one of the initialization values -- must be a hit
	la   $5, entryHi_i
	mtc0 $5, c0_entryhi

	nop
	nop
	nop

	tlbp
	
	mfc0 $19, c0_index    # check for bit31=1
	sw   $19, 0($31)

	slt  $20, $19, $zero    # $20 <- (bit31 = 1)
	beq  $20, $zero, hit0
	nop

miss0:	li   $30, 'm'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)
	j    done

hit0:	li   $30, 'h'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '='
	sw   $30, x_IO_ADDR_RANGE($31)
	andi $30, $19, (MMU_CAPACITY - 1)
	addi $30, $30, '0'
	sw   $30, x_IO_ADDR_RANGE($31)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)
	nop
	nop
	sw   $30, x_IO_ADDR_RANGE($31)

done:	nop
	nop
	nop
	nop
	wait
	nop
	nop
	.end _start

	
