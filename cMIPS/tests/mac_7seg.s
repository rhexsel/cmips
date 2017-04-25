	##
	## test the 7-segment LED displays, and the RGB-led
	##
	.include "cMIPS.s"
        .text
        .align 2
	.set noreorder
	.set noat
        .globl _start
        .ent _start

        .set MMU_WIRED,  2  ### do not change mapping for ROM-0, I/O
	
        .org x_INST_BASE_ADDR,0
	
_start: nop
	li   $k0, 0x10000000
        mtc0 $k0, c0_status

        li   $k0, MMU_WIRED
        mtc0 $k0, c0_wired

	j main
	nop

        .org x_EXCEPTION_0000,0
_excp_0000:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x1399		# display .9.9, led red
	sw   $k1, 0($k0)		# write to 7 segment display
h0000:	j    h0000			# wait forever
	nop
	
        .org x_EXCEPTION_0100,0
_excp_0100:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x1388		# display .8.8, led red
	sw   $k1, 0($k0)		# write to 7 segment display
h0100:	j    h0100			# wait forever
	nop
	
        .org x_EXCEPTION_0180,0
_excp_0180:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x0777		# display .7.7, led blue
	sw   $k1, 0($k0)		# write to 7 segment display
h0180:	j    h0180			# wait forever
	nop
	
        .org x_EXCEPTION_0200,0
_excp_0200:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x0766		# display .6.6, led blue
	sw   $k1, 0($k0)		# write to 7 segment display
h0200:	j    h0200			# wait forever
	nop
	
        .org x_EXCEPTION_BFC0,0
_excp_BFC0:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x0b55		# display .5.5, led green
	sw   $k1, 0($k0)		# write to 7 segment display
hBFC0:	j    hBFC0			# wait forever
	nop


	#
	# main -----------------------------------------------------
	#
	.equ DELAY,1000
	.equ RED, 0x4000
	.equ GRE, 0x2000
	.equ BLU, 0x1000
	.equ OFF, 0x0000

main:	la   $25, HW_dsp7seg_addr  # 7 segment display
	#
	# light up leds RED (b14), GREEN (b13), BLUE (b12)
	#   turn {R.G,B} led on for 1 sec, turn it off for 1 sec,
	#   repeat for next color
	#
	li   $9, RED		   # light up led RED
	sw   $9, 0($25)            # write to 7 segment display
	jal  delay_ms
	la   $a0, DELAY

	li   $9, OFF		   # turn off leds
	sw   $9, 0($25)            # write to 7 segment display
	jal  delay_ms
	la   $a0, DELAY

	li   $9, GRE		   # light up led GREEN
	sw   $9, 0($25)            # write to 7 segment display
	jal  delay_ms
	la   $a0, DELAY

	li   $9, OFF		   # turn off leds
	sw   $9, 0($25)            # write to 7 segment display
	jal  delay_ms
	la   $a0, DELAY

	li   $9, BLU		   # light up led BLUE
	sw   $9, 0($25)            # write to 7 segment display
	jal  delay_ms
	la   $a0, DELAY

	li   $9, OFF		   # turn off leds
	sw   $9, 0($25)            # write to 7 segment display
	jal  delay_ms
	la   $a0, DELAY
	

	#
	# write 0..0xff to the 7-segment displays
	# when count reaches 0xff+1, turn on least significant dot
	# when count reaches 0xfff+1, turn on most significant dot
	# meanwhile, light up one of the 9 colors for 3/4 of a second
	#
	li    $3,0

new:	addiu $3, $3, 1            # change digit
	andi  $3, $3, 0x73ff	   # keep it into 2 digits plus dots
	andi  $4, $3, 0x0007       # keep only 3 bits for RGB
        sll   $4, $4, 12           # light up the leds (RED on bit 14)
        or    $3, $3, $4
	sw    $3, 0($25)           # write to 7 segment display

	jal   delay_ms
	li    $a0, (DELAY*3/4)     # wait 3/4 second
	
	andi  $3, $3, 0x03ff	   # turn off leds
	sw    $3, 0($25)           # write to 7 segment display
	
	jal   delay_ms
	li    $a0, (DELAY*1/4)     # wait 1/4 second
	
	b     new	           # and repeat forever
	nop

end1:	nop
        nop
	nop
        nop
        wait
	nop
	nop
        .end _start


        #================================================================
        # delays processing by $a0 times 1 mili second
        #   loop takes 5 cycles = 100ns @ 50MHz
        #   1.000.000ns / 100 = 10.000
        .text
        .set    noreorder
        .ent    delay_ms
delay_ms:
        li    $v0, 10000
        mul   $a0, $v0, $a0
        nop
_d_ms:  addiu $a0, $a0, -1
        nop
	nop
        bne   $a0, $zero, _d_ms
        nop
        jr    $ra
        nop
        .end    delay_ms
        #----------------------------------------------------------------

	

	# not used, just to shut up the linker.
        .bss
nil1:   .space 4
        .sbss
        .data
nil3:   .word 0
        .sdata
nil4:   .word 0


