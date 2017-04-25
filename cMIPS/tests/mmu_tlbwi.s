	##
	## Test the TLB as if it were just a memory array
	## Perform a series of indexed writes, then a series of reads
	##   and compare values read to those written
	##
	## Entries 0,1,6,7 are only read, to show initialization values
	##

	## EntryHi     : EntryLo0           : EntryLo1
	## VPN2 g ASID : PPN0 ccc0 d0 v0 g0 : PPN1 ccc1 d1 v1 g1

	.include "cMIPS.s"

	.set MMU_WIRED,    2  ### do not change mapping for base of ROM, I/O

	# New entries cannot overwrite tlb[0.1] which map base of ROM + I/O
	
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
	.globl _start,_exit

	.ent _start
_start:	la   $31, x_IO_BASE_ADDR

        li   $2, c0_status_reset
	addi $2, $2, -2
        mtc0 $2, c0_status ### make sure CPU is not at exception level

        li   $2, MMU_WIRED
        mtc0 $2, c0_wired  ### make sure all but 0,1 TLB entries are usable

	
	# load into MMU(3)
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

	ehb
	
	addi $30, $1, '0'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '\n'
	sw $30, x_IO_ADDR_RANGE($31)
	
read3:	tlbr 			# read TLB at index = 3
	mfc0 $23, c0_entryhi
	sw   $23, 0($31)
	mfc0 $24, c0_entrylo0
	sw   $24, 0($31)
	mfc0 $25, c0_entrylo1
	sw   $25, 0($31)

	li $30, '\n'
	sw $30, x_IO_ADDR_RANGE($31)


	# load into MMU(4)
	li   $1, 4
	mtc0 $1, c0_index
	la   $11, entryHi_4
	mtc0 $11, c0_entryhi
	la   $12, entryLo0_4
	mtc0 $12, c0_entrylo0
	la   $13, entryLo1_4
	mtc0 $13, c0_entrylo1
	tlbwi

	# load into MMU(2)
	li   $1, 2
	mtc0 $1, c0_index
	la   $5, entryHi_2
	mtc0 $5, c0_entryhi
	la   $6, entryLo0_2
	mtc0 $6, c0_entrylo0
	la   $7, entryLo1_2
	mtc0 $7, c0_entrylo1
	tlbwi

	# load into MMU(5)
	li   $1, 5
	mtc0 $1, c0_index
	la   $8, entryHi_1
	mtc0 $8, c0_entryhi
	la   $9, entryLo0_1
	mtc0 $9, c0_entrylo0
	la   $10, entryLo1_1
	mtc0 $10, c0_entrylo1
	tlbwi


	# and now read back all entries: 0..7

	# read from MMU(0)
	li    $1, 0
	addi  $30, $1, '0'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '\n'
	sw $30, x_IO_ADDR_RANGE($31)

	mtc0  $1, c0_index
	tlbr 			# index = 0
	mfc0 $23, c0_entryhi
	sw   $23, 0($31)
	mfc0 $24, c0_entrylo0
	sw   $24, 0($31)
	mfc0 $24, c0_entrylo1
	sw   $24, 0($31)


	# read from MMU(1)
	li   $1, 1
	addi $30, $1, '0'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '\n'
	sw $30, x_IO_ADDR_RANGE($31)

	mtc0 $1, c0_index
	tlbr 			# index = 1
	mfc0 $14, c0_entryhi
	sw   $14, 0($31)
	mfc0 $15, c0_entrylo0
	sw   $15, 0($31)
	mfc0 $16, c0_entrylo1
	sw   $16, 0($31)

	
	# read from MMU(2)
	li    $1, 2
	addi  $30, $1, '0'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '\n'
	sw $30, x_IO_ADDR_RANGE($31)

	mtc0  $1, c0_index
	tlbr 			# index = 2
	mfc0 $17, c0_entryhi
	sw   $17, 0($31)
	mfc0 $18, c0_entrylo0
	sw   $18, 0($31)
	mfc0 $19, c0_entrylo1
	sw   $19, 0($31)

	
	# read from MMU(3)
	li    $1, 3
	addi  $30, $1, '0'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '\n'
	sw $30, x_IO_ADDR_RANGE($31)

	mtc0  $1, c0_index
	tlbr 			# index = 3
	mfc0 $20, c0_entryhi
	sw   $20, 0($31)
	mfc0 $21, c0_entrylo0
	sw   $21, 0($31)
	mfc0 $22, c0_entrylo1
	sw   $22, 0($31)


	# read from MMU(4)
	li    $1, 4
	addi  $30, $1, '0'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '\n'
	sw $30, x_IO_ADDR_RANGE($31)

	mtc0  $1, c0_index
	tlbr 			# index = 4
	mfc0 $23, c0_entryhi
	sw   $23, 0($31)
	mfc0 $24, c0_entrylo0
	sw   $24, 0($31)
	mfc0 $25, c0_entrylo1
	sw   $25, 0($31)

	
	# read from MMU(5)
	li    $1, 5
	addi  $30, $1, '0'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '\n'
	sw $30, x_IO_ADDR_RANGE($31)

	mtc0  $1, c0_index
	tlbr 			# index = 5
	mfc0 $23, c0_entryhi
	sw   $23, 0($31)
	mfc0 $24, c0_entrylo0
	sw   $24, 0($31)
	mfc0 $24, c0_entrylo1
	sw   $24, 0($31)


	## to make the test position-independent, compute the contents
	##   and then compare these to those read from the TLB
	## test will break if MMU is initialized with different page #s
	.set PAGE_SZ,   4096
	.set TAG_MASK, 0xfffff000 	# 4Kbyte pages
	.set TAG_G,    0x00000000	# mark pages as non-global

	
	# read from MMU(6)
	addi $1, $1, 1
	addi $30, $1, '0'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '\n'
	sw $30, x_IO_ADDR_RANGE($31)

	# compute mappings for MMU(6)
	.set x_RAM_PPN_4, (x_DATA_BASE_ADDR + 4*PAGE_SZ)
	.set MMU_ini_dat_RAM4, (((x_RAM_PPN_4 >>12) <<6) | 0b000111) # d,v,g=1
	
	.set x_RAM_PPN_5, (x_DATA_BASE_ADDR + 5*PAGE_SZ)
	.set MMU_ini_dat_RAM5, (((x_RAM_PPN_5 >>12) <<6) | 0b000111) # d,v,g=1

	.set MMU_ini_tag_RAM4, ((x_RAM_PPN_4 & TAG_MASK) | TAG_G)
	
	la $13, MMU_ini_tag_RAM4
 	# sw $13, 0($31)
	la $14, MMU_ini_dat_RAM4
 	# sw $14, 0($31)
	la $15, MMU_ini_dat_RAM5
 	# sw $15, 0($31)
	
	
	mtc0  $1, c0_index
	tlbr 			# index = 6
	mfc0 $23, c0_entryhi
	# sw   $23, 0($31)

	bne  $23, $13, error
	nop
	
	mfc0 $24, c0_entrylo0
	# sw   $24, 0($31)

	bne  $24, $14, error
	nop
	
	mfc0 $25, c0_entrylo1
	# sw   $25, 0($31)

	bne  $25, $15, error
	nop

