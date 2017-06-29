	##
	##== synthesis version of startup code ===========================
	##
	##   simple startup code for synthesis
	##

	.include "cMIPS.s"
	.text
	.set noreorder
	.align 2
	.extern main
	.global _start, _exit, exit

        .set MMU_WIRED,    2  ### do not change mapping for base of ROM, I/O
	
	.org x_INST_BASE_ADDR,0
	.ent _start

        ##
        ## reset leaves processor in kernel mode, all else disabled
        ##
_start:	nop

	##### not making use of TLB check this
	j st_0
	nop
	
        # get physical page number for 2 pages at the bottom of RAM, for .data
        #  needed so systems without a page table will not break
        #  read TLB[4] and write it to TLB[2]
        li    $k0, 4
        mtc0  $k0, c0_index
        ehb
        tlbr
        li    $k1, 2
        mtc0  $k1, c0_index
        ehb
        tlbwi


        #  then set another mapping onto TLB[4], to avoid replicated entries
        li    $a0, ( (x_DATA_BASE_ADDR + 8*4096) >>12 )
        sll   $a2, $a0, 12      # tag for RAM[8,9] double-page
        mtc0  $a2, c0_entryhi

        li    $a0, ((x_DATA_BASE_ADDR + 8*4096) >>12 )
        sll   $a1, $a0, 6       # RAM[8] (even)
        ori   $a1, $a1, 0b00000000000000000000000000000111 # ccc=0, d,v,g1
        mtc0  $a1, c0_entrylo0

        li    $a0, ( (x_DATA_BASE_ADDR + 9*4096) >>12 )
        sll   $a1, $a0, 6       # RAM[9] (odd)
        ori   $a1, $a1, 0b00000000000000000000000000000111 # ccc=0, d,v,g1
        mtc0  $a1, c0_entrylo1

        # and write it to TLB[4]
        li    $k0, 4
        mtc0  $k0, c0_index
        tlbwi 



        # pin down first four TLB entries: ROM[0], RAM[0], stack and I/O
        li   $k0, 4
        mtc0 $k0, c0_wired



        # initialize SP at top of RAM: RAM[1] - 16
st_0:	li   $sp, ((x_DATA_BASE_ADDR + (2*4096)) - 16)

        # set STATUS, cop0, hw interrupt IRQ7,IRQ6,IRQ5 enabled, user mode
	la   $k1, c0_status_reset
	ori  $k0, $k1, M_StatusIEn
        mtc0 $k0, c0_status

	# reset: COUNTER stopped, use special interrVector, no interrupts
	la   $k0, c0_cause_reset
        mtc0 $k0, c0_cause
	
        j main
        nop

	##
	## signal normal program ending
	##
exit:	
_exit:	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x1300		# display .0.0, RED led
	sw   $k1, 0($k0)		# write to 7 segment display
        li   $k0, 0x1000ff11		# 0x10000010
        mtc0 $k0, c0_status		# enable all interrupts
	nop
	
hexit:	j hexit	  # wait forever
	nop
	.end _start


	##
	## read contents of control registers (for debugging)
	##
	.global print_sp, print_status, print_cause
	.ent print_sp
print_sp:
	jr   $ra
	move $v0, $sp
	.end print_sp

	.ent print_status
print_status:
	mfc0 $v0, c0_status
	nop
	jr   $ra
	nop
	.end print_status

	.ent print_cause
print_cause:
	mfc0 $v0, c0_cause
	nop
	jr   $ra
	nop
	.end print_cause
	
	
        ##
        ##================================================================
	## area to save up to 16 registers
        .data
        .align  2
	.global _excp_saves
        .comm   _excp_saves 16*4


        ##===============================================================
        ## Page Table (empty for synthesis, address must be declared)
        ##
        ## .section .PT,"aw",@progbits, .org (x_DATA_BASE_ADDR+2*4096)
        ## .align 4
        .global _PT
	.comm _PT 4

	
        ##
        ##================================================================
        ## exception vector_0000 TLBrefill
        ##
	.text
	.org x_EXCEPTION_0000,0
_excp_0000:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x0399		# display .9.9
	sw   $k1, 0($k0)		# write to 7 segment display
h0000:	j    h0000			# wait forever
	nop


        ##
        ##================================================================
        ## exception vector_0100 Cache Error (hw not implemented)
        ##   print CAUSE and stop simulation
        ##
         .org x_EXCEPTION_0100,0
_excp_0100:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x0388		# display .8.8
	sw   $k1, 0($k0)		# write to 7 segment display
h0100:	j    h0100			# wait forever
	nop


        ##
        ##================================================================
        ## handler for all exceptions except interrupts and TLBrefill
        ##
        .org x_EXCEPTION_0180,0
_excp_0180:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	# mfc0 $k1, c0_cause
	# andi $k1, $k1, 0x07f		# display .7.7
	li   $k1, 0x0377
	sw   $k1, 0($k0)		# write to 7 segment display
	j _excp_0200
	nop
	
h0180:	j    h0180			# wait forever
	nop

        ##
        ##================================================================
        ## exception return address (should never get here)
        ##
	.global _excp_0180ret
_excp_0180ret:	
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x0344		# display .4.4
	sw   $k1, 0($k0)		# write to 7 segment display
heret:	j    heret			# wait forever
	nop
	


        ##
        ##===============================================================
        ## interrupt handlers at exception vector 0200
        ##
        # declare all handlers here, these must be in file syn_handlers.s
        .extern countCompare  # IRQ7 = hwIRQ5, Cop0 counter
        .extern UARTinterr    # IRQ6 - hwIRQ4, see vhdl/tb_cMIPS.vhd
        .extern DMAinterr     # IRQ5 - hwIRQ3, see vhdl/tb_cMIPS.vhd
        .extern extCounter    # IRQ4 - hwIRQ2, see vhdl/tb_cMIPS.vhd

        .set noreorder

        .org x_EXCEPTION_0200,0    # exception vector_200, interrupt handlers
        .ent _excp_0200
_excp_0200:
        mfc0 $k0, c0_cause
        andi $k0, $k0, M_CauseIM   # Keep only IP bits from Cause
        mfc0 $k1, c0_status
        and  $k0, $k0, $k1         # and mask with IM bits 

        srl  $k0, $k0, 12          # keep only 4 MS bits of IP (irq7..4)
	sll  $k0, $k0,  3          # plus displacement in j-table of 8 bytes
        lui  $k1, %hi(handlers_tbl)
        ori  $k1, $k1, %lo(handlers_tbl)
        add  $k1, $k1, $k0
        nop
        jr   $k1
        nop

        ## the code for each handler must repeat the exception return
        ##   sequence shown below in excp_0200ret.
handlers_tbl:
        j dismiss                  # no request: 0000
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
        eret                       # Return from interrupt
        nop

        .end _excp_0200
        #-----------------------------------------------------------------


	

        ##
        ##================================================================
        ## exception vector_BFC0 NMI or soft-reset
        ##
	.org x_EXCEPTION_BFC0,0
_excp_BFC0:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x13ff		# display .f.f, BLUE
	sw   $k1, 0($k0)		# write to 7 segment display
hBFC0:	j    hBFC0			# wait forever
	nop

	##================================================================
	
	
	##
	##===============================================================
	## main(), normal code starts below -- do not edit next line
	.org x_ENTRY_POINT,0

