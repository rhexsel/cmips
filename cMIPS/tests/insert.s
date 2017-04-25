	# mips-as -O0 -EL -mips32 -o start.o start.s
	.include "cMIPS.s"
	.text
	.align 2
	.global _start
	.global _exit
	.global exit
	.ent _start
_start: nop
	li   $k0,0x10000002     # RESET_STATUS, kernel mode, all else disabled
	mtc0 $k0,c0_status
	li   $sp,(x_DATA_BASE_ADDR+x_DATA_MEM_SZ-8)  # initialize SP: memTop-8
	li   $k0,0x00000000     # nothing happens
	mtc0 $k0,c0_cause
        li   $k0, 0x1000ff01    # enable interrupts
        mtc0 $k0, c0_status
	nop
	jal main
exit:	
_exit:	nop	     # flush pipeline
	nop
	nop
	nop
	nop
	wait  # then stop VHDL simulation
	nop
	nop
	.end _start

	
	.org x_EXCEPTION_0180,0 # exception vector_180 at 0x00000060
	.global excp_180
	.ent excp_180
excp_180:
	mfc0 $k0, c0_cause  # show cause
	sw   $k0, 0($15)
	li   $k1, 0x00000000  # disable SW interrupt
	mtc0 $k1, c0_cause
        li   $k0, 0x1000ff00  # disable interrupts
        mtc0 $k0, c0_status
	eret
	.end excp_180

	
	.org x_ENTRY_POINT,0 # normal code at 0x0000.0100
	.ent main
main:	la $15,x_IO_BASE_ADDR  # print 0x200 and count downwards

	li $6,0x000003ff
	
	# ins rt, rs, pos, size
	li $7,0x55555555
	ins   $7,$6,0,10	# 5555.57ff
	sw    $7, 0($15)

	li $7,0x55555555
	ins   $7,$6,0,8         # 5555.55ff
	sw    $7, 0($15)

	li $7,0x55555555
	ins   $7,$6,0,20	# 5550.03ff
	sw    $7, 0($15)

	li $7,0x55555555
	ins   $7,$6,0,32        # 0000.03ff
	sw    $7, 0($15)


	sw $zero,0($15)

	
	li $6,0x88888888
	
	li $7,0x55555555
	ins   $7,$6,8,24        # 8888.8855
	sw    $7, 0($15)

	li $7,0x55555555
	ins   $7,$6,0,32        # 8888.8888
	sw    $7, 0($15)


	sw $zero,0($15)

	
	li $6,0x0000000a

	# ins rt, rs, pos, size
	li $7,0x55555555
	ins   $7,$6,28,4	# a555.5555
	sw    $7, 0($15)

	li $7,0x55555555
	ins   $7,$6,24,4        # 5a55.5555
	sw    $7, 0($15)

	li $7,0x55555555
	ins   $7,$6,20,4	# 55a5.5555
	sw    $7, 0($15)

	ins   $7,$6,16,4        # 55aa.5555
	sw    $7, 0($15)

	ins   $7,$6,12,4        # 55aa.a555
	sw    $7, 0($15)

	ins   $7,$6,8,4         # 55aa.aa55
	sw    $7, 0($15)

	ins   $7,$6,4,4         # 55aa.aaa5
	sw    $7, 0($15)


	sw    $zero,0($15)


	li $6,0x00000011

	# ins rt, rs, pos, size
	li $7,0x55555555
	ins   $7,$6,5,5		# 5555.5635
	sw    $7, 0($15)

	li $7,0x55555555
	ins   $7,$6,5,6		# 5555.5235
	sw    $7, 0($15)

	li $7,0x55555555
	ins   $7,$6,17,5	# 5562.5555
	sw    $7, 0($15)

	li $7,0x55555555
	ins   $7,$6,27,5	# 8d55.5555
	sw    $7, 0($15)


	
	j exit

	.end main
