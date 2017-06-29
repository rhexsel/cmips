	# interrupt handlers
	.include "cMIPS.s"
	.text
	.set noreorder	# do not reorder instructions
	.set noat	# do not use register $1 as $at
        .align 2

	#================================================================
	# interrupt handler for external counter attached to IP4=HW2
	# for extCounter address see vhdl/packageMemory.vhd
	#
	# counter set to interrupt 4 times per second (12,500,000*20ns)
	#
	.bss
	.align  2
	.global _counter_val	# accumulate number of interrupts
_counter_val:	.space 4
_counter_saves:	.space 8*4	# area to save up to 8 registers
	# _counter_saves[0]=$a0, [1]=$a1, [2]=$a2, [3]=$a3, ...
	
	.set HW_counter_value,(0xc0000000 | 0x00bebc20) # 12,500,000

	.global extCounter
	.text
	.set    noreorder
	.ent    extCounter

extCounter:
	lui   $k0, %hi(HW_counter_addr)
	ori   $k0, $k0, %lo(HW_counter_addr)
	sw    $zero, 0($k0) 	# Reset counter, remove interrupt request

	#----------------------------------
	# if you change this handler, then save additional registers
	# lui $k1, %hi(_counter_saves)
	# ori $k1, $k1, %lo(_counter_saves)
	# sw  $a0, 0*4($k1)
	# sw  $a1, 1*4($k1)
	#----------------------------------
	
	lui   $k1, %hi(HW_counter_value)
	ori   $k1, $k1, %lo(HW_counter_value)
	sw    $k1, 0($k0)	      # Reload counter so it starts again

	lui   $k0, %hi(_counter_val)  # Increment interrupt event counter
	ori   $k0, $k0, %lo(_counter_val)
	lw    $k1, 0($k0)
	nop
	addiu $k1, $k1, 1
	sw    $k1, 0($k0)

	#----------------------------------
	# if you changed this handler, then restore those same registers
	# lui $k1, %hi(_counter_saves)
	# ori $k1, $k1, %lo(_counter_saves)
	# lw  $a0, 0*4($k1)
	# lw  $a1, 1*4($k1)
	#----------------------------------
	
	eret			    # Return from interrupt
	.end extCounter
	#----------------------------------------------------------------

	
	#================================================================
	# interrupt handler for UART attached to IP6=HW4
	# for UART's address see vhdl/packageMemory.vhd
	#
	.bss 
        .align  2
	.global Ud

	.equ RXHD,0
	.equ RXTL,4
	.equ RX_Q,8
	.equ TXHD,24
	.equ TXTL,28
	.equ TX_Q,32
	.equ NRX,48
	.equ NTX,52

Ud:
rx_hd:	.space 4	# reception queue head index
rx_tl:	.space 4	# tail index
rx_q:   .space 16       # reception queue
tx_hd:	.space 4	# transmission queue head index
tx_tl:	.space 4	# tail index
tx_q:	.space 16	# transmission queue
nrx:	.space 4	# characters in RX_queue
ntx:	.space 4	# spaces left in TX_queue

	.global tx_has_started
tx_has_started:	.space 4 # synchronizes transmission with Putc()

_uart_buff: .space 16*4 # up to 16 registers to be saved here
	# _uart_buff[0]=UARTstatus, [1]=UARTcontrol, [2]=$v0, [3]=$v1,
	#           [4]=$ra, [5]=$a0, [6]=$a1, [7]=$a2, [8]=$a3

	.set U_rx_irq,0x08
	.set U_tx_irq,0x10
	.equ UCTRL,0    # UART registers
	.equ USTAT,4
	.equ UINTER,8
	.equ UDATA,12
	
	.text
	.set    noreorder
	.global UARTinterr
	.ent    UARTinterr
	
UARTinterr:

	#----------------------------------------------------------------
	# While you are developing the complete handler, uncomment the
	#   line below
	#
         .include "../tests/handlerUART.s"
	#
	# Your new handler should be self-contained and do the
	#   return-from-exception.  To do that, copy the lines below up
	#   to, but excluding, ".end UARTinterr", to yours handlerUART.s.
	#----------------------------------------------------------------

