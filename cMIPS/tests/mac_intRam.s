	.include "cMIPS.s"
        .text
        .align 2
	.set noreorder
        .globl _start
        .ent _start

	# delay loops over four instructions, so divide num cycles by 4
	.set wait_1_sec,       50000000/4 # 1s / 20ns
	.set LCD_power_cycles, 10000000/4 # 200ms / 20ns
	.set LCD_reset_cycles, 2500000/4  # 50ms / 20ns
	.set LCD_clear_delay,  35000/4    # 0.7ms / 20ns
	.set LCD_delay_30us,   1500/4     # 30us / 20ns
	.set LCD_oper_delay,   750/4      # 15us / 20ns
	.set LCD_write_delay,  750/4      # 15us / 20ns

	# smaller constants for simulation
	# .set wait_1_sec,       5   # 1s / 20ns
	# .set LCD_power_cycles, 4   # 200ms / 20ns
	# .set LCD_reset_cycles, 4   # 50ms / 20ns
	# .set LCD_clear_delay,  2   # 0.7ms / 20ns
	# .set LCD_delay_30us,   4   # 30us / 20ns
	# .set LCD_oper_delay,   4   # 15us / 20ns
	# .set LCD_write_delay,  2   # 15us / 20ns

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
        la   $k0, HW_dsp7seg_addr       # 7 segment display
        li   $k1, 0x0399                # display .9.9
        sw   $k1, 0($k0)                # write to 7 segment display
h0000:  j    h0000                      # wait forever
        nop

        .org x_EXCEPTION_0100,0
_excp_0100:
        la   $k0, HW_dsp7seg_addr       # 7 segment display
        li   $k1, 0x0388                # display .8.8
        sw   $k1, 0($k0)                # write to 7 segment display
h0100:  j    h0100                      # wait forever
        nop

        .org x_EXCEPTION_0180,0
_excp_0180:
        la   $k0, HW_dsp7seg_addr       # 7 segment display
        li   $k1, 0x0377                # display .7.7
        sw   $k1, 0($k0)                # write to 7 segment display
h0180:  j    h0180                      # wait forever
        nop

        .org x_EXCEPTION_0200,0
_excp_0200:
        la   $k0, HW_dsp7seg_addr       # 7 segment display
        li   $k1, 0x0366                # display .6.6
        sw   $k1, 0($k0)                # write to 7 segment display
h0200:  j    h0200                      # wait forever
        nop

        .org x_EXCEPTION_BFC0,0
_excp_BFC0:
        la   $k0, HW_dsp7seg_addr       # 7 segment display
        li   $k1, 0x0355                # display .5.5
        sw   $k1, 0($k0)                # write to 7 segment display
hBFC0:  j    hBFC0                      # wait forever
        nop


        .org x_ENTRY_POINT,0

main:	nop

	### tell the world we are alive
	la  $15, HW_dsp7seg_addr   # 7 segment display
	li  $16, 1
	sw  $16, 0($15)            # write to 7 segment display

	la $4, LCD_reset_cycles    # wait for 50ms, so LCDcntrllr resets
	jal delay
	nop

	### WAKE UP commands -- send these at 30us intervals	
	##  peripheral reads only LSbyte, so send a word and it gets a byte

	la  $26, HW_lcd_addr       # LCD display hw address
	li  $21, 4
	la  $19, 0x17393030

wakeup:	sw  $19, 0($26)
	la  $4, LCD_delay_30us     # wait for 30us
	jal delay
	nop
	srl  $19,$19,8              # next command/byte
	addi $21, $21, -1
	bne  $21, $zero, wakeup
	nop

	### display is now on fast clock
	
	### next four commands
	li  $21, 4
	la  $19, 0x0f6d5670

more4:	sw  $19, 0($26)
	nop			    # give some time to LCD controller
	nop
w_m4:	lw   $4, 0($26)		    # wait for BUSYflag=0
	nop
	andi $4, $4, 0x80
	bne  $4, $zero, w_m4
	nop
	srl  $19,$19,8              # next command/byte
	addi $21, $21, -1
	bne  $21, $zero, more4
	nop
	

	li  $19, 0b00000110        # x06 entry mode: blink, Shift, addrs++
	sw  $19, 0($26)
	nop
	nop
w_ntry:	lw   $4, 0($26)
	nop
	andi $4, $4, 0x80
	bne  $4, $zero, w_ntry
	nop

	jal LCDclr
	nop

	la  $15, HW_dsp7seg_addr # 7 segment display
	li  $16, 0x01
	sw  $16, 0($15)            # write to 7 segment display
	la $4, wait_1_sec          # wait ONE second
	jal delay
	nop

	### end of commands +++++++++++++++++++++++++++++++++++++++


        # first line of Hello world!

	# first line
	jal LCDhome1               # cursor at home, clear screen
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

	la $4, wait_1_sec          # wait ONE second
	jal delay
	nop
	
	# second line
	jal LCDhome2
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

	
	### tell where we are
	la  $15, HW_dsp7seg_addr # 7 segment display
	li  $16, 0x02
	sw  $16, 0($15)            # write to 7 segment display

	la $4, wait_1_sec          # wait ONE second
	jal delay
	nop
	

	##
	## test internal FPGA RAM ------------------------------------
	##
	## write chars '0' to '9' to RAM, read them back then print
	##
	jal LCDclr
	nop

	jal LCDhome1
	nop
	
	la $8,  x_DATA_BASE_ADDR
	la $10, 0x33323130       # 
	sw $10, 0($8)
	la $11, 0x37363534       # 
	sw $11, 4($8)
	la $12, 0x00003938       #
	sw $12, 8($8)

