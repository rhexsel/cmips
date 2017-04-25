	# mips-as -O0 -EL -mips32 -o start.o start.s
	.include "cMIPS.s"
	.text
	.align 2
	.set noreorder
	.global _start, _exit, exit
	
	.ent _start
_start: nop
	li   $k0,0x10000002     # RESET_STATUS, EXL=1, all else disabled
	mtc0 $k0,c0_status
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8)  # initialize SP: memTop-8
        li   $k0, 0x1000ff01    # enable interrupts, EXL=0
        mtc0 $k0, c0_status
	nop
	j    main
	nop

exit:	
_exit:	nop	     # flush pipeline
	nop
	nop
	nop
	nop
	wait         # then stop VHDL simulation
	nop
	nop
	.end _start


	
        .org x_EXCEPTION_0000,0
_excp_0000:
        la   $k0, x_IO_BASE_ADDR
        mfc0 $k1, c0_cause
        sw   $k1, 0($k0)        # print CAUSE, flush pipe and stop simulation
        nop
        nop
        nop
        wait 0x01
        nop
        .org x_EXCEPTION_0100,0
_excp_0100:
        la   $k0, x_IO_BASE_ADDR
        mfc0 $k1, c0_cause
        sw   $k1, 0($k0)        # print CAUSE, flush pipe and stop simulation
        nop
        nop
        nop
        wait 0x02
        nop

	
	
	.org x_EXCEPTION_0180,0
	.global excp_180
	.ent excp_180
excp_180:
	mfc0 $k0, c0_cause  # show cause
	sw   $k0, 0($15)
	li   $k1, 0x00000000  # remove SW interrupt request
	mtc0 $k1, c0_cause
	li   $k0, 0x1000ff03  # enable interrupts, user mode, EXL=1
        mtc0 $k0, c0_status
	eret
	nop
	.end excp_180


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



	##
	##=================================================================
	##	
	.org x_ENTRY_POINT,0
	.ent main
main:	la    $15, x_IO_BASE_ADDR  # print $5=8 and count downwards
	li    $5, 8
	li    $6, 4
	li    $t1, 0
	la    $t0, x_DATA_BASE_ADDR
	li    $s0, 's'
	li    $s1, '\n'
	li    $k1, 0x00000100  # cause SW interrupt after 4 rounds
	sw    $zero, 0($t0)
	nop
loop:	sw    $5, 0($15)      # print-out $5
	nop
L:	ll    $t1, 0($t0)     # load-linked
	addiu $5, $5, -1
	bne   $5, $6, fwd     # four rounds yet?
	nop
	
	mtc0 $k1, c0_cause    # causes SC to fail and prints 0000.0000=CAUSE

	nop	# must delay SC so that interrupt starts before the SC
	nop
	nop
	nop

fwd:	addi $t2, $t1, 1   # increment value read by LL
	sc   $t2, 0($t0)   # try to store, checking for atomicity
	addiu $t0,$t0,4    # use a new address in each round
	sw   $s0, x_IO_ADDR_RANGE($15)   # prints 0000.0001 if SC succeeds
	sw   $s1, x_IO_ADDR_RANGE($15)   # prints 0000.0001 if SC succeeds
	beq  $t2, $zero, L # if not atomic (0), try again, does not print 4
	sw   $zero, 0($t0) # store zero to new address

	bne  $5,$zero, loop
	nop

	sw   $zero, 0($t0) # clear untouched location
	nop
	lw   $t2, 0($t0)   # print untouched location = 0000.0000
	sw   $t2, 0($15)
	nop

	li   $k1, 0x00000000  # clear CAUSE
	mtc0 $k1, c0_cause
	li   $k0, 0x10000002  # RESET_STATUS, EXL=1, all else disabled
	mtc0 $k0, c0_status

	
	##
	## do a SC to the same address as ll -- must succeed
	##

test1:	li   $30, '\n'     	# print a blank line to separate tests
        sw   $30, x_IO_ADDR_RANGE($15)

	la  $t0, x_DATA_BASE_ADDR
	li  $a0, 0xffffffff
	sw  $a0, 0($t0)

	ll  $a1, 0($t0)
	nop 
	sw  $a1, 0($15)	
	nop
	li  $a2, 256-1
	sc  $a2, 0($t0)		# same address -- must succeed
	nop
	beq $a2, $zero, error
	nop
	lw  $a3, 0($t0)
	sw  $a3, 0($15) 	# print out 0xff	

	##
	## try to sc to a different adress from ll -- must fail
	##
	
