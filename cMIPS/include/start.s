	##
	##== simulation version of startup code ==========================
	##

	.include "cMIPS.s"
	.text
	.set noreorder
	.align 2
	.extern main
	.global _start, _exit, exit, halt
	
	.org x_INST_BASE_ADDR,0
	.ent _start

        ##
        ## reset leaves processor in kernel mode, all else disabled
        ##
_start:
	# get physical page number for 2 pages at the bottom of RAM, for .data
	#  needed so simulations without a page table will not break
	#  read TLB[4] and write it to TLB[2]
	li    $k0, 4
	mtc0  $k0, c0_index
	ehb
	tlbr
	li    $k1, 2
	mtc0  $k1, c0_index
	ehb
	tlbwi

#### this is not needed when simulating with a PageTable
#	
#	#  then set another mapping onto TLB[4] to avoid replicated entries
#	li    $a0, ( (x_DATA_BASE_ADDR + 8*4096) >>13 )<<13
#	mtc0  $a0, c0_entryhi		# tag for RAM[8,9] double-page
#
#	li    $a0, ((x_DATA_BASE_ADDR + 8*4096) >>12)<<6  # RAM[8] (even)
#	ori   $a1, $a0, 0b00000000000000000000000000000111 # ccc=0, d,v,g1
#	mtc0  $a1, c0_entrylo0
#
#	li    $a0, ((x_DATA_BASE_ADDR + 9*4096) >>12)<<6  # RAM[9] (odd)
#	ori   $a1, $a0, 0b00000000000000000000000000000111 # ccc=0, d,v,g1
#	mtc0  $a1, c0_entrylo1
#
#	# and write it to TLB[4]
#	li    $k0, 4
#	mtc0  $k0, c0_index
#	tlbwi 
####
	
	#
	# the page table is located at the middle of the RAM
	#   bottom half is reserved for "RAM memory", top half is for PTable
	#
	.set TOP_OF_RAM, (x_DATA_BASE_ADDR + x_DATA_MEM_SZ)
	.set MIDDLE_RAM, (x_DATA_BASE_ADDR + (x_DATA_MEM_SZ/2))

	# get physical page number for two pages at the top of RAM, for stack
	la    $a0, ( (MIDDLE_RAM - 2*4096) >>13 )<<13
	mtc0  $a0, c0_entryhi		# tag for top double-page

	la    $a0, ( (MIDDLE_RAM - 2*4096) >>12 )<<6
	ori   $a1, $a0, 0b00000000000000000000000000000111 # ccc=0, d,v,g1
	mtc0  $a1, c0_entrylo0		# top page - 2 (even)

	la    $a0, ( (MIDDLE_RAM - 1*4096) >>12 )<<6
	ori   $a1, $a0, 0b00000000000000000000000000000111 # ccc=0, d,v,g1
	mtc0  $a1, c0_entrylo1		# top page - 1 (odd)

	# and write it to TLB[3]
	li    $k0, 3
	mtc0  $k0, c0_index
	tlbwi 

	#  then set another mapping onto TLB[7], to avoid replicated entries
	li    $a0, ( (x_DATA_BASE_ADDR + 10*4096) >>13 )<<13
	mtc0  $a0, c0_entryhi		# tag for RAM[10,11] double-page

	li    $a0, ((x_DATA_BASE_ADDR + 10*4096) >>12)<<6  # RAM[10] (even)
	ori   $a1, $a0, 0b00000000000000000000000000000111 # ccc=0, d,v,g1
	mtc0  $a1, c0_entrylo0

	li    $a0, ((x_DATA_BASE_ADDR + 11*4096) >>12)<<6  # RAM[11] (odd)
	ori   $a1, $a0, 0b00000000000000000000000000000111 # ccc=0, d,v,g1
	mtc0  $a1, c0_entrylo1

	# and write it to TLB[7]
	li    $k0, 7
	mtc0  $k0, c0_index
	tlbwi 


	# get physical page number for two pages at the bottom of PageTable
	la    $a0, ( MIDDLE_RAM >>13 )<<13
	mtc0  $a0, c0_entryhi		# tag for bottom double-page

	la    $a0, ( (MIDDLE_RAM + 0*4096) >>12 )<<6
	ori   $a1, $a0, 0b00000000000000000000000000000111 # ccc=0, d,v,g1
	mtc0  $a1, c0_entrylo0		# bottom page (even)

	la    $a0, ( (MIDDLE_RAM + 1*4096) >>12 )<<6
	ori   $a2, $a0, 0b00000000000000000000000000000111 # ccc=0, d,v,g1
	mtc0  $a2, c0_entrylo1		# bottom page + 1 (odd)

	# and write it to TLB[4]
	li    $k0, 4
	mtc0  $k0, c0_index
	tlbwi 

	# create a PT entry for the Page Table itself
	#   in these simulations, only the first page is used
	la    $a0, MIDDLE_RAM
	srl   $a0, $a0, 9        # (_PT>>13)*16
        la    $v0, PTbase
        add   $a0, $v0, $a0
	sw    $a1, 0($a0)        # write to PT[ _PTV ].entryLo0
        sw    $a2, 8($a0)        # write to PT[ _PTV ].entryLo1

	# pin down first five TLB entries: ROM[0], I/O, RAM[0], stack, PgTbl
	li   $k0, 5
	mtc0 $k0, c0_wired

	
	# write PageTable base address to Context
	la   $k0, MIDDLE_RAM
	mtc0 $k0, c0_context

	
	# initialize SP at top of usable RAM: (middle of ram) - 16
	la   $sp, (MIDDLE_RAM - 16)

	
	# set STATUS, c0, all hw+sw interrupts enabled, user mode
        li   $k0, c0_status_normal
        mtc0 $k0, c0_status
	ehb
	
	jal  main # on returning from main(), MUST go into exit()
	nop       #   to stop the simulation.
