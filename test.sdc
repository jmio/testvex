# This file is generated by Anlogic Timing Wizard. 21 02 2021

#Created Clock
create_clock -name clk24m -period 42 -waveform {0 21} 

#Derive PLL Clocks
derive_pll_clocks -gen_basic_clock

