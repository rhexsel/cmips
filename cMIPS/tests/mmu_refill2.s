	##
	## Cause a TLB miss on a LOAD, then copy a mapping from page table
	##   cause a second miss by overwriting TLB[7] which maps ROM
	##
	## faulting LOAD is on a branch delay slot
	##
	## EntryHi     : EntryLo0           : EntryLo1
	## VPN2 g ASID : PPN0 ccc0 d0 v0 g0 : PPN1 ccc1 d1 v1 g1

	.include "cMIPS.s"

        # New entries cannot overwrite tlb[0,1] which map base of ROM, I/O

	.set MMU_WIRED,  2  ### do not change mapping for ROM-0, I/O
	
	.text
	.align 2
	.set noreorder
	.set noat
	.org x_INST_BASE_ADDR,0
	.globl _start, _exit
	.ent _start

	## set STATUS, cop0, no interrupts enabled, UM=0, EXL=0
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
        .ent _excp
        .set noreorder
        .set noat

_excp:  mfc0 $k1, c0_context
        lw   $k0, 0($k1)           # k0 <- TP[Context.lo]
        lw   $k1, 8($k1)           # k1 <- TP[Context.hi]
        mtc0 $k0, c0_entrylo0    # EntryLo0 <- k0 = even element
        mtc0 $k1, c0_entrylo1    # EntryLo1 <- k1 = odd element
	##
	## cause, on purpose, another miss on 2nd ROM mapping
	##
	li   $k0, 2
	mtc0 $k0, c0_index
	ehb
        tlbwi                      # update TLB
	
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
	mfc0 $k1, c0_cause		# clear CAUSE

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
        wait 0x01
        nop


        .org x_EXCEPTION_0180,0
_excp_0180:
        la   $k0, x_IO_BASE_ADDR
        mfc0 $k1, c0_cause
        sw   $k1, 0($k0)        # print CAUSE, flush pipe and stop simulation

	la  $a0, not_enough_ram
	jal kprintf
	nop
        nop
        nop
        wait 0x02
        nop

	
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


	
	## dirty trick: there is not enough memory for a full PT, thus
	##   we set the PT at the bottom of RAM addresses and have
	##   Context pointing into that address range

	.set PTbase, x_DATA_BASE_ADDR
	.set PTsize, 1024		# set 1/4 page for PT
	.data
_PageTable:
	.space PTsize, 0	
	
	##
        ##================================================================
        ## normal code starts here
	##
	.text
        .org x_ENTRY_POINT,0

	.ent main
main:	la   $20, x_IO_BASE_ADDR
	
	##
	## setup a PageTable
	##
	## 16 bytes per entry:  
	## EntryLo0                     : EntryLo1
	## PPN0 ccc0 d0 v0 g0 0000.0000 : PPN1 ccc1 d1 v1 g1 0000.0000
	##

	# load Context with PTbase
	la   $4, PTbase
	mtc0 $4, c0_context
	
	# 1st entry: PPN0 & PPN1 ROM
	li   $5, 0            # 1st ROM mapping
	mtc0 $5, c0_index
	nop
	tlbr

	mfc0 $6, c0_entrylo0
	# sw   $6, 0($20)
	mfc0 $7, c0_entrylo1
	# sw   $7, 0($20)

	sw  $6, 0x0($4)
	sw  $0, 0x4($4)
	sw  $7, 0x8($4)
	sw  $0, 0xc($4)

	
	# 2nd entry: PPN2 & PPN3 ROM
	li $5, 2              # 2nd ROM mapping
	mtc0 $5, c0_index
	nop
	tlbr

	mfc0 $6, c0_entrylo0
	# sw   $6, 0($20)
	mfc0 $7, c0_entrylo1
	# sw   $7, 0($20)


	sw  $6, 0x10($4)
	sw  $0, 0x14($4)
	sw  $7, 0x18($4)
	sw  $0, 0x1c($4)


	# 1024th entry: PPN6 & PPN7 RAM
	li   $5, 7           # 3rd RAM mapping
	mtc0 $5, c0_index
	nop
	tlbr

	mfc0 $6, c0_entrylo0
	# sw   $6, 0($20)
	mfc0 $7, c0_entrylo1
	# sw   $7, 0($20)

	.set ram6_displ,((x_DATA_BASE_ADDR + 6*4096)>>(13-4)) # num(VPN2)*16

	# li $1, ram6_displ
	# sw $1, 0($20)
	
	sw  $6, ram6_displ+0($4)
	sw  $0, ram6_displ+4($4)
	sw  $7, ram6_displ+8($4)
	sw  $0, ram6_displ+12($4)
	
	
	## change mapping for 3rd RAM TLB entry, thus causing a miss
chnge3:	li   $5, 7           # 3rd RAM mapping
	mtc0 $5, c0_index

	li   $9, 0x8000
	sll  $9, $9, 8

	mfc0 $8, c0_entryhi
	add  $8, $9, $8     # change tag
	mtc0 $8, c0_entryhi
	ehb
	tlbwi		    # and write it back to TLB (Index = 6)

	nop
	nop
	nop
	
	##
	## cause miss on the load in the delay slot - miss on 6th RAM page
	##   then a second miss since handler (purposefully) updates the
	##   TLB entry for the 2nd ROM page
	##
	li  $15, (x_DATA_BASE_ADDR + 6*4096) # VPN2
		
last:	jal there
	lw  $16, 0($15)

	##
	## try to catch error in EPC.  Return address adjusted below
	##
	li   $30, '@'
	sw   $30, x_IO_ADDR_RANGE($20)
	sw   $30, x_IO_ADDR_RANGE($20)
	sw   $30, x_IO_ADDR_RANGE($20)
	li   $30, '\n'
	sw   $30, x_IO_ADDR_RANGE($20)
	
	
goBack:	li   $30, 'a'
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

kprintf:
	la   $a3, x_IO_BASE_ADDR
kloop:	lbu  $a1, 0($a0)	# while (*p++ != '\0') putc(*p) ;
	addi $a0, $a0, 1
	beq  $a1, $zero, kend
	nop
	j    kloop
	sw   $a1, x_IO_ADDR_RANGE($a3)
	
kend:	li   $a1, '\n'		# print a newline
	jr   $ra
	sw   $a1, x_IO_ADDR_RANGE($a3)


	.data
not_enough_ram:
	.asciiz "\n\tneed >=4 ROM pages & >=8 RAM pages for this test\n"
	.text
	

	##
	## set destination to a far far away place
	##
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

	##
	## adjust return address to catch error in EPC
	##
	la   $31, goBack
	jr   $31
	nop
	
	
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


