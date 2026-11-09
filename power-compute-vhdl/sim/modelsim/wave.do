# ------------------------------------------------------------------
# wave.do : clean Wave window layout for power_compute
# Called by sim.do. Can also be run alone once a simulation is loaded:
#     do wave.do
# ------------------------------------------------------------------

# defaults if run alone (fast testbench timing)
if {![info exists TCLK_US]}  { set TCLK_US  0.1 }
if {![info exists TCALC_US]} { set TCALC_US 25.6 }
if {![info exists UNIT]}     { set UNIT us }

view wave
delete wave *

# --- window settings ----------------------------------------------
configure wave -signalnamewidth 1
configure wave -namecolwidth 170
configure wave -valuecolwidth 110
configure wave -timelineunits $UNIT
configure wave -justifyvalue right

set TB /test_power_compute
set U  /test_power_compute/c1

# --- 1. inputs / outputs ------------------------------------------
add wave -noupdate -divider -height 25 "INPUTS / OUTPUTS"
add wave -noupdate -label reset -color Red     $TB/reset
add wave -noupdate -label clock -color Gray60  $TB/clock
add wave -noupdate -label C     -color Orange  $TB/C
add wave -noupdate -label amplitude -color White $TB/amp
add wave -noupdate -label "X (sine)" -color Cyan -radix decimal \
         -format analog-step -height 150 -min -32768 -max 32767 $TB/X
add wave -noupdate -label "P (curve)" -color Yellow -radix unsigned \
         -format analog-step -height 150 -min 0 -max 540000000 $TB/P
add wave -noupdate -label "P (value)" -color Yellow -radix unsigned $TB/P

# --- 2. state machine ---------------------------------------------
add wave -noupdate -divider -height 25 "STATE MACHINE"
add wave -noupdate -group FSM -label state      -color Magenta $U/state
add wave -noupdate -group FSM -label next_state -color Plum    $U/next_state
add wave -noupdate -group FSM -label end_cnt    -color Red     $U/end_cnt
add wave -noupdate -group FSM -label clr_cnt    -color Green   $U/clr_cnt
add wave -noupdate -group FSM -label inc_cnt    -color Green   $U/inc_cnt
add wave -noupdate -group FSM -label init       -color Green   $U/init
add wave -noupdate -group FSM -label ld_acc     -color Green   $U/ld_acc
add wave -noupdate -group FSM -label ld_p       -color Green   $U/ld_p

# --- 3. data path -------------------------------------------------
add wave -noupdate -divider -height 25 "DATA PATH"
add wave -noupdate -group Datapath -label cnt   -radix unsigned -color "Light Blue" $U/cnt
add wave -noupdate -group Datapath -label "x^2" -radix unsigned -color White  $U/sq
add wave -noupdate -group Datapath -label opa   -radix unsigned -color White  $U/opa
add wave -noupdate -group Datapath -label sum   -radix unsigned -color White  $U/sum
add wave -noupdate -group Datapath -label "ACC (curve)" -radix unsigned -color Orange \
         -format analog-step -height 80 -min 0 -max 549755813888 $U/acc
add wave -noupdate -group Datapath -label p_reg -radix unsigned -color Yellow $U/p_reg

# --- bookmarks (Wave window > Bookmarks menu) ---------------------
proc zoomrange {t0 t1} { return [list "$t0 us" "$t1 us"] }
set c $TCLK_US
set T $TCALC_US
bookmark add wave "End of computation 0" [zoomrange [expr {$T - 5*$c}]   [expr {$T + 5*$c}]]   0
bookmark add wave "C=0 : standby"        [zoomrange [expr {4*$T - 5*$c}] [expr {4*$T + 5*$c}]] 0
bookmark add wave "Restart (C=1)"        [zoomrange [expr {5*$T - 2*$c}] [expr {5*$T + 8*$c}]] 0

update
