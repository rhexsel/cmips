	##
        ## Test the TLB INDEX and RANDOM registers
	## 
        ## First, check randomness of RANDOM

	.include "cMIPS.s"

	.text
	.align 2
	.set noreorder
	.globl _start, _exit
	
	.set MMU_CAPACITY, 8
	.set MMU_WIRED,    1  ### do not change mapping for base of ROM

	.ent _start
_start: li   $5, MMU_WIRED
	mtc0 $5, c0_wired  ### make sure all but 0'th TLB entries are usable
	li   $6, MMU_CAPACITY - 1
	mtc0 $6, c0_index

	la   $15, x_IO_BASE_ADDR

	nop
	nop
	nop # give the RANDOM counter some time after resetting,
	nop #   so it can advance freely for a few cycles
	nop
	nop

	## ok, waited for several cycles

	##
        ## print 6 random values in 1..CAPACITY-1
	##
	
	li    $7, MMU_CAPACITY - 2  # one entry wired -> TLB(0)
	mfc0  $25, c0_random	    # read one value
	#sw    $25, 0($15)
	nop			    # there must be more than 6 instructions
	nop			    #  in between two comparisons
	
L1:	addiu $7,  $7, -1
	mfc0  $26, c0_random      # read new value
	nop
	nop
	#sw    $26, 0($15)
	nop
	beq   $26, $25, error       # stop if last two values read are equal
	nop
	move  $25, $26              # keep last value read
	nop
	bne   $7,  $zero, L1
	nop

        li   $30, 'o'		    # print a blank line
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'k'		    # print a blank line
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, '\n'		    # print a blank line
        sw   $30, x_IO_ADDR_RANGE($15)

	
	##
	## print 6 random values in 3..CAPACITY-1
	##
	
	li    $7, MMU_CAPACITY - 2
	li    $5, MMU_WIRED + 2     # 3 entries are wired (0..2)
	mtc0  $5, c0_wired

	mfc0  $25, c0_random	    # read one value
	#sw    $25, 0($15)
	nop			    # there must be more than 6 instructions
	nop			    #  in between two comparisons

	
L2:	addiu $7,  $7,-1
	mfc0  $26, c0_random
	nop
	nop
	#sw    $26, 0($15)
	beq   $26, $25, error       # stop if last two values read are equal
	nop
	nop
	move  $25, $26              # keep last value read
	nop
	bne   $7,  $zero, L2
	nop

        li   $30, 'o'		    # print a blank line
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'k'		    # print a blank line
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, '\n'		    # print a blank line
        sw   $30, x_IO_ADDR_RANGE($15)


	##
	## print 6 random values in 7..7=CAPACITY-1
	##
	
	li    $7, MMU_CAPACITY - 2
	li    $5, MMU_CAPACITY - 1  # 7 entries are wired (0..6)
	mtc0  $5, c0_wired

	mfc0  $25, c0_random	    # read one value
	#sw    $25, 0($15)
	
L3:	addiu $7,  $7,-1
	mfc0  $26, c0_random
	nop
	nop
	#sw    $26, 0($15)
	bne   $26, $25, error       # stop if last two values read differ
	nop
	nop
	move  $25, $26              # keep last value read
	nop
	bne   $7,  $zero, L3
	nop

        li   $30, 'o'		    # print a blank line
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'k'		    # print a blank line
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, '\n'		    # print a blank line
        sw   $30, x_IO_ADDR_RANGE($15)

	
	##
	## print 10 random values in 0..CAPACITY-1
	##
	
	li    $7, 10                
	li    $5, 0                 # no entries are wired
	mtc0  $5, c0_wired

	mfc0  $25, c0_random	    # read one value
	#sw    $25, 0($15)
	nop
	
L4:	addiu $7,  $7,-1
	mfc0  $26, c0_random
	nop
	#sw    $26, 0($15)
	beq   $26, $25, error       # stop if last two values read are equal
	nop
	move  $25, $26              # keep last value read
	nop
	bne   $7,  $zero, L4
	nop

        li   $30, 'o'		    # print a blank line
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'k'		    # print a blank line
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, '\n'		    # print a blank line
        sw   $30, x_IO_ADDR_RANGE($15)
	j     exit
        sw   $30, x_IO_ADDR_RANGE($15)
	

error:	li   $30, 'e'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'r'
        sw   $30, x_IO_ADDR_RANGE($15)
	sw   $30, x_IO_ADDR_RANGE($15)
        li   $31, 'o'
        sw   $31, x_IO_ADDR_RANGE($15)
	sw   $30, x_IO_ADDR_RANGE($15)
        li   $31, '\n'		    # print a blank line
        sw   $31, x_IO_ADDR_RANGE($15)
	sw   $31, x_IO_ADDR_RANGE($15)
	
exit:	nop
_exit:	nop
        nop
	nop
	nop
        nop
        wait
	nop
	nop
	.end _start

	
