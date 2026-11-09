# ------------------------------------------------------------------
# GHDL flow (free, open-source VHDL simulator)
#
#   make            compile everything
#   make sim        run the lab testbench   (N = 1024, 9.5 s simulated)
#   make sim-fast   run the fast testbench  (N = 256,  0.22 ms simulated)
#   make waves      fast testbench -> VCD  -> PNG waveforms in docs/img/
#   make golden     bit-exact Python reference model of the fast testbench
#   make clean
# ------------------------------------------------------------------

GHDL  ?= ghdl
FLAGS  = --std=93 --workdir=build
SRC    = rtl/power_compute_e.vhd rtl/power_compute_a1.vhd \
         tb/test_power_compute_e.vhd tb/test_power_compute_a1.vhd \
         tb/test_power_compute_fast.vhd

.PHONY: all sim sim-fast waves golden clean

all: build/.compiled

build/.compiled: $(SRC)
	mkdir -p build
	$(GHDL) -a $(FLAGS) $(SRC)
	$(GHDL) -e $(FLAGS) test_power_compute a1
	$(GHDL) -e $(FLAGS) test_power_compute fast
	touch $@

sim: all
	$(GHDL) -r $(FLAGS) test_power_compute a1 --wave=build/tb_a1.ghw

sim-fast: all
	$(GHDL) -r $(FLAGS) test_power_compute fast --wave=build/tb_fast.ghw

waves: all
	$(GHDL) -r $(FLAGS) test_power_compute fast --vcd=build/tb_fast.vcd
	python3 scripts/plot_waves.py build/tb_fast.vcd docs/img

golden:
	python3 scripts/golden_model.py

clean:
	rm -rf build *.o *.cf test_power_compute
