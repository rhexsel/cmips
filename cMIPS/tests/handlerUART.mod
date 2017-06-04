	
	# .set UART_rx_irq,0x08
	# .set UART_tx_irq,0x10
	.set UART_tx_bfr_empty,0x40

	# save registers


	# replace $xx for the apropriate registers

	lui   $xx, %hi(HW_uart_addr)  # get device's address
	ori   $xx, $xx, %lo(HW_uart_addr)
	
	# your code goes here
	
	#---------------------------------------------------
	# handle reception
UARTrec:
	lw    $xx, UDATA($xx) 	# Read data from device

	# your code goes here
	
	j     _return
	nop

	
	
	#---------------------------------------------------
	# handle transmission
UARTtra:	

	# your code goes here
	
	sw    $xx, UDATA($xx) 	# Read data from device


	#---------------------------------------------------
	# return	
	
_return:

	# restore registers


	eret			    # Return from interrupt

