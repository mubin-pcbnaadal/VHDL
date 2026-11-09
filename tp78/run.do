# ModelSim script - TP 7&8 Gray counter
# Usage (ModelSim Transcript window, after "cd" into the folder with the .vhd files):
#     do run.do
# To test another architecture, edit line 44 of test_gray_a1.vhd:
#     c2 : entity work.gray_counter(a1)   ->  a2 / a3 / a4 / a5
# then type "do run.do" again.

quit -sim
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

# ---- compile (order matters) ----
vcom -2008 myfuncs_package.vhd
vcom -2008 myfuncs_body.vhd
vcom -2008 gray_counter_e.vhd
vcom -2008 gray_counter_a1.vhd
vcom -2008 gray_counter_a2.vhd
vcom -2008 gray_counter_a3.vhd
vcom -2008 gray_counter_a4.vhd
vcom -2008 gray_counter_a5.vhd
vcom -2008 digital_gene_e.vhd
vcom -2008 digital_gene_a1.vhd
vcom -2008 test_gray_e.vhd
vcom -2008 test_gray_a1.vhd

# ---- simulate ----
vsim -voptargs=+acc work.test_gray

add wave -divider "Stimuli"
add wave           /test_gray/reset
add wave           /test_gray/enable
add wave           /test_gray/clk
add wave           /test_gray/clk2
add wave -radix unsigned /test_gray/factor
add wave -divider "Inside the counter"
add wave -radix binary   /test_gray/c2/g
add wave                 /test_gray/c2/gs
add wave -divider "Outputs"
add wave -radix binary   /test_gray/count_out
add wave -radix unsigned /test_gray/count_out
add wave                 /test_gray/clock_out

run 60 us
wave zoom full
