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

	li $6,0x55555555

	# ext rt, rs, pos, size
	ext   $7,$6,0,10	# 0000.0155
	sw    $7, 0($15)

	ext   $7,$6,0,8         # 0000.0055
	sw    $7, 0($15)

	ext   $7,$6,10,10	# 0000.0155
	sw    $7, 0($15)

	ext   $7,$6,16,16       # 0000.5555
	sw    $7, 0($15)

	ext   $7,$6,8,24        # 0055.5555
	sw    $7, 0($15)

	ext   $7,$6,0,32        # 5555.5555
	sw    $7, 0($15)


	li $6,0xaaaaaaaa

	# ext rt, rs, pos, size
	ext   $7,$6,0,10	# 0000.02aa
	sw    $7, 0($15)

	ext   $7,$6,0,8         # 0000.00aa
	sw    $7, 0($15)

	ext   $7,$6,10,10	# 0000.02aa
	sw    $7, 0($15)

	ext   $7,$6,16,16       # 0000.aaaa
	sw    $7, 0($15)

	ext   $7,$6,8,24        # 00aa.aaaa
	sw    $7, 0($15)

	ext   $7,$6,0,32        # aaaa.aaaa
	sw    $7, 0($15)


	sw    $zero,0($15)
	li $6,0xaaaaaaaa
	
	# ext rt, rs, pos, size
	ext   $7,$6,0,13	# 0000.0aaa
	sw    $7, 0($15)

	ext   $7,$6,1,13	# 0000.1555
	sw    $7, 0($15)

	ext   $7,$6,2,13	# 0000.0aaa
	sw    $7, 0($15)

	ext   $7,$6,3,13	# 0000.1555
	sw    $7, 0($15)


	sw    $zero,0($15)
	li $6,0xaaaaaaaa

	ext   $7,$6,16,13       # 0000.0aaa
	sw    $7, 0($15)

	ext   $7,$6,17,13	# 0000.1555
	sw    $7, 0($15)

	ext   $7,$6,18,13       # 0000.0aaa
	sw    $7, 0($15)

	ext   $7,$6,19,13       # 00aa.1555
	sw    $7, 0($15)

	
	j exit

	.end main