exit:	
_exit:	nop	  # flush pipeline
	nop
	nop
	nop
	nop
	wait 0    # then stop VHDL simulation gracefully
	nop
halt:	nop	  # flush pipeline
	nop
	nop
	nop
	nop
	wait 0x1f # then stop VHDL simulation forcefully
	nop
	.end _start
	##----------------------------------------------------------------



	##
	##================================================================
	## exception vector_0000 TLBrefill, from See MIPS Run pg 145
	##
	.org x_EXCEPTION_0000,0
	.ent _excp_0000
_excp_0000:
	.set noreorder
	.set noat

	mfc0 $k1, c0_context
	lw   $k0, 0($k1)      	# k0 <- TP[context.lo]
	lw   $k1, 8($k1)        # k1 <- TP[context.hi]
	mtc0 $k0, c0_entrylo0   # EntryLo0 <- k0 = even element
	mtc0 $k1, c0_entrylo1   # EntryLo1 <- k1 = odd element
	ehb
	tlbwr	                # update TLB
	eret	
	.end _excp_0000

	
	##
	##================================================================
	## exception vector_0100 Cache Error (hw not implemented)
	##   print CAUSE and stop simulation
	##
	.org x_EXCEPTION_0100,0
	.ent _excp_0100
_excp_0100:
	.set noreorder
	.set noat

	la   $k0, x_IO_BASE_ADDR # PANIC: SHOULD NEVER GET HERE
	mfc0 $k1, c0_cause
	sw   $k1, 0($k0) 	 # print CAUSE, flush pipe and kill simulation
	nop
	nop
	nop
	wait 0x01
	nop
	.end _excp_0100


	##
	##================================================================
	## handler for all exceptions except interrupts and TLBrefill
	##
	## area to save up to 16 registers
        .bss
        .align  2
	.global _excp_0180ret
        .comm   _excp_saves 16*4
        # _excp_saves[0]=CAUSE, [1]=STATUS, [2]=ASID,
	#            [8]=$ra, [9]=$a0, [10]=$a1, [11]=$a2, [12]=$a3
	#            [13]=$sp [14]=$fp [15]=$at 
        .text
        .set noreorder
	.set noat
	
	.org x_EXCEPTION_0180,0  # exception vector_180
	.ent _excp_0180
_excp_0180:
	mfc0 $k0, c0_status
	lui  $k1, %hi(_excp_saves)
	ori  $k1, $k1, %lo(_excp_saves)
	sw   $k0, 1*4($k1)
        mfc0 $k0, c0_cause
	sw   $k0, 0*4($k1)
	
	andi $k0, $k0, 0x3c    # keep only the first 16 ExceptionCodes & b"00"
	sll  $k0, $k0, 1       # displacement in vector with 8 bytes/element
	lui  $k1, %hi(excp_tbl)
        ori  $k1, $k1, %lo(excp_tbl)
	add  $k1, $k1, $k0
	nop
	jr   $k1
	nop

