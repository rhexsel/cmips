	.include "cMIPS.s"
	.text
	.align 2
	.set noat
	.globl _start
	.ent _start

_start: la   $15, x_IO_BASE_ADDR  # stdout
	addi $1, $0, 1
	addi $5, $0, 5

	nop	# do not touch these 3 NOPS
	nop
	nop

        add $6, $5, $1  # $5 + 1
	nop		# remove on first test
	nop		# remove on second test
	nop		# remove on third test

        add $7, $6, $1  # $6 + 1
	nop		# remove on first test
	nop		# remove on second test
	nop		# remove on third test
	
        add $8, $7, $1  # $7 + 1
	nop		# remove on first test
	nop		# remove on second test
	nop		# remove on third test

        sw  $6, 0($15) 	# print $6
        sw  $7, 0($15) 	# print $7
        sw  $8, 0($15) 	# print $8
	
	nop	# do not touch these 5 NOPS
	nop	# they are here to flush the pipeline
	nop
	nop
	nop
	wait	# end simulation
	nop
	.end _start
