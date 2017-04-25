	###
	### these are functional tests to the BUS-SDcard controller interface
	###   this program DOES NOT test the SDcard controller itself
	###
	###*************************************************************
	###  
	###  DO NOT RUN THIS TEST ON THE BOARD
	###    ACTIONS IN IT MAY DAMAGE THE CONTROLLER AND OR THE SDcard
	###
	###*************************************************************
	###

	.include "cMIPS.s"
        .text
        .align 2
	.set noreorder
	.set noat
        .globl _start
        .ent _start

	.equ DELAY,1
	
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
	li   $k1, 0x0399		# display .9.9
	sw   $k1, 0($k0)		# write to 7 segment display
h0000:	j    h0000			# wait forever
	nop
	
        .org x_EXCEPTION_0100,0
_excp_0100:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x0388		# display .8.8
	sw   $k1, 0($k0)		# write to 7 segment display
h0100:	j    h0100			# wait forever
	nop
	
        .org x_EXCEPTION_0180,0
_excp_0180:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x0377		# display .7.7
	sw   $k1, 0($k0)		# write to 7 segment display
h0180:	j    h0180			# wait forever
	nop
	
        .org x_EXCEPTION_0200,0
_excp_0200:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x0366		# display .6.6
	sw   $k1, 0($k0)		# write to 7 segment display
h0200:	j    h0200			# wait forever
	nop
	
        .org x_EXCEPTION_BFC0,0
_excp_BFC0:
	la   $k0, HW_dsp7seg_addr  	# 7 segment display
	li   $k1, 0x0355		# display .5.5
	sw   $k1, 0($k0)		# write to 7 segment display
hBFC0:	j    hBFC0			# wait forever
	nop


        .org x_ENTRY_POINT,0
	
main:	nop

	.equ RED,0x4000
	.equ GRE,0x2000
	.equ BLU,0x1000
	.equ OFF,0x03ff		   # mask off RGB leds, leave other bits 
	
	### tell the world we are alive
	la  $15, HW_dsp7seg_addr   # 7 segment display
	li  $16, 00
	sw  $16, 0($15)            # write to 7 segment display

	jal delay_ms		   # and wait for 1 second
	li  $a0, DELAY
	
	la  $5, HW_SDcard_addr	   # SD card controller

	##
	## let us write 0xffff.ffff to the address register
	##
	li  $6, -1
	sw  $6, 0($5)
	nop
	nop
	## and then read it back
	lw  $6, 0($5)
	nop

	## new test ---------------------------------------------------
	li  $16, 01
	sw  $16, 0($15)             # write to 7 segment display

	jal delay_ms		    # and wait for 1 second
	li  $a0, DELAY
	
	##
	## let us read the status register
	##
	## rgb values are in [0,7], stored in bits RGB=bit(14,13,12)
	lw   $7, 3*4($5)            # read status register for error
	nop
	move $8,$7		    # keep a copy

	srl  $2, $7, 31		    # controller busy?
	nop
	beq  $2, $zero, notBusy
	nop

	j    showIt
	li   $25, RED		    # light up RED led

notBusy:
	li   $25, GRE		    # light up GREEN led

showIt:
	andi $23, $7, 0xff	    # keep bits 7..0
	or   $24, $23, $25

	sw   $24, 0($15)            # write to 7 segment display

	jal delay_ms		    # and wait for 1 second
	li   $a0, DELAY

	andi $23, $7, 0xff00	    # keep bits 15..8
	srl  $23, $23, 8
	or   $24, $23, $25	    # light up led

	sw   $24, 0($15)            # write to 7 segment display
	nop

	jal delay_ms		    # and wait for 1 second
	li  $a0, DELAY

	
	## new test ---------------------------------------------------
	li  $16, 02
	sw  $16, 0($15)            # write to 7 segment display

	jal delay_ms		   # and wait for 1 second
	li  $a0, DELAY
	
	##
	## let us read the DATAinp register
	##
	lw   $8, 1*4($5)            # read from DATA register
	nop

	lw   $7, 3*4($5)            # read status register for error
	nop
	srl  $2, $7, 31		    # controller busy?
	nop
	beq  $2, $zero, notBusy2 
	nop

	j    showIt2
	li   $25, RED		    # light up RED led

notBusy2:
	li   $25, GRE		    # light up GREEN led

showIt2:
	andi $23, $8, 0xff	    # keep bits 7..0
	or   $24, $23, $25

	sw   $24, 0($15)            # write to 7 segment display
	nop

	jal delay_ms		    # and wait for 1 second
	li   $a0, DELAY

	
	## new test ---------------------------------------------------
	li  $16, 03
	sw  $16, 0($15)            # write to 7 segment display

	jal delay_ms		   # and wait for 1 second
	li  $a0, DELAY

	##
	## let us write to the DATAout register
	##
	li   $a0, 0x55
	sw   $a0, 1*4($5)           # write to DATA register
	nop

	lw   $7, 3*4($5)            # read status register for error
	nop
	srl  $2, $7, 31		    # controller busy?
	nop
	beq  $2, $zero, notBusy3
	nop

	j    showIt3
	li   $25, RED		    # light up RED led