excp_tbl: # see Table 8-25, pg 95,96
	wait 0x02  # interrupt, should never get here, abort simulation
	nop

	j handle_Mod  # 1
	nop

	j handle_TLBL # 2
	nop

	j handle_TLBL # 3 == TLBS if miss on PT, on the TLB, on a store
	nop		# should mark page as Modified on PT

	j excp_report # 4 AdEL addr error     -- abort simulation
	nop
	j excp_report # 5 AdES addr error     -- abort simulation
	nop
	j excp_report # 6 IBE addr error      -- abort simulation
	nop
	j excp_report # 7 DBE addr error      -- abort simulation
	nop
	
	wait 0x08 # j h_syscall # 8        -- abort simulation
	nop
	wait 0x09 # j h_breakpoint # 9     -- abort simulation
	nop
	wait 0x0a # j h_RI    # 10 reserved instruction -- abort simulation
	nop
	wait 0x0b # j h_CpU   # 11 coprocessor unusable -- abort simulation
	nop
	wait 0x0c # j h_Ov    # 12 overflow             -- abort simulation
	nop
	wait 0x0d # 13 trap                             -- abort simulation
	nop
	wait 0x0e # reserved, should never get here     -- abort simulation
	nop
	wait 0x0f # FP exception, should never get here -- abort simulation
	nop

h_TLBS:	
h_syscall:
h_breakpoint:
h_RI:
h_CpU:
h_Ov:

_excp_0180ret:
	lui  $k1, %hi(_excp_saves) # Read previous contents of STATUS
	ori  $k1, $k1, %lo(_excp_saves)
	lw   $k0, 1*4($k1)
        nop                        #  and do not modify its contents
	ori  $k0, $k0, M_StatusIEn #  and keep user/kernel mode
	mtc0 $k0, c0_status	   #  but enable all interrupts
	ehb
	eret			   # Return from exception

	.end _excp_0180
	#----------------------------------------------------------------

	##
	##===============================================================
	## interrupt handlers at exception vector 0200
	##
	# declare all handlers here, these must be in file handlers.s
	.extern countCompare  # IRQ7 = hwIRQ5, Cop0 counter
	.extern UARTinterr    # IRQ6 - hwIRQ4, see vhdl/tb_cMIPS.vhd
	.extern DMAinterr     # IRQ5 - hwIRQ3, see vhdl/tb_cMIPS.vhd
	.extern extCounter    # IRQ4 - hwIRQ2, see vhdl/tb_cMIPS.vhd

	.set M_CauseIM,0xff00       # keep bits 15..8 -> IM = IP

	.set noreorder
	
	.org x_EXCEPTION_0200,0     # exception vector_200, interrupt handlers
	.ent _excp_0200
_excp_0200:
	mfc0 $k0, c0_cause
	mfc0 $k1, c0_status
	andi $k0, $k0, M_CauseIM   # Keep only IP bits from Cause
	and  $k0, $k0, $k1         #   and mask with IM bits
	srl  $k0, $k0, 9	   # Keep only 4 MS bits of IP (irq7..4)
	lui  $k1, %hi(handlers_tbl) # plus displacement in j-table of 8 bytes
	ori  $k1, $k1, %lo(handlers_tbl)
	add  $k1, $k1, $k0
	nop
	jr   $k1
	nop

	## the code for each handler must contain an exception return (eret)
handlers_tbl:
        j dismiss                  # no request: 000
        nop

        j extCounter               # lowest priority, IRQ4: 0001
        nop

        j DMAinterr                # mid priority, IRQ5: 001x
        nop
        j DMAinterr
        nop
	
        j UARTinterr               # mid priority, IRQ6: 01xx
        nop
        j UARTinterr
        nop
        j UARTinterr
        nop
        j UARTinterr
        nop

        j countCompare             # highest priority, IRQ7: 1xxx
        nop
        j countCompare
        nop
        j countCompare
        nop
        j countCompare
        nop
        j countCompare
        nop
        j countCompare
        nop
        j countCompare
        nop
        j countCompare
        nop
	
