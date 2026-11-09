# ------------------------------------------------------------------
# sim.do : compile, simulate and display power_compute in ModelSim
#
# Usage (ModelSim transcript, from this sim/modelsim directory):
#     do sim.do            -> fast testbench  (N = 256, 10 MHz clock, ~0.22 ms)
#     do sim.do a1         -> lab testbench   (N = 1024, 50 Hz sine,   9.5 s)
# ------------------------------------------------------------------

# testbench architecture : "fast" (default) or "a1"
if {$argc >= 1} { set TB_ARCH $1 } else { set TB_ARCH fast }

# close a previous simulation if one is running
quit -sim

# --- library and compilation --------------------------------------
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

set RTL ../../rtl
set TBD ../../tb

vcom -93 -work work $RTL/power_compute_e.vhd
vcom -93 -work work $RTL/power_compute_a1.vhd
vcom -93 -work work $TBD/test_power_compute_e.vhd
vcom -93 -work work $TBD/test_power_compute_a1.vhd
vcom -93 -work work $TBD/test_power_compute_fast.vhd

# --- timing of the chosen testbench (used by wave.do) -------------
if {$TB_ARCH eq "a1"} {
    set TCLK_US  976.5625         ;# 1000 ms / 1024
    set TCALC_US 1000000.0        ;# 1024 samples = 1 s
    set UNIT     ms
} else {
    set TCLK_US  0.1              ;# 10 MHz
    set TCALC_US 25.6             ;# 256 samples
    set UNIT     us
}

# --- load the testbench -------------------------------------------
vsim -t ps "work.test_power_compute($TB_ARCH)"

# --- windows ------------------------------------------------------
view structure
view objects
view transcript
view wave

# --- waveforms, run -----------------------------------------------
do wave.do
run -all
wave zoom full