_u_rx:	lui   $k0, %hi(_uart_buff)  # get buffer's address
	ori   $k0, $k0, %lo(_uart_buff)
	
	sw    $a0, 5*4($k0)	    # save registers $a0,$a1, others?
	sw    $a1, 6*4($k0)
	sw    $a2, 7*4($k0)

	lui   $a0, %hi(HW_uart_addr)# get device's address
	ori   $a0, $a0, %lo(HW_uart_addr)

	lw    $k1, USTAT($a0) 	    # Read status
	nop
	sw    $k1, 0*4($k0)         #  and save UART status to memory

	li    $a1, U_rx_irq         # remove interrupt request
	sw    $a1, UINTER($a0)
	
	and   $a1, $k1, $a1	    # Is this reception?
	beq   $a1, $zero, UARTret   #   no, ignore it and return
	nop

	# handle reception
	lw    $a1, UDATA($a0) 	    # Read data from device
	lui   $a2, %hi(Ud)          # get address for data & flag
	ori   $a2, $a2, %lo(Ud)

	sw    $a1, 0*4($a2)         #   and return from interrupt
	addiu $a1, $zero, 1
	sw    $a1, 1*4($a2)	    # set flag to signal new arrival 

UARTret:
	lw    $a2, 7*4($k0)
	lw    $a1, 6*4($k0)         # restore registers $a0,$a1, others?
	lw    $a0, 5*4($k0)

	eret			    # Return from interrupt
	.end UARTinterr
	#----------------------------------------------------------------


        #================================================================
        # interrupt handler for DMA controller attached to IP5=HW3
        # for DMA-disk controller address see vhdl/packageMemory.vhd
        #
	# NOT IMPLEMENTED FOR SYNTHESIS
	#
        .bss
        .align  2
        .global _dma_status
_dma_status: .space 2*4         # 2 words to share with DMA-disk driver
_dma_saves:  .space 4*4         # area to save up to 4 registers
        # _dma_saves[0]=$a0, [1]=$a1, [2]=$a2, [3]=$a3

        .set D_clr_irq, 0x0001

        .equ D_FLAG, 0  # DMAinterr flag, done=1
        .equ D_LAST, 4  # DMA device status post interrupt

        .equ DCTRL,  0  # DMAcontroller registers' displacement from base
        .equ DSTAT,  4
        .equ DSRC,   8
        .equ DDST,  12
        .equ DINTER,16

        .text
        .set    noreorder
        .global DMAinterr
        .ent    DMAinterr

	##
	## should NEVER get to this address, signal error
	##
DMAinterr:
        la   $k0, HW_dsp7seg_addr       # 7 segment display
        li   $k1, 0x4355                # display .5.5, RED
        sw   $k1, 0($k0)                # write to 7 segment display
heret:  j    heret                      # wait forever
	nop

        eret                        # Return from interrupt
        .end DMAinterr
        #----------------------------------------------------------------



	#================================================================
	# handler for COUNT-COMPARE registers -- IP7=HW5
	.text
	.set    noreorder
	.equ	num_cycles, 64
	.global countCompare
	.ent    countCompare
countCompare:
	mfc0  $k1,c0_count    	 # read COUNT
	addiu $k1,$k1,num_cycles # set next interrupt in so many ticks
	mtc0  $k1,c0_compare	 # write to COMPARE to clear IRQ

	mfc0  $k0, c0_status	 # Read STATUS register
	ori   $k0, $k0, M_StatusIEn #   but do not modify its contents
	mtc0  $k0, c0_status	 #   except for re-enabling interrupts
	eret			 # Return from interrupt
	.end countCompare
	#----------------------------------------------------------------


	#================================================================
	# startCount enables the COUNT register, returns new CAUSE
	#   CAUSE.dc <= 0 to enable counting
	#----------------------------------------------------------------
	.text
	.set    noreorder
	.global startCount
	.ent    startCount
startCount:
	mfc0 $v0, c0_cause
	lui  $v1, 0xf7ff
	ori  $v1, $v1, 0xffff
        and  $v0, $v0, $v1
	mtc0 $v0, c0_cause
	ehb
	jr   $ra
	nop
	.end    startCount
	#----------------------------------------------------------------


	#================================================================
	# stopCount disables the COUNT register, returns new CAUSE
	#   CAUSE.dc <= 1 to disable counting
	#----------------------------------------------------------------
	.text
	.set    noreorder
	.global stopCount
	.ent    stopCount
stopCount:
	mfc0 $v0, c0_cause
	lui  $v1, 0x0800
        or   $v0, $v0, $v1
	jr   $ra
	mtc0 $v0, c0_cause
	.end    stopCount
	#----------------------------------------------------------------


	#================================================================
	# readCount returns the value of the COUNT register
	#----------------------------------------------------------------
	.text
	.set    noreorder
	.global readCount
	.ent    readCount
readCount:
        mfc0 $v0, c0_count
        jr   $ra
        nop
	.end    readCount
	#----------------------------------------------------------------

	
	#================================================================
	# functions to enable and disable interrupts, both return STATUS
	.text
	.set    noreorder
	.global enableInterr,disableInterr
	.ent    enableInterr