dismiss: # No pending request, must have been noise
	 #  do nothing and return

_excp_0200ret:
	eret			   # Return from interrupt

	.end _excp_0200
	#----------------------------------------------------------------


	.org x_EXCEPTION_BFC0,0
	.ent _excp_BFC0
_excp_BFC0:
	##
	##================================================================
	## exception vector_BFC0 NMI or soft-reset
	##
	.set noreorder
	.set noat

	la   $k0, x_IO_BASE_ADDR # PANIC: SHOULD NEVER GET HERE
	mfc0 $k1, c0_cause
	sw   $k1, 0($k0)	# print CAUSE, flush pipe and stop simulation
	nop
	nop
	nop
	wait 0xff		# signal exception and abort simulation
	nop
	.end _excp_BFC0
	##---------------------------------------------------------------

	
	##
	##===============================================================
	## main(), normal code starts below -- do not edit next line
	.org x_ENTRY_POINT,0
	##---------------------------------------------------------------
	

	#================================================================
	# read the page table:
	# int PT_read(void *V_addr, int component)
	#   component is in {0=entrylo0, 1-int0, 2=entrylo1, 3=int1}
	.text
	.global PT_read

	.set noreorder
	.ent PT_read
PT_read:
	srl  $a0, $a0, 9	# (_PT + (V_addr >>13)*16)
	la   $v0, PTbase
	add  $a0, $v0, $a0
	andi $a1, $a1, 0x0003	# make sure component is in range
	sll  $a1, $a1, 2	# component * 4
	add  $a0, $a0, $a1	# (_PT + (V_addr >>13)*16).component
	jr   $ra
	lw   $v0, 0($a0)	# return PT[V_addr].component
	.end PT_read
	##---------------------------------------------------------------

	
	#================================================================
	# update/modify the page table:
	# void PT_update(void *V_addr, int component, int new_value)
	#   component is in {0=entrylo0, 1-int0, 2=entrylo1, 3=int1}
	.text
	.global PT_update

	.set noreorder
	.ent PT_update
PT_update:
	srl  $a0, $a0, 9	# (_PT + (V_addr >>13)*16)
	la   $v0, PTbase
	add  $a0, $v0, $a0
	andi $a1, $a1, 0x0003	# make sure component is in range
	sll  $a1, $a1, 2	# component * 4
	add  $a0, $a0, $a1	# (_PT + (V_addr >>13)*16).component
	jr   $ra
	sw   $a2, 0($a0)	# write to PT[V_addr].component
	.end PT_update
	##---------------------------------------------------------------


	
	##===============================================================
	## Page Table
	##
	## See EntryLo, pg 63
	##
	## intLo0 and intLo1 are:
	## nil_31..6 Modified_5 Used_4  Writable_3  eXecutable_2 Status_1,0
	## Status: 00=unmapped, 01=mapped, 10=in_secondary_storage, 11=locked
	##
	.section .PT,"aw",@progbits
	.align 4
	.global _PT
	
	## ( ( (x_INST_BASE_ADDR + n*4096) >>12 )<<6 ) || 0b000011  d,v,g
	##
	## ROM mappings
	##
	## mapped pages:   intLo{01} = U=M=W=0, X=1, S=01 = 5
	## UNmapped pages: intLo{01} = U=M=W=0, X=1, S=00 = 4
	##
_PT:	.org (_PT + (x_INST_BASE_ADDR >>13)*16)

	# PT[0], ROM
