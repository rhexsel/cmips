# cmips
All things related to cMIPS, a synthesizable VHDL model for the 5-stage pipeline, MIPS32r2 core.

The VHDL model mimics the pipeline design described in Patterson & Hennessy's
book (Computer Organisation and Design) and is a complete implementation
of the MIPS32r2 instruction set.

The model was synthesized for an Altera EP4CE30F23.  The model runs at 50 MHz
(top board speed) and uses up 22% of the combinational blocks, 9% of the
logic registers, and 33% of the memory bits on the FPGA.

The processor model runs C code, compiled with GCC;  there are scripts to
compile and assemble code to run on the simulator or for sythesis.

The core has all forwarding paths and is fully interlocked for data and
control hazards.

Coprocessor0 supports six hardware interrupts + NMI in "Interrupt
Compatibility Mode" and an 8-way fully associative TLB.  The control
instructions break, syscall, trap, mfc0, mtc0, eret, ei, di, ll, sc
are fully implemented.

Partial-word loads and stores (word, half-word, byte, lwl,lwr,swl,swr) are
implemented.

A simulation testbench includes processor, RAM, ROM and (simulator) file I/O.

Top level file for synthesis includes processor, RAM, ROM, LCD display
controller, 2x7segment LED display, keypad and UART.  SDRAM controller,
VGA interface and Ethernet port are in the works.

See docs/cMIPS.pdf for a more complete description.