enableInterr:
	mfc0  $v0, c0_status	    # Read STATUS register
	ori   $v0, $v0, 1           #   and enable interrupts
	mtc0  $v0, c0_status
	ehb
	jr    $ra                   # return updated STATUS
	nop
	.end enableInterr

	.ent disableInterr
disableInterr:
	mfc0  $v0, c0_status	    # Read STATUS register
	addiu $v1, $zero, -2        #   and disable interrupts
	and   $v0, $v0, $v1         # -2 = 0xffff.fffe
	mtc0  $v0, c0_status
	ehb
	jr    $ra                   # return updated STATUS
	nop
	.end disableInterr
	#----------------------------------------------------------------


	#================================================================
	## TLB handlers
	## page table entry is { EntryLo0, int0, EntryLo1, int1 }
	## int{0,1} is
	## { fill_31..6, Modified_5, Used_4, Writable_3, eXecutable_2,
	##    Status_10 },
	## Status: 00=unmapped, 01=mapped, 10=secondary_storage, 11=panic
	#================================================================
	

	#================================================================
	# handle TLB Modified exception -- store to page with bit dirty=0
	#
	# (a) fix TLB entry, by setting dirty=1 ;
	# (b) check permissions in PT entry and (maybe) kill the process
	#     OR mark PT entry as Used and Modified, then
	#     update TLB entry.
	#
	.global _excp_saves
	.global _excp_0180ret
	.global handle_Mod
	.set noreorder
	
	.ent handle_Mod
handle_Mod:			# EntryHi points to offending TLB entry
	tlbp			# what is the offender's index?
	lui  $k1, %hi(_excp_saves)
        ori  $k1, $k1, %lo(_excp_saves)
	sw   $a0,  9*4($k1)	# save registers
	sw   $a1, 10*4($k1)
	sw   $a2, 11*4($k1)

	mfc0 $a0, c0_badvaddr
	andi $a0, $a0, 0x1000	# check if even or odd page
	beq  $a0, $zero, M_even
	mfc0 $a0, c0_context

M_odd:	addi $a2, $a0, 12	# address for odd entry
	mfc0 $k0, c0_entrylo1
	ori  $k0, $k0, 0x0004	# mark TLB entry as dirty/writable
	j    M_test
	mtc0 $k0, c0_entrylo1
	
M_even: addi $a2, $a0, 4	# address for even entry
	mfc0 $k0, c0_entrylo0
	ori  $k0, $k0, 0x0004	# mark TLB entry as dirty/writable
	mtc0 $k0, c0_entrylo0

M_test:	lw   $a1, 0($a2)	# read PT[badVAddr]
	mfc0 $k0, c0_badvaddr	# get faulting address
	andi $a0, $a1, 0x0001	# check if page is mapped
	beq  $a0, $zero, M_seg_fault	# no, abort simulation
	nop

	andi $a0, $a1, 0x0008	# check if page is writable
	beq  $a0, $zero, M_prot_viol	# no, abort simulation
	nop

	andi $a0, $a1, 0x0002	# check if page is in secondary memory
	bne  $a0, $zero, M_sec_mem	# yes, abort simulation
	nop

	mfc0 $a0, c0_epc	# check if fault is on an instruction
	beq  $a0, $k0, M_prot_viol	# k0 is badVAddr, if so, abort
	nop

	ori  $a1, $a1, 0x0030	# mark PT entry as modified, used
	sw   $a1, 0($a2)

	tlbwi			# write entry with dirty bit=1 back to TLB
	
	lw   $a0,  9*4($k1)	# restore saved registers and return
	lw   $a1, 10*4($k1)
	j    _excp_0180ret
	lw   $a2, 11*4($k1)

M_seg_fault:	# print message and abort simulation
	la   $k1, x_IO_BASE_ADDR
	sw   $k0, 0($k1)
	jal  cmips_kmsg
	la   $k1, 3		# segmentation fault
	nop
	nop
	nop
	wait 0x41
	
M_prot_viol:	# print message and abort simulation
	la   $k1, x_IO_BASE_ADDR
	sw   $k0, 0($k1)
	jal  cmips_kmsg
	la   $k1, 2		# protection violation
	nop
	nop
	nop
	wait 0x42

