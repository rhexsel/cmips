	.include "cMIPS.s"
        .text
        .align 2
	.set noreorder
	.set noat
        .globl _start
        .ent _start
_start: nop
	la   $15, HW_keybd_addr    # keyboard
	la   $25, HW_dsp7seg_addr  # 7 segment display
	li   $1, 15          # kbd presents key value in d0-d3, no-key=0xf
	li   $3, 3
	li   $31, 1          # keyboard presents key value in d0-d3
	sll  $31, $31, 31    # bit 31 = 1

wait1:	lw   $8, 0($15)      # read keyboard
	nop
	and  $9, $8, $1      # any key pressed?  any bit not a one?
	beq  $9, $1, wait1
	nop
	
deb1:	lw   $8, 0($15)      # read keyboard, check debouncing ended
	nop
	and  $9,$8,$31       # bit 31 == 1: data is clean
	beq  $9,$zero, deb1
	nop
	andi $8, $8, 0x0f    # clean up datum
	sw   $8, 0($25)      # write key read to 7 segment display
	b    wait1           # repeat forever
	nop
	j wait1
	nop
end1:	nop
        nop
        nop
	nop
	nop
	nop
	nop
        .end _start
