
	# see vhdl/packageMemory.vhd for addresses
        .set x_INST_BASE_ADDR,0x00000000
        .set x_INST_MEM_SZ,0x00004000

        .set x_DATA_BASE_ADDR,0x00040000
        .set x_DATA_MEM_SZ,0x00020000
	
        .set x_IO_BASE_ADDR,0x3c000000
        .set x_IO_MEM_SZ,0x00002000
	.set x_IO_ADDR_RANGE,0x00000020

	.set x_SDRAM_BASE_ADDR,0x04000000
	.set x_SDRAM_MEM_SZ,0x02000000
	
	.set HW_counter_addr,(x_IO_BASE_ADDR +  5 * x_IO_ADDR_RANGE)
	.set HW_FPU_addr,    (x_IO_BASE_ADDR +  6 * x_IO_ADDR_RANGE)
	.set HW_uart_addr,   (x_IO_BASE_ADDR +  7 * x_IO_ADDR_RANGE)
	.set HW_dsp7seg_addr,(x_IO_BASE_ADDR +  9 * x_IO_ADDR_RANGE)
	.set HW_keybd_addr,  (x_IO_BASE_ADDR + 10 * x_IO_ADDR_RANGE)
	.set HW_lcd_addr,    (x_IO_BASE_ADDR + 11 * x_IO_ADDR_RANGE)
	.set HW_sdc_addr,    (x_IO_BASE_ADDR + 12 * x_IO_ADDR_RANGE)
	.set HW_dma_addr,    (x_IO_BASE_ADDR + 13 * x_IO_ADDR_RANGE)

	# see vhdl/packageMemory.vhd for addresses
	.set x_EXCEPTION_0000,0x00000130
	.set x_EXCEPTION_0100,0x00000200
	.set x_EXCEPTION_0180,0x00000280
	.set x_EXCEPTION_0200,0x00000400
	.set x_EXCEPTION_BFC0,0x000004E0
	.set x_ENTRY_POINT,   0x00000500


	.set c0_index,   $0
	.set c0_random,  $1
	.set c0_entrylo0,$2
	.set c0_entrylo1,$3
	.set c0_context ,$4
	.set c0_pagemask,$5
	.set c0_wired,   $6
	.set c0_badvaddr,$8
	.set c0_count   ,$9
	.set c0_entryhi ,$10
	.set c0_compare ,$11
	.set c0_status  ,$12
	.set c0_cause   ,$13
	.set c0_epc,     $14
	.set c0_config,  $16
	.set c0_config_f0,0
	.set c0_config_f1,1
	.set c0_lladdr,  $17
	.set c0_errorpc, $30

	
	# reset: COP0 present, at exception level, all else disabled
	.set c0_status_reset,0x10000002
	
	# normal state: COP0 present, user mode, all IRQs enabled
	.set c0_status_normal,0x1000ff11

	# user mode, enable all interrupts, EXL=0, user_mode
        .set M_StatusIEn, 0xff11

	# interrupt mask keep bits 15..8 -> STATUS.IM = CAUSE.IP
	.set M_CauseIM,0xff00
	
	# reset: COUNTER stopped, use special interrVector, no interrupts
	.set c0_cause_reset, 0x0880007c

