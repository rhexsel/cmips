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
	li $5,4
	li $6,126

L1:	seb   $7,$6
	sw    $7, 0($15)
	addiu $6,$6,1
	addiu $5,$5,-1
	bne   $5,$zero, L1

	li $5,4
	li $6,0x7ffe

L2:	seh   $7,$6
	sw    $7, 0($15)
	addiu $6,$6,1
	addiu $5,$5,-1
	bne   $5,$zero, L2

	li $5,4
	li $6,0x55aacc66
	sw    $6, 0($15)
	
L3:	wsbh  $7,$6
	sw    $7, 0($15)
	la    $8,0x555555
	xor   $6,$6,$8
	sw    $6, 0($15)
	addiu $5,$5,-1
	bne   $5,$zero, L3
	wsbh  $7,$6
	sw    $7, 0($15)

	j exit

	.end main