notBusy3:
	li   $25, GRE		    # light up GREEN led

showIt3:
	andi $23, $7, 0xff	    # keep bits 7..0
	or   $24, $23, $25

	sw   $24, 0($15)            # write to 7 segment display

	jal delay_ms		    # and wait for 1 second
	li   $a0, DELAY

	andi $23, $7, 0xff00	    # keep bits 15..8
	srl  $23, $23, 8
	or   $24, $23, $25	    # light up led

	sw   $24, 0($15)            # write to 7 segment display

	jal delay_ms		    # and wait for 1 second
	li   $a0, DELAY


	## new test ---------------------------------------------------
	li  $16, 04
	sw  $16, 0($15)            # write to 7 segment display

	jal delay_ms		   # and wait for 1 second
	li  $a0, DELAY
	##
	## let us write 0x10 to the CTRL register to reset the controller
	##
	li  $7, 0x0010		   # activate reset bit
	sw  $7, 2*4($5)
	nop			   # wait a little
	nop
	nop
	nop
	nop

	lw   $7, 3*4($5)            # read status register for error
	nop
	srl  $2, $7, 31		    # controller busy?
	nop
	beq  $2, $zero, notBusy4
	nop

	j    showIt4
	li   $25, RED		    # light up RED led

notBusy4:
	li   $25, GRE		    # light up GREEN led

showIt4:
	andi $23, $7, 0xff	    # keep bits 7..0
	or   $24, $23, $25

	sw   $24, 0($15)            # write to 7 segment display

	jal delay_ms		    # and wait for 1 second
	li   $a0, DELAY

	andi $23, $7, 0xff00	    # keep bits 15..8
	srl  $23, $23, 8
	or   $24, $23, $25	    # light up led

	sw   $24, 0($15)            # write to 7 segment display

	jal delay_ms		    # and wait for 1 second
	li   $a0, DELAY

	

	## new test ---------------------------------------------------
	li  $16, 05
	sw  $16, 0($15)            # write to 7 segment display

	jal delay_ms		   # and wait for 1 second
	li  $a0, DELAY
	##
	## let us activate wr_i read the status register
	##
	li  $7, 0x0001		   # activate wr_i bit
	sw  $7, 2*4($5)
	nop			   # wait a little
	nop
	nop
	nop
	nop
	li  $7, 0x0000		   # clear wr_i bit by writing to DATAout
	sw  $7, 1*4($5)
	nop			   # wait a little
	nop
	nop
	nop
	nop

	lw   $7, 3*4($5)            # read status register for error
	nop
	move $8,$7		    # keep a copy

	srl  $2, $7, 31		    # controller busy?
	nop
	beq  $2, $zero, notBusy5
	nop

	j    showIt5
	li   $25, (1<<12)	    # light up RED led

notBusy5:
	li   $25, (1<<11)	    # light up GREEN led

showIt5:
	andi $23, $7, 0xff	    # keep bits 7..0
	or   $24, $23, $25

	sw   $24, 0($15)            # write to 7 segment display

	jal delay_ms		    # and wait for 1 second
	li   $a0, DELAY

	andi $23, $7, 0xff00	    # keep bits 15..8
	srl  $23, $23, 8
	or   $24, $23, $25	    # light up led

	sw   $24, 0($15)            # write to 7 segment display
	nop


	## new test ---------------------------------------------------
	li  $16, 06
	sw  $16, 0($15)            # write to 7 segment display

	jal delay_ms		   # and wait for 1 second
	li  $a0, DELAY
	##
	## let us activate rd_i read the status register
	##
	li  $7, 0x0002		   # activate rd_i bit
	sw  $7, 2*4($5)
	nop			   # wait a little
	nop
	nop
	nop
	nop
	lw  $7, 1*4($5)		   # clear rd_i bit by reading from DATAout
	nop			   # wait a little
	nop
	nop
	nop
	nop

	lw   $7, 3*4($5)            # read status register for error
	nop
	move $8,$7		    # keep a copy

	srl  $2, $7, 31		    # controller busy?
	nop
	beq  $2, $zero, notBusy6
	nop

	j    showIt6
	li   $25, (1<<12)	    # light up RED led

notBusy6:
	li   $25, (1<<11)	    # light up GREEN led

showIt6:
	andi $23, $7, 0xff	    # keep bits 7..0
	or   $24, $23, $25

	sw   $24, 0($15)            # write to 7 segment display

	jal delay_ms		    # and wait for 1 second
	li   $a0, DELAY

	andi $23, $7, 0xff00	    # keep bits 15..8
	srl  $23, $23, 8
	or   $24, $23, $25	    # light up led

	sw   $24, 0($15)            # write to 7 segment display
	nop





	## end of tests ------------------------------------------------
	li  $16, 0x00ff
	sw  $16, 0($15)            # write 0xff to 7 segment display
	
here:	j here
	nop
	
	
end:	nop
	nop
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
        jr    $ra
        nop


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

	

	.bss
nil1:	.space 4
	.sbss
	.data
nil3:	.word 0
	.sdata
nil4:	.word 0

