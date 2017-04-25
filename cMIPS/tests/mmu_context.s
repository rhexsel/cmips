	##
	## Test the Context register.
	##
	## Write to the upper 16 bits (PTEbase) then read it back
	##   this register is non-compliant so the TP can be set at low addr
	## 
	## Cause an exception by referencing an unmapped address and
	##   then check BadVPN2
	##
	##
	## EntryHi     : EntryLo0           : EntryLo1
	## VPN2 g ASID : PPN0 ccc0 d0 v0 g0 : PPN1 ccc1 d1 v1 g1
	##
	
	.include "cMIPS.s"

	.set MMU_CAPACITY, 8
	.set MMU_WIRED,    2  ### do not change mapping for base of ROM, I/O

	# New entries cannot overwrite tlb[0,1] that map base of ROM + I/O
	
	.set MMU_ini_tag_RAM0, x_DATA_BASE_ADDR
	.set MMU_ini_dat_RAM0, 0x0001005         # this mapping is INVALID
	.set MMU_ini_dat_RAM1, 0x0001047
	
	.text
	.align 2
	.set noreorder
	.set noat
	.globl _start,_exit
	
	.ent _start
_start:	

        li   $2, c0_status_reset
	addi $2, $2, -2
        mtc0 $2, c0_status ### make sure CPU is not at exception level

        li   $2, MMU_WIRED
        mtc0 $2, c0_wired  ### make sure all but 0'th TLB entries are usable

	j main
	nop
	.end _start


        ##
        ##================================================================
        ## exception vector_0180 TLBrefill, from "See MIPS Run" pg 145
        ##
        .org x_EXCEPTION_0180,0
        .set noreorder
        .set noat

        ## EntryHi holds VPN2(31..13), probe the TLB for the offending entry
	
excp:	tlbp            # probe for the guilty entry
        tlbr            # it will surely hit, use Index to point at it
        mfc0 $k1, c0_entrylo0
        ori  $k1, $k1, 0x0002   # make V=1
        mtc0 $k1, c0_entrylo0
        tlbwi                   # write entry back

	li   $30, 'e'
        sw   $30, x_IO_ADDR_RANGE($31)
        li   $30, 'x'
        sw   $30, x_IO_ADDR_RANGE($31)
        li   $30, 'c'
        sw   $30, x_IO_ADDR_RANGE($31)
        li   $30, 'p'
        sw   $30, x_IO_ADDR_RANGE($31)
        li   $30, '\n'
        sw   $30, x_IO_ADDR_RANGE($31)
        eret


	##
	##================================================================
        ## normal code starts here
	##
        .org x_ENTRY_POINT,0

main:	la $31, x_IO_BASE_ADDR
	
	##
	## write PTEbase, twice
	##

	la   $29, 0xaaaf0000		# 16 MS bits
	mtc0 $29, c0_context

	ehb				# clear hazards
	ehb				# clear hazards
	
	mfc0 $28, c0_context
	#sw   $28, 0($31)
	#sw   $29, 0($31)
	bne  $28, $29, error1
	nop

	li $30, 'o'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, 'k
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '1'
	j  next1
	sw $30, x_IO_ADDR_RANGE($31)
	
error1:	li $30, 'e'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, 'r'
	sw $30, x_IO_ADDR_RANGE($31)
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '1'
	sw $30, x_IO_ADDR_RANGE($31)

next1:	li $30, '\n'
	sw $30, x_IO_ADDR_RANGE($31)

	##
	## check only top 16 bits are written
	##

	move $28, $zero
	la   $29, 0x555f0000		# can write only 16 MS bits
	mtc0 $29, c0_context		# must read back 0x555f0000

	ehb				# clear hazards
	ehb				# clear hazards
	
	mfc0 $28, c0_context
	#sw   $28, 0($31)
	srl  $28, $28, 16	     	# keep only 16 MS bits
	li   $27, 0x555f		# check 16MS bits = 0x555f---- = 0x555f
	bne  $28, $27, error2
	nop
	
	li $30, 'o'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, 'k'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '2'
	j  next2
	sw $30, x_IO_ADDR_RANGE($31)
	
error2:	li $30, 'e'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, 'r'
	sw $30, x_IO_ADDR_RANGE($31)
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '2'
	sw $30, x_IO_ADDR_RANGE($31)

next2:	li $30, '\n'
	sw $30, x_IO_ADDR_RANGE($31)


	##
	## cause a TLB exception and check only bottom 16 bits are written
	##   mark first RAM VPN2 as invalid
	##

	li   $5, 4                   # tlb[4] maps first RAM entry
	mtc0 $5, c0_index

	tlbr
	ehb
	
	mfc0 $6, c0_entrylo0
	li   $7, -3		      # clear valid bit: -3 =0xffff.fffd
	and  $5, $6, $7
	mtc0 $5, c0_entrylo0

	ehb
	tlbwi                        # change mapping
	
	la   $29, 0xffff0000         # can write only 16 MS bits
	mtc0 $29, c0_context

	ehb			     # clear hazards
	nop
	nop
	nop
	
	la   $8, x_DATA_BASE_ADDR    # cause the exception: TLBinvalid
	sw   $zero, 0($8)
	
	nop
	nop      # instructions that follow offending store are nullified
	nop	 #   so we prevent misbehaved tests by doing nothing for
	nop      #   6 cycles to drain the pipeline
	nop
	nop
	
	mfc0 $28, c0_context
	#sw   $28, 0($31)

	la   $27, 0xffff0000 | (x_DATA_BASE_ADDR >>9)
	nop
	bne  $28, $27, error3
	nop
	
	li $30, 'o'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, 'k'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '3'
	j  next3
	sw $30, x_IO_ADDR_RANGE($31)
	
error3:	li $30, 'e'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, 'r'
	sw $30, x_IO_ADDR_RANGE($31)
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '3'
	sw $30, x_IO_ADDR_RANGE($31)
next3:	li $30, '\n'
	sw $30, x_IO_ADDR_RANGE($31)

	##
	## make sure BadVAddr was loaded correctly with offending address
	##

	mfc0 $28, c0_badvaddr
	#sw   $28, 0($31)
	#sw   $8, 0($31)
	bne  $28, $8, error4
	nop
	
	li $30, 'o'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, 'k'
	li $30, '4'
	sw $30, x_IO_ADDR_RANGE($31)
	j  next4
	sw $30, x_IO_ADDR_RANGE($31)

error4:	li $30, 'e'
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, 'r'
	sw $30, x_IO_ADDR_RANGE($31)
	sw $30, x_IO_ADDR_RANGE($31)
	li $30, '4'
	sw $30, x_IO_ADDR_RANGE($31)

next4:	li $30, '\n'
	sw $30, x_IO_ADDR_RANGE($31)
	sw $30, x_IO_ADDR_RANGE($31)

_exit:	nop
	nop
        nop
	nop
	nop
        nop
        wait
	nop
	nop


	