PTbase:	.word  ( (x_INST_BASE_ADDR +  0*4096) >>6) | 0b000011  
	.word 0x00000005
	.word  ( (x_INST_BASE_ADDR +  1*4096) >>6) | 0b000011  
	.word 0x00000005

	# PT[1]
	.word  ( (x_INST_BASE_ADDR +  2*4096) >>6) | 0b000011  
	.word 0x00000005
	.word  ( (x_INST_BASE_ADDR +  3*4096) >>6) | 0b000011  
	.word 0x00000005
	
	# PT[2] -- not mapped for simulation
	.word  ( (x_INST_BASE_ADDR +  4*4096) >>6) | 0b000001  
	.word 0x00000004
	.word  ( (x_INST_BASE_ADDR +  5*4096) >>6) | 0b000001  
	.word 0x00000004

	# PT[3] -- not mapped for simulation
	.word  ( (x_INST_BASE_ADDR +  6*4096) >>6) | 0b000001  
	.word 0x00000004
	.word  ( (x_INST_BASE_ADDR +  7*4096) >>6) | 0b000001  
	.word 0x00000004
	
	# PT[4] -- not mapped for simulation
	.word  ( (x_INST_BASE_ADDR +  8*4096) >>6) | 0b000001
	.word 0x00000004
	.word  ( (x_INST_BASE_ADDR +  9*4096) >>6) | 0b000001
	.word 0x00000004

	# PT[5] -- not mapped for simulation
	.word  ( (x_INST_BASE_ADDR + 10*4096) >>6) | 0b000001
	.word 0x00000004
	.word  ( (x_INST_BASE_ADDR + 11*4096) >>6) | 0b000001
	.word 0x00000004
	
	# PT[6] -- not mapped for simulation
	.word  ( (x_INST_BASE_ADDR + 12*4096) >>6) | 0b000001
	.word 0x00000004
	.word  ( (x_INST_BASE_ADDR + 13*4096) >>6) | 0b000001
	.word 0x00000004

	# PT[7] -- not mapped for simulation
	.word  ( (x_INST_BASE_ADDR + 14*4096) >>6) | 0b000001
	.word 0x00000004
	.word  ( (x_INST_BASE_ADDR + 15*4096) >>6) | 0b000001
	.word 0x00000004

	## remaining ROM entries are invalid and unmapped (0 filled by AS)
	
	
	##
	## RAM mappings
	##
	## mapped pages:   intLo{01} = U=M=0, W=1, X=0, S=01 = 9
	## UNmapped pages: intLo{01} = U=M=0, W=1, X=0, S=00 = 8
	##
	.org (_PT + (x_DATA_BASE_ADDR >>13)*16)

	## ( ( (x_DATA_BASE_ADDR + n*4096) >>12 )<<6 ) || 0b000111  d,v,g
	
	# PT[ram+0], RAM
	.word  ( (x_DATA_BASE_ADDR +  0*4096) >>6) | 0b000111  
	.word 0x00000009
	.word  ( (x_DATA_BASE_ADDR +  1*4096) >>6) | 0b000111  
	.word 0x00000009

	# PT[ram+1]
	.word  ( (x_DATA_BASE_ADDR +  2*4096) >>6) | 0b000111  
	.word 0x00000009
	.word  ( (x_DATA_BASE_ADDR +  3*4096) >>6) | 0b000111  
	.word 0x00000009
	
	# PT[ram+2]
	.word  ( (x_DATA_BASE_ADDR +  4*4096) >>6) | 0b000111  
	.word 0x00000009
	.word  ( (x_DATA_BASE_ADDR +  5*4096) >>6) | 0b000111  
	.word 0x00000009

	# PT[ram+3]
	.word  ( (x_DATA_BASE_ADDR +  6*4096) >>6) | 0b000111  
	.word 0x00000009
	.word  ( (x_DATA_BASE_ADDR +  7*4096) >>6) | 0b000111  
	.word 0x00000009
	
	# PT[ram+4]
	.word  ( (x_DATA_BASE_ADDR +  8*4096) >>6) | 0b000111  
	.word 0x00000009
	.word  ( (x_DATA_BASE_ADDR +  9*4096) >>6) | 0b000111  
	.word 0x00000009

	# PT[ram+5]
	.word  ( (x_DATA_BASE_ADDR + 10*4096) >>6) | 0b000111  
	.word 0x00000009
	.word  ( (x_DATA_BASE_ADDR + 11*4096) >>6) | 0b000111  
	.word 0x00000009
	
	# PT[ram+6]
	.word  ( (x_DATA_BASE_ADDR + 12*4096) >>6) | 0b000111  
	.word 0x00000009
	.word  ( (x_DATA_BASE_ADDR + 13*4096) >>6) | 0b000111  
	.word 0x00000009

	# PT[ram+7]
	.word  ( (x_DATA_BASE_ADDR + 14*4096) >>6) | 0b000111  
	.word 0x00000009
	.word  ( (x_DATA_BASE_ADDR + 15*4096) >>6) | 0b000111  
	.word 0x00000009

	
	## remaining RAM entries are invalid and unmapped (0 filled by AS)
	
_endPT:

