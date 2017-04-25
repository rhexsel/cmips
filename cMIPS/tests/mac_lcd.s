	.include "cMIPS.s"
        .text
        .align 2
	.set noreorder
	.set noat
        .globl _start
        .ent _start

	# delay loops in four instructions, so divide num cycles by 4
	.set wait_1_sec,       50000000/4 # 1s / 20ns
	.set LCD_power_cycles, 10000000/4 # 200ms / 20ns
	.set LCD_reset_cycles, 2500000/4  # 50ms / 20ns
	.set LCD_clear_delay,  35000/4    # 0.7ms / 20ns
	.set LCD_delay_30us,   1500/4     # 30us / 20ns
	.set LCD_oper_delay,   750/4      # 15us / 20ns
	.set LCD_write_delay,  750/4      # 15us / 20ns

	# smaller constants for simulation
	# .set wait_1_sec,       5   # 1s / 20ns
	# .set LCD_power_cycles, 6   # 200ms / 20ns
	# .set LCD_reset_cycles, 10  # 50ms / 20ns
	# .set LCD_clear_delay,  2   # 0.7ms / 20ns
	# .set LCD_delay_30us,   4   # 30us / 20ns
	# .set LCD_oper_delay,   4   # 15us / 20ns
	# .set LCD_write_delay,  3   # 15us / 20ns

        .set MMU_WIRED,  2  ### do not change mapping for ROM-0, I/O
	
        .org x_INST_BASE_ADDR,0
	
_start: nop
	li   $k0, 0x10000000
        mtc0 $k0, c0_status

        li   $k0, MMU_WIRED
        mtc0 $k0, cop0_Wired

	j main
	nop

        .org x_EXCEPTION_0000,0
_excp_0000:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x4399		# display .9.9, RED led on
	sw   $k1, 0($k0)		# write to 7 segment display
h0000:	j    h0000			# wait forever
	nop
	
        .org x_EXCEPTION_0100,0
_excp_0100:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x4388		# display .8.8
	sw   $k1, 0($k0)		# write to 7 segment display
h0100:	j    h0100			# wait forever
	nop
	
        .org x_EXCEPTION_0180,0
_excp_0180:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x4377		# display .7.7
	sw   $k1, 0($k0)		# write to 7 segment display
h0180:	j    h0180			# wait forever
	nop
	
        .org x_EXCEPTION_0200,0
_excp_0200:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x4366		# display .6.6
	sw   $k1, 0($k0)		# write to 7 segment display
h0200:	j    h0200			# wait forever
	nop
	
        .org x_EXCEPTION_BFC0,0
_excp_BFC0:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x4355		# display .5.5
	sw   $k1, 0($k0)		# write to 7 segment display
hBFC0:	j    hBFC0			# wait forever
	nop


        .org x_ENTRY_POINT,0
	
main:	nop

	### tell the world we are alive
	la  $15, HW_dsp7seg_addr   # 7 segment display
	li  $16, 01
	sw  $16, 0($15)            # write 01 to 7 segment display

	
	la $4, LCD_reset_cycles    # wait for 50ms, so LCDctrl resets
	jal delay
	nop

	la  $26, HW_lcd_addr       # LCD display hw address

	## WAKE UP commands -- send these at 30us intervals	

	li  $19, 0b00110000        # x30 wake-up
	sw  $19, 0($26)
	la $4, LCD_delay_30us      # wait for 30us
	jal delay
	nop

	li  $19, 0b00110000        # x30 wake-up
	sw  $19, 0($26)
	la $4, LCD_delay_30us      # wait for 30us
	jal delay
	nop
	
	li  $19, 0b00111001        # x39 funct: 8bits, 2line, 5x8font, IS=0
	sw  $19, 0($26)
	la $4, LCD_delay_30us      # wait for 30us
	jal delay
	nop


	### set internal oscillator frequency to 700KHz
	
	li  $19, 0b00010111        # x17 int oscil freq: 1/5bias, freq=700kHz 
	sw  $19, 0($26)
	la $4, LCD_delay_30us      # wait for 30us
	jal delay
	nop

	
	### display is now on fast clock
	
	li  $19, 0b01110000        # x70 contrast for int follower mode: 0
	sw  $19, 0($26)
	la $4, LCD_oper_delay      # wait for 15us
	jal delay
	nop

	li  $19, 0b01010110        # x56 pwrCntrl: ICON=off, boost=on, contr=2 
	sw  $19, 0($26)
	la $4, LCD_oper_delay      # wait for 15us
	jal delay
	nop

	
	                 # change amplification (b2-b0) to increase contrast
	li  $19, 0b01101101        # x6d follower control: fllwr=on, aplif=5 
	sw  $19, 0($26)
	la $4, LCD_oper_delay      # wait for 15us
	jal delay
	nop

	
check1:	lw   $11, 0($26)
	nop
	andi $11, $11, 0x0080      # check BusyFlag
	move $16, $11
	sw   $16, 0($15)           # write to 7 segment display
	bne  $11, $zero, check1
	nop


	li  $16, 02
	sw  $16, 0($15)            # write to 7 segment display
	la  $4, wait_1_sec         # wait ONE second
	jal delay
	nop


	### wait for internal power to stabilize
#	la $4, LCD_power_cycles    # wait for 200ms, so LCD power is stable
#	jal delay
#	nop

	
	### so far so good
	li  $16, 03
	sw  $16, 0($15)           # write to 7 segment display
	la  $4, wait_1_sec        # wait ONE second
	jal delay
	nop


	### send rest of commands
	# la  $26, HW_lcd_addr       # LCD display

	li  $19, 0b00001111        # x0f displayON/OFF: Off, cur=on, blnk=on
	sw  $19, 0($26)
	la  $4, LCD_oper_delay     # wait for 15us
	jal delay
	nop


	li  $19, 0b00000110        # x06 entry mode: blink, noShift, addrs++
	sw  $19, 0($26)
	la  $4, LCD_oper_delay     # wait for 15us
	jal delay
	nop


	### tell where we are
	li  $16, 4
	sw  $16, 0($15)            # write to 7 segment display
	la $4, wait_1_sec          # wait ONE second
	jal delay
	nop


	li  $19, 0b00000001        # x01 clear display -- DELAY=0.6ms
	sw  $19, 0($26)
	la  $4, LCD_clear_delay    # wait for CLEAR
	jal delay
	nop

	
	li  $19, 0b10000000        # x80 RAMaddrs=0, cursor at home
	sw  $19, 0($26)            #                  -- DELAY=0.6ms
	la  $4,  LCD_clear_delay   # wait for CLEAR
	jal delay
	nop


	### and tell again
	li  $16, 5
	sw  $16, 0($15)            # write to 7 segment display
	la  $4, wait_1_sec         # wait ONE second
	jal delay
	nop


#check:	lw   $19, 0($26)
#	nop
#	andi $19, $19, 0x0080     # check BusyFlag
#	bne  $19, $zero, check
#	nop

	### and tell yet again
#	move  $16, $19
#	sw  $16, 0($15)            # write to 7 segment display
#	la $4, wait_1_sec          # wait ONE second
#	jal delay
#	nop

	
#string:	 .asciiz "Hello world! said cMIPS"	
#	la  $19, 0x6c6c6548
#	la  $19, 0x6f77206f
#	la  $19, 0x21646c72
#	la  $19, 0x69617320
#	la  $19, 0x4d632064
#	la  $19, 0x00535049

	
	### end of commands


	# first line
	li  $19, 0b10000000        # x80 RAMaddrs=0, cursor at home
	sw  $19, 0($26)
	la  $4, LCD_oper_delay     # wait for 15us
	jal delay
	nop

	la  $4, 0x6c6c6548
	jal send
	nop

	la  $4, 0x6f77206f
	jal send
	nop

	la  $4, 0x21646c72
	jal send
	nop

	
#	li  $16, 7
#	sw  $16, 0($15)            # write to 7 segment display
#	la $4, wait_1_sec          # wait ONE second
#	jal delay
#	nop

	
	# second line
	li  $19, 0b11000000        # x80 RAMaddrs=40, cursor at home
	sw  $19, 0($26)
	la  $4, LCD_oper_delay     # wait for 15us
	jal delay
	nop
	
	la  $4, 0x69617320
	jal send
	nop

	la  $4, 0x4d632064
	jal send
	nop

	la  $4, 0x20535049
	jal send
	nop


	li  $16, 0x77
	sw  $16, 0($15)         # write to 7 segment display
	
end:	j end			# wait forever
	nop


### send 4 characters to LCD's RAM
send:	la  $26, HW_lcd_addr    # LCD display
	
	sw   $4, 4($26)		# write character to LCD's RAM
	srl  $4, $4, 8

	la $5, LCD_write_delay
delay0:	addiu $5, $5, -1
	nop
	bne $5, $zero, delay0
	nop

	sw   $4, 4($26)		# write character to LCD's RAM
	srl  $4, $4, 8	

	la $5, LCD_write_delay
delay1:	addiu $5, $5, -1
	nop
	bne $5, $zero, delay1
	nop

	sw  $4, 4($26)		# write character to LCD's RAM
	srl $4, $4, 8

	la $5, LCD_write_delay
delay2:	addiu $5, $5, -1
	nop
	bne $5, $zero, delay2
	nop

	sw  $4, 4($26)		# write character to LCD's RAM
	nop

	la $5, LCD_write_delay
delay3:	addiu $5, $5, -1
	nop
	bne $5, $zero, delay3
	nop

	jr $ra
	nop	
	
	
delay:	addiu $4, $4, -1
	nop
	bne $4, $zero, delay
	nop
	jr $ra
	nop	

	.end _start

	
	### command table in initialized RAM, for when it works	;)
# 	.data
# cmdVec:
        # .byte  0b00110000        # x30 wake-up
        # .byte  0b00110000        # x30 wake-up
        # .byte  0b00111001        # x39 funct: 8bits, 2line, 5x8font, IS=0
        # .byte  0b00010111        # x17 int oscil freq: 1/5bias, freq=700kHz 
        # .byte  0b01110000        # x70 contrast for int follower mode: 0
        # .byte  0b01010110        # x56 pwrCntrl: ICON=off, boost=on, contr=2 
        # .byte  0b01101101        # x6d follower control: fllwr=on, aplif=5 
        # .byte  0b00001111        # x0f displayON/OFF: Off, cur=on, blnk=on
        # .byte  0b00000110        # x06 entry mode: blink, noShift, addrs++
        # .byte  0b00000001        # x01 clear display
        # .byte  0b10000000        # x80 RAMaddrs=0, cursor at home
        # .byte  0b10000000        # x80 RAMaddrs=0, cursor at home
        # .byte  0b11000000        # x80 RAMaddrs=40, cursor at home
	# .byte 0,0
# 
# string:	 .asciiz "Hello world! said cMIPS"
# 
	.bss
nil1:	.space 4
	.sbss
	.data
nil3:	.word 0
	.sdata
nil4:	.word 0