M_sec_mem:	# print message and abort simulation
	la   $k1, x_IO_BASE_ADDR
	sw   $k0, 0($k1)
	jal  cmips_kmsg
	la   $k1, 4		# secondary memory
	nop
	nop
	nop
	wait 0x43
	
	.end handle_Mod
	#----------------------------------------------------------------


	#================================================================
	# handle TLB Load exception: double-fault caused by a TLB miss
	#   to the Page Table -- mapping pointing to PT is not on TLB
	#
	# (a) fix the fault by (re)loading the mapping into TLB[4];
	# (b) check permissions in PT entry and (maybe) kill the process.
	#
	.global handle_TLBL
	.global _PT
        .set MIDDLE_RAM, (x_DATA_BASE_ADDR + (x_DATA_MEM_SZ/2))

	.ent handle_TLBL
handle_TLBL:			# EntryHi points to offending TLB entry
	tlbp			# probe it to find the offender's index
	lui  $k1, %hi(_excp_saves)
        ori  $k1, $k1, %lo(_excp_saves)
	sw   $a0,  9*4($k1)
	sw   $a1, 10*4($k1)
	sw   $a2, 11*4($k1)

	mfc0 $a0, c0_badvaddr
	la   $a1, (_PT + (x_INST_BASE_ADDR >>13)*16)

	slt  $a2, $a0, $a1	# a2 <- (badVAddr <= PageTable)
	bne  $a2, $zero, L_chks	#   fault is not to PageTable
	nop

	# this is same code as in start.s
        # get physical page number for two pages at the bottom of PageTable
        la    $a0, ( MIDDLE_RAM >>13 )<<13
        mtc0  $a0, c0_entryhi           # tag for bottom double-page

        la    $a0, ( (MIDDLE_RAM + 0*4096) >>12 )<<6
        ori   $a1, $a0, 0b00000000000000000000000000000111 # ccc=0, d,v,g1
        mtc0  $a1, c0_entrylo0          # bottom page (even)

        la    $a0, ( (MIDDLE_RAM + 1*4096) >>12 )<<6
        ori   $a1, $a0, 0b00000000000000000000000000000111 # ccc=0, d,v,g1
        mtc0  $a1, c0_entrylo1          # bottom page + 1 (odd)

        # and write it to TLB[4]
        li    $k0, 4
        mtc0  $k0, c0_index
        tlbwi
	j     L_ret		# all work done, return
	nop

L_chks: andi $a0, $a0, 0x1000	# check if even or odd page
	beq  $a0, $zero, L_even
	mfc0 $a0, c0_context

L_odd:	j    L_test
	addi $a2, $a0, 12	# address for odd intLo1 entry
	
L_even: addi $a2, $a0, 4	# address for even intLo0 entry

L_test:	lw   $a1, 0($a2)	# get intLo{0,1}
	mfc0 $k0, c0_badvaddr	# get faulting address for printing
	andi $a0, $a1, 0x0001	# check if page is mapped
	beq  $a0, $zero, M_seg_fault	# no, abort simulation
	nop

	andi $a0, $a1, 0x0002	# check if page is in secondary memory
	bne  $a0, $zero, M_sec_mem	# yes, abort simulation
	nop

	ori  $a1, $a1, 0x0010	# mark PT entry as used
	sw   $a1, 0($a2)

	# if this were handler_TLBS, now is the time to also mark the
	#    PT entry as Modified

L_ret:	lw   $a0,  9*4($k1)	# nothing else to do, return
	lw   $a1, 10*4($k1)
	j    _excp_0180ret
	lw   $a2, 11*4($k1)

	.end handle_TLBL
	#----------------------------------------------------------------


	#================================================================
	# purge an entry from the TLB
	# int TLB_purge(void *V_addr)
	#   returns 0 if V_addr purged, 1 if V_addr not in TLB (probe failure)
	#
	.text
	.set noreorder
	.ent TLB_purge
TLB_purge:
	srl  $a0, $a0, 13	# clear out in-page address bits
	sll  $a0, $a0, 13	# 
	mtc0 $a0, c0_entryhi
	nop
	tlbp			# probe the TLB
	nop
	mfc0 $a0, c0_index	# check for hit
	srl  $a0, $a0, 31	# keeo only MSbit
	bne  $a0, $zero, pu_miss # address not in TLB
	move $v0, $a0		# V_addr not in TLB

	tlbr			# read the entry
	li   $a0, -8192		# -8192 = 0xffff.e000
	mtc0 $a0, c0_entryhi	# and write an un-mapped address to tag

	addi $v0, $zero, -3	# -3 = 0xffff.fffd to clear valid bit
	mfc0 $a0, c0_entrylo0	# invalidate the mappings
	and  $a0, $v0, $a0
	mtc0 $a0, c0_entrylo0

	mfc0 $a0, c0_entrylo1
	and  $a0, $v0, $a0
	mtc0 $a0, c0_entrylo1
	move $v0, $zero		# V_addr was purged from TLB

	tlbwi			# write invalid mappings to TLB
	ehb
	