test2:	li   $30, '\n'     	# print a blank line to separate tests
        sw   $30, x_IO_ADDR_RANGE($15)
	
	la  $t0, x_DATA_BASE_ADDR
	li  $a0, 0xffffffff	# store -1 to data[0]
	li  $a1, 0x88442211	# store 88442211 to data[1]
	sw  $a0, 0($t0)
	sw  $a1, 4($t0) 	# address to store_c != addr to load_l
	
	ll  $a1, 0($t0)	 	# load-linked from data[0]
	li  $a2, 4096-1 	# attempt to write 0x0ffff to data[1]
	sw  $a1, 0($15)		# display data[0]

	sc  $a2, 4($t0)	 	# different address from ll -- must fail
	## branch forwarding clears this hazard on $a2
	beq $a2, $zero, did_ok
	nop

succ_nok: 			# should never get here
	lw  $a3, 4($t0)
	sw  $a2, 0($15)		# print out wrong value stored to data[1]
	beq $a3, $a2, error	# sc did change data[1]
	nop
	# sc ought to have failed, which is the expected result, good!

did_ok:	jal fail_ok
	nop


	##
	## repeat above test, with different branch forwarding (one nop)
	##
test3:	li   $30, '\n'     	# print a blank line to separate tests
        sw   $30, x_IO_ADDR_RANGE($15)
	
	la  $t0, x_DATA_BASE_ADDR
	li  $a0, 0x55555555	# store -1 to data[0]
	li  $a1, 0x88442211	# store 88442211 to data[1]
	sw  $a0, 0($t0)
	sw  $a1, 4($t0) 	# address to store_c != addr to load_l
	
	ll  $a1, 0($t0)	 	# load-linked from data[0]
	li  $a2, 4096-1 	# attempt to write 0x0ffff to data[1]
	sw  $a1, 0($15)		# display data[0]

	sc  $a2, 4($t0)	 	# different address from ll -- must fail
	nop			## branch forwarding clears this hazard on $a2
	beq $a2, $zero, did_ok3
	nop

succ_nok3: 			# should never get here
	lw  $a3, 4($t0)
	sw  $a2, 0($15)		# print out wrong value stored to data[1]
	beq $a3, $a2, error	# sc did change data[1]
	nop
	# sc ought to have failed, which is the expected result, good!

did_ok3:
	jal fail_ok
	nop
	
	##
	## check forwarding from SC to ALU inputs
	##
fwdadd:	li   $30, '\n'     	# print a blank line to separate tests
        sw   $30, x_IO_ADDR_RANGE($15)

	la  $t0, x_DATA_BASE_ADDR
	li  $a0, 0xffffffff	# store -1 to data[0]
	li  $a1, 0x88442211	# store 88442211 to data[1]
	sw  $a0, 0($t0)
	sw  $a1, 4($t0) 	# address to store_c != addr to load_l

	ll  $a2, 0($t0)
	li  $a2, 2048-1 	# attempt to write 0x03ff to data[0]
	sc  $a3, 0($t0)		#   should succeed - a3 := 1
	addi $a3, $a3, -1
	bne  $a3, $zero, error
	nop

	jal fail_ok
	nop

fwdadd2:
	li   $30, '\n'     	# print a blank line to separate tests
        sw   $30, x_IO_ADDR_RANGE($15)
	li   $s5, 1

	ll  $a2, 0($t0)
	li  $a2, 64-1 		# attempt to write 0x003f to data[1]
	sc  $a3, 4($t0)		#   should fail: a3 <-0 
	addi $s6, $a3, 1	#  s6 <- 0 + 1
	bne  $s5, $s6, error    #  (0+1) == 1 ?
	nop
	
	jal fail_ok
	nop

	j exit
	nop
	
		
error:  li   $30, 'e'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'r'
        sw   $30, x_IO_ADDR_RANGE($15)
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $28, 'o'
        sw   $28, x_IO_ADDR_RANGE($15)
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, '\n'              # print a blank line
	j exit
        sw   $30, x_IO_ADDR_RANGE($15)


fail_ok:
	li   $30, 'o'
        sw   $30, x_IO_ADDR_RANGE($15)
        li   $30, 'k'
	sw   $30, x_IO_ADDR_RANGE($15)	
        li   $30, '\n'              # print a blank line
	jr   $ra
        sw   $30, x_IO_ADDR_RANGE($15)	

	.end main

