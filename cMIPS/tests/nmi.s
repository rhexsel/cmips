# to test the non maskable interrupt (NMI) connect the interrupt signal
# from the EXTERNAL counter (the one on the testbench) to the NMI input
# on the core.

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
	li   $k0,0x00000700
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
	.global _excp_180
	.global excp_180
	.global _excp_200
	.global excp_200
	.ent excp_180
excp_180:
_excp_180:
	la   $k0, x_IO_BASE_ADDR + (0x100*4)   # counter address
        li   $k1, 0x00000000  		# remove interrupt request
        sw   $k1, 0($k0)
        li   $k1, 0x80000100            # restart counter
        sw   $k1, 0($k0)
        li   $k0, 0x1000ff01
        mtc0 $k0, c0_status
	eret
	.end excp_180


	.org x_EXCEPTION_0000,0 # exception vector_0000 at 0x0000.00a0
        .ent excp_0000
excp_0000:
_excp_0000:
        mfc0 $k0, c0_status  # read STATUS
	sw   $k0,0($15)	       # and print its contents
	j nmi_reset_handler
	nop
excp_0000ret:
        li   $k0, 0x1000ff03   # enable interrupts, still in kernel mode
        mtc0 $k0, c0_status
        eret

nmi_reset_handler:  # handler for NMI or soft-reset
        j exit                 # or do something else!
        j excp_0000ret
        .end excp_0000

	
	.org x_ENTRY_POINT,0 # normal code at 0x0000.0100
	.ent main
main:	la $15,x_IO_BASE_ADDR  # print 0x200 and count downwards
	li $5,0x200
        la $16, x_IO_BASE_ADDR + (0x100*4)   # counter address
        li $k1, 0x80000020       # interrupt after 32 cycles
	sw $k1, 0($16)
	nop
loop:	sw    $5, 0($15)
	addiu $5,$5,-1
	bne   $5,$zero,loop
	nop
	j exit
	
	.end main

# 00000200
# 000001ff
# 000001fe
# 000001fd
# 000001fc
# 000001fb
# 000001fa
# 1048ff05

	