pu_miss: jr  $ra
	nop
	.end TLB_purge
	##---------------------------------------------------------------


	
	#================================================================	
	# delays processing by approx 4*$a0 processor cycles
	.text
	.set    noreorder
	.global cmips_delay, delay_cycle, delay_us, delay_ms
	.ent    cmips_delay
delay_cycle:	
cmips_delay:
	beq   $a0, $zero, _d_cye
	nop
_d_cy:	addiu $a0, $a0, -1
        nop
        bne   $a0, $zero, _d_cy
        nop
_d_cye:	jr    $ra
        nop
	.end    cmips_delay
	#----------------------------------------------------------------

        #================================================================
        # delays processing by $a0 times 1 microsecond
        #   loop takes 5 cycles = 100ns @ 50MHz
        #   1.000ns / 100 = 10
        .text
        .set    noreorder
        .ent    delay_us
delay_us:
        beq   $a0, $zero, _d_use
        nop
        li    $v0, 10
        mul   $a0, $v0, $a0
_d_us:  addiu $a0, $a0, -1
        nop
        nop
        bne   $a0, $zero, _d_us
        nop
_d_use: jr    $ra
        nop
        .end    delay_us
        #----------------------------------------------------------------

        #================================================================
        # delays processing by $a0 times 1 milisecond
        #   loop takes 5 cycles = 100ns @ 50MHz
        #   1.000.000ns / 100 = 10.000
        .text
        .set    noreorder
        .ent    delay_ms
delay_ms:
	beq   $a0, $zero, _d_mse
        nop
        li    $v0, 10000
        mul   $a0, $v0, $a0
        nop
_d_ms:  addiu $a0, $a0, -1
        nop
        nop
        bne   $a0, $zero, _d_ms
        nop
_d_mse: jr    $ra
        nop
        .end    delay_ms
        #----------------------------------------------------------------


	#================================================================	
	# print a message from within "the kernel"
	#   void cmips_kmsg( $k1 )
	# this function preserves registers other than k0,k1
	#
	.bss
        .align  2
_kmsg_saves:	.space 4*4		# area to save 4 registers
		# _kmsg_saves[0]=$a0, [1]=$a1, [2]=$a2, [3]=$a3

	.text
	.align  2
	.set    noreorder
	.set    noat
	.equ	stdout,(x_IO_BASE_ADDR + 1*x_IO_ADDR_RANGE);

	.global cmips_kmsg
	.ent    cmips_kmsg
cmips_kmsg:
	lui   $k0, %hi(_kmsg_saves)
	ori   $k0, $k0, %lo(_kmsg_saves)
	sw    $a0, 0*4($k0)
	sw    $a1, 1*4($k0)
	sw    $a2, 2*4($k0)
	
	lui   $a1, %hi(_kmsg_list)
	ori   $a1, $a1, %lo(_kmsg_list)

	sll   $k1, $k1, 2		# adjust index onto table
	addu  $a1, $a1, $k1
	lw    $a1, 0($a1)		# de-reference pointer
	
	lui   $a2, %hi(stdout)
	ori   $a2, $a2, %lo(stdout)
	
k_for:	lbu   $a0, 0($a1)
	addiu $a1, $a1, 1
	bne   $a0, $zero, k_for
	sb    $a0, 0($a2)		# send it to simulator's stdout
	
	lw    $a0, 0*4($k0)
	lw    $a1, 1*4($k0)
	jr    $ra
	lw    $a2, 2*4($k0)

	.end    cmips_kmsg

	.equ kmsg_interr,0
	.equ kmsg_excep,1

	.section .rodata
        .align  2
_kmsg_interr:	.asciiz "\n\t00 - interrupt\n\n"
_kmsg_excep:	.asciiz "\n\t01 - exception\n\n"
_kmsg_prot_viol:	.asciiz "\n\t02 - protection violation\n\n"
_kmsg_seg_fault: 	.asciiz "\n\t03 - segmentation fault\n\n"
_kmsg_sec_mem: 		.asciiz "\n\t04 - in secondary memory\n\n"

	.global _kmsg_list
	.section .rodata
        .align  2
_kmsg_list:
	.word _kmsg_interr,_kmsg_excep, _kmsg_prot_viol, _kmsg_seg_fault
	.word _kmsg_sec_mem

	##
	## need this so the allocation of the PageTable does not break B^(
	##
	.section .data
        .align  2
_end_of_data:
	.word 0

	#----------------------------------------------------------------