ok6:	li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($31)
        li   $30, 'k'
        sw   $30, x_IO_ADDR_RANGE($31)
        li   $30, '6'
        sw   $30, x_IO_ADDR_RANGE($31)
        li   $30, '\n'
        sw   $30, x_IO_ADDR_RANGE($31)


	# read from MMU(7)
	addi $1, $1, 1
	addi  $30, $1, '0'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '\n'
	sw $30, x_IO_ADDR_RANGE($31)

	# compute mappings for MMU(7)
	
	.set x_RAM_PPN_6, (x_DATA_BASE_ADDR + 6*PAGE_SZ)
	.set MMU_ini_dat_RAM6, (((x_RAM_PPN_6 >>12) <<6) | 0b000111) # d,v,g=1
	
	.set x_RAM_PPN_7, (x_DATA_BASE_ADDR + 7*PAGE_SZ)
	.set MMU_ini_dat_RAM7, (((x_RAM_PPN_7 >>12) <<6) | 0b000111) # d,v,g=1

	.set MMU_ini_tag_RAM6, ((x_RAM_PPN_6 & TAG_MASK) | TAG_G)
	
	la $13, MMU_ini_tag_RAM6
 	# sw $13, 0($31)
	la $14, MMU_ini_dat_RAM6
 	# sw $14, 0($31)
	la $15, MMU_ini_dat_RAM7
 	# sw $15, 0($31)
	
	mtc0  $1, c0_index
	tlbr 			# index = 7
	mfc0 $23, c0_entryhi
	# sw   $23, 0($31)

	bne  $23, $13, error
	nop
	
	mfc0 $24, c0_entrylo0
	# sw   $24, 0($31)

	bne  $24, $14, error
	nop

	mfc0 $25, c0_entrylo1
	# sw   $25, 0($31)

	bne  $25, $15, error
	nop

ok7:	li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($31)
        li   $30, 'k'
        sw   $30, x_IO_ADDR_RANGE($31)
        li   $30, '7'
        sw   $30, x_IO_ADDR_RANGE($31)
        li   $30, '\n'
        sw   $30, x_IO_ADDR_RANGE($31)
	j    _exit


error:  li   $30, 'e'
        sw   $30, x_IO_ADDR_RANGE($31)
        li   $30, 'r'
        sw   $30, x_IO_ADDR_RANGE($31)
        sw   $30, x_IO_ADDR_RANGE($31)
        li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($31)
        li   $30, 'r'
        sw   $30, x_IO_ADDR_RANGE($31)
        li   $30, '\n'
        sw   $30, x_IO_ADDR_RANGE($31)
	
	nop
	nop
_exit:	nop
	nop
	nop
        nop
        wait
	nop
	nop
	.end _start

	
