	##
	## Test the TLB as if it were just a memory array
	## Perform a random write, then probe for it
	##   writes are such that first two probes fail, next two succeed
	## Because of timing, only one WRITE -> PROBE can be tested
	##   "deterministically" as changes to core timing may break the test
	##
	
	## EntryHi     : EntryLo0           : EntryLo1
	## VPN2 g ASID : PPN0 ccc0 d0 v0 g0 : PPN1 ccc1 d1 v1 g1

	.include "cMIPS.s"

	.set MMU_CAPACITY, 8
	.set MMU_WIRED,    2  ### do not change mapping for base of ROM
	                      ###   nor I/O addresses

	# New entries cannot overwrite tlb[0.1] which maps base of ROM + I/O
	
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
	
	# initialize TLB with these
	.set entryHi_i,  0x00ffff00 #                    pfn0  cc cdvg
	.set entryLo0_i, 0x0fff185f #  x0 x0 x0 xf xf 11 11 11 00 0000 xfffc0
	.set entryLo1_i, 0x0fff1c7f #  x0 xf xf xf xf 11 11 11 00 0000 xfffc0

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
	
	li   $2, MMU_WIRED
	mtc0 $2, c0_wired  ### make sure all but 0'th TLB entries are usable
	

	##
	## Initialize TLB with entries that will not match in tests below
	##
	la   $2, entryHi_i
	mtc0 $2, c0_entryhi
	la   $3, entryLo0_i
	mtc0 $3, c0_entrylo0
	la   $4, entryLo1_i
	mtc0 $4, c0_entrylo1

	### do not change mapping for base of ROM at tlb[0] not tlb[1]
	li   $5, 2
	mtc0 $5, c0_index
	tlbwi

	addi $2, $2, 0x4000  # increase VPN2
	li   $5, 3
	mtc0 $5, c0_index
	tlbwi

	addi $2, $2, 0x4000  # increase VPN2
	li   $5, 4
	mtc0 $5, c0_index
	tlbwi

	addi $2, $2, 0x4000  # increase VPN2
	li   $5, 5
	mtc0 $5, c0_index
	tlbwi

	addi $2, $2, 0x4000  # increase VPN2
	li   $5, 6
	mtc0 $5, c0_index
	tlbwi

	addi $2, $2, 0x4000  # increase VPN2
	li   $5, 7
	mtc0 $5, c0_index
	tlbwi
	

	mfc0 $19, c0_random    # check for randomness
	mfc0 $20, c0_random    # check for randomness	
	mfc0 $21, c0_random    # check for randomness
	mfc0 $22, c0_random    # check for randomness
	
	beq $19, $20, error4
	nop
	beq $19, $21, error4
	nop
	beq $19, $22, error4
	nop
	beq $20, $21, error4
	nop
	beq $20, $22, error4
	nop
	beq $21, $22, error4
	nop

        li $30, 'o'
        sw $30, x_IO_ADDR_RANGE($31)
        li $30, 'k'
        j  next4
        sw $30, x_IO_ADDR_RANGE($31)

error4: li $30, 'e'
        sw $30, x_IO_ADDR_RANGE($31)
        li $30, 'r'
        sw $30, x_IO_ADDR_RANGE($31)
        sw $30, x_IO_ADDR_RANGE($31)

next4:  li $30, '\n'
        sw $30, x_IO_ADDR_RANGE($31)


	## write to a random location
	la   $2, entryHi_3
	mtc0 $2, c0_entryhi
	la   $3, entryLo0_3
	mtc0 $3, c0_entrylo0
	la   $4, entryLo1_3
	mtc0 $4, c0_entrylo1

	tlbwr # write to TLB, ranndom loc

	nop
	nop
	nop
	nop

	##
	## check first record was written
	## make sure it will miss by probing for Entry_0
	##
	la   $5, entryHi_4
	mtc0 $5, c0_entryhi
	la   $5, entryLo0_4
	mtc0 $5, c0_entrylo0
	la   $5, entryLo1_4
	mtc0 $5, c0_entrylo1

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
	la   $7, entryLo1_2
	mtc0 $7, c0_entrylo1
	nop

	tlbwr
	
	nop
	nop

	##
	## check second record was written
	## make sure it will miss by probing for entryHi_1
	## 
	la   $5, entryHi_1
	mtc0 $5, c0_entryhi
	mtc0 $zero, c0_entrylo0
	mtc0 $zero, c0_entrylo1

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
	# sw   $19, 0($31)

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
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)

		
next0:	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($31)

	
	## write to a random location
	la   $2, entryHi_1
	mtc0 $2, c0_entryhi
	la   $3, entryLo0_1
	mtc0 $3, c0_entrylo0
	la   $4, entryLo1_1
	mtc0 $4, c0_entrylo1

	nop
	nop
	nop

	tlbwr
	
	## now look for it -- must be a hit

	nop

	tlbp
	
	mfc0 $19, c0_index    # check for bit31=1
	# sw   $19, 0($31)

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

	
