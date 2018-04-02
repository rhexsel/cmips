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

        add $5,$5,$1    # $5 + 1
	nop		# remove on first test
	nop		# remove on second test
	nop		# remove on third test
        sw  $5, 0($15) 	# print $5

        add $5,$5,$1    # $5 + 1
	nop		# remove on first test
	nop		# remove on second test
	nop		# remove on third test
        sw  $5, 0($15) 	# print $5
	
        add $5,$5,$1    # $5 + 1
	nop		# remove on first test
	nop		# remove on second test
	nop		# remove on third test
        sw  $5, 0($15) 	# print $5

	nop	# do not touch these 5 NOPS
	nop	# flush the pipeline
	nop
	nop
	nop
	wait	# end simulation
	nop
	.end _start
