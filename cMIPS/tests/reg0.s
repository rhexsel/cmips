        .include "cMIPS.s"
        .text
        .align 2
        .set noat
        .globl _start
        .ent _start
_start: nop
        la $15, x_IO_BASE_ADDR
	li $16, '\n'
	
	li $0, 5       # $0 = 5
	sw $0, ($15)            # print $0's vaule
	sw $0, ($15)            # print $0's vaule
	sw $0, ($15)            # print $0's vaule
	sw $0, ($15)            # print $0's vaule
	sw $0, ($15)            # print $0's vaule
	nop 			# need this to separate IO addresses [1]
	sw $16, x_IO_ADDR_RANGE($15) # print a blank line

	li $0, 5       # $0 = 5
	nop
	sw $0, ($15)            # print $0's vaule
	nop 			# need this to separate IO references
	sw $16, x_IO_ADDR_RANGE($15) # print a blank line

	li $0, 5       # $0 = 5
	sw $0, ($15)            # print $0's vaule
	nop 			# need this to separate IO references
	sw $16, x_IO_ADDR_RANGE($15) # print a blank line
	nop
	nop
	nop
	wait
	nop
	.end _start


	# for simulation purposes only: GHDL's simulator does not react
	#   to the change in address for successive I/O references  B^(

	