loop1:	lbu   $13, 0($8)
	nop
	addiu $8, $8, 1
	beq   $13, $zero, endT1
	nop

	jal  LCDput
	move  $4, $13            # print number

	j    loop1
	nop

endT1:	la  $15, HW_dsp7seg_addr # 7 segment display
	li  $16, 0x03
	sw  $16, 0($15)          # write to 7 segment display
	nop

	jal delay
	la $4, wait_1_sec          # wait ONE second
	jal delay
	la $4, wait_1_sec          # wait ONE second
	
	##
	## 2nd test of internal FPGA RAM -----------------------------
	##
	## write chars 'a' to 'z' to RAM, read them back then print
	##
	jal LCDhome2
	nop
	
	la $8,  x_DATA_BASE_ADDR
	li $9,  'a'
	li $10, 'p'	# 'a'..'p' = one full display line

loop2:	sb    $9, 0($8)		# store char
	addiu $9, $9, 1	
	lbu   $13, 0($8)	# read it back
	addiu $8, $8, 1

	jal   LCDput		# then print it
	move  $4, $13
	
	beq   $13, $10, endT2
	nop

	j    loop2
	nop

endT2:	la  $15, HW_dsp7seg_addr # 7 segment display
	li  $16, 0x04

endAll:	sw  $16, 0($15)          # write to 7 segment display

	la  $4, wait_1_sec       # wait ONE second
	jal delay
	addi $16, $16,1
	
	j   endAll               # wait forever 
	nop

#----------------------------------------------------------------------
	
	
### send one character to LCD's RAM -----------------------------------
LCDput:	la   $6, HW_lcd_addr    # LCD display
	sw   $4, 4($6)		# write character to LCD's RAM
	nop			# give the controller time
	nop
dlyput:	lw   $4, 0($6)
	nop
	andi $4, $4, 0x80
	bne  $4, $zero, dlyput
	nop

	jr $ra
	nop
#----------------------------------------------------------------------


### put cursor at home, write do 1st position of 1st line -------------
LCDhome1:
	la  $6, HW_lcd_addr   # LCD display
	li  $4, 0b10000000      # x80 RAMaddrs=00, cursor at home
	sw  $4, 0($6)

	nop
	nop			# give the controller time
	nop	
dlyhm1:	lw   $4, 0($6)
	nop
	andi $4, $4, 0x80
	bne  $4, $zero, dlyhm1
	nop

	jr $ra
	nop
#----------------------------------------------------------------------

### put cursor at home, write do 1st position of 2nd line -------------
LCDhome2: la  $6, HW_lcd_addr   # LCD display
	li  $4, 0b11000000      # xc0 RAMaddrs=40, cursor at home
	sw  $4, 0($6)
	
#	la  $4, LCD_clear_delay    # wait for CLEAR
#dlyhm2:	addiu $4, $4, -1
#	nop
#	bne $4, $zero, dlyhm2
#	nop
	
	nop
	nop			# give the controller time
	nop	
dlyhm2:	lw   $4, 0($6)
	nop
	andi $4, $4, 0x80
	bne  $4, $zero, dlyhm2
	nop

	jr $ra
	nop
#----------------------------------------------------------------------

### clear display and send cursor home -------------------------------
LCDclr: la  $6, HW_lcd_addr     # LCD display
	li  $4, 0b00000001      # x01 clear display -- DELAY=0.6ms
	sw  $4, 0($6)

	la  $4, LCD_clear_delay    # wait for CLEAR
dlyclr:	addiu $4, $4, -1
	nop
	bne $4, $zero, dlyclr
	nop


#	nop
#	nop			# give the controller time
#	nop	
#dlyclr:	lw   $4, 0($6)
#	nop
#	andi $4, $4, 0x80
#	bne  $4, $zero, dlyclr
#	nop

	jr $ra
	nop
#----------------------------------------------------------------------

	
### send 4 characters to LCD's RAM ------------------------------------
send:	la  $26, HW_lcd_addr    # LCD display

	andi $6, $4, 0xff
	sw   $6, 4($26)		# write character to LCD's RAM
	srl  $4, $4, 8

	la $5, LCD_write_delay
delay0:	addiu $5, $5, -1
	nop
	bne $5, $zero, delay0
	nop

	andi $6, $4, 0xff
	sw   $6, 4($26)		# write character to LCD's RAM
	srl  $4, $4, 8
	
	la $5, LCD_write_delay
delay1:	addiu $5, $5, -1
	nop
	bne $5, $zero, delay1
	nop

	andi $6, $4, 0xff
	sw   $6, 4($26)		# write character to LCD's RAM
	srl  $4, $4, 8
	
	la $5, LCD_write_delay
delay2:	addiu $5, $5, -1
	nop
	bne $5, $zero, delay2
	nop

	andi $6, $4, 0xff
	sw   $6, 4($26)		# write character to LCD's RAM

	la $5, LCD_write_delay
delay3:	addiu $5, $5, -1
	nop
	bne $5, $zero, delay3
	nop

	jr $ra
	nop	
# ---------------------------------------------------------------------
	

### delay for N/4 processor cycles ------------------------------------	
delay:	addiu $4, $4, -1
	nop
	bne $4, $zero, delay
	nop
	jr $ra
	nop
	
	.end _start

	.data
vec:	.space 4,0xffffffff
	
	
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
        # .byte  0b11000000        # xc0 RAMaddrs=40, cursor at home
	# .byte 0,0
# 
#string:	 .asciiz "Hello world! said cMIPS"	
#	la  $19, 0x6c6c6548
#	la  $19, 0x6f77206f
#	la  $19, 0x21646c72
#	la  $19, 0x69617320
#	la  $19, 0x4d632064
#	la  $19, 0x00535049
