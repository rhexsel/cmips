## Generated SDC file "tb_cMIPS.out.sdc"

## Copyright (C) 1991-2013 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 13.1.0 Build 162 10/23/2013 SJ Web Edition"

## DATE    "Sat Aug 16 21:02:22 2014"

##
## DEVICE  "EP4CE30F23C7"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 2



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clock_50mhz} -period 20.00 -waveform { 0.00 10.00 } [get_ports {clock_50mhz}]

# create_clock -name clock_50mhz_virt -period 20.00

#**************************************************************
# Create Generated Clock
#**************************************************************

derive_pll_clocks -create_base_clocks

#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

derive_clock_uncertainty

#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -clock clock_50mhz -max 3 [all_inputs]
set_input_delay -clock clock_50mhz -min 1 [all_inputs]

#**************************************************************
# Set Output Delay
#**************************************************************

# set_output_delay -clock clock_50mhz 3 [all_outputs]

#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

#set_false_path -from * -to [get_ports {LEDM_C* LEDM_R* LED_B LED_G LED_R}]
#set_false_path -from [get_ports {KEY* SW*}] -to *
#set_false_path -from * -to [get_ports {LCD_BACKLIGHT LCD_D* LCD_EN LCD_RS LCD_RW UART_TXD}]

set_false_path -from * -to [get_ports {led_b led_g led_r}]
set_false_path -from [get_ports {key* sw*}] -to *

set_false_path -from * -to [get_ports {disp1* disp0*}]

set_false_path -from * -to [get_ports {lcd_*}]
set_false_path -from [get_ports {lcd_*}] -to *

set_false_path -from * -to [get_ports {uart_*}]
set_false_path -from [get_ports {uart_*}] -to *

set_false_path -from * -to [get_ports {sd_*}]
set_false_path -from [get_ports {sd_*}] -to *

# set_false_path -from [get_ports {reset_n}] -to [all_registers]

# set_false_path -from [get_ports {clock_50mhz}] -to *

#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

