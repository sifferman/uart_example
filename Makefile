
TOP := uart_mul_tb

export ALEXFORENCICH_UART_DIR := $(abspath third_party/alexforencich_uart)
export BASEJUMP_STL_DIR := $(abspath third_party/basejump_stl)
export YOSYS_DATDIR := $(shell yosys-config --datdir)

RTL := $(shell \
 ALEXFORENCICH_UART_DIR=$(ALEXFORENCICH_UART_DIR) \
 BASEJUMP_STL_DIR=$(BASEJUMP_STL_DIR) \
 python3 misc/convert_filelist.py Makefile rtl/rtl.f \
)

SV2V_ARGS := $(shell \
 ALEXFORENCICH_UART_DIR=$(ALEXFORENCICH_UART_DIR) \
 BASEJUMP_STL_DIR=$(BASEJUMP_STL_DIR) \
 python3 misc/convert_filelist.py sv2v rtl/rtl.f \
)

.PHONY: lint sim gls icestorm_icebreaker_gls icestorm_icebreaker_program icestorm_icebreaker_flash clean

lint:
	verilator lint/verilator.vlt -f rtl/rtl.f -f dv/dv.f --lint-only --top uart_mul

sim:
	verilator lint/verilator.vlt --Mdir ${TOP}_$@_dir -f rtl/rtl.f -f dv/pre_synth.f -f dv/dv.f --binary -Wno-fatal --top ${TOP}
	./${TOP}_$@_dir/V${TOP} +verilator+rand+reset+2

synth/build/rtl.sv2v.v: ${RTL} rtl/rtl.f
	mkdir -p $(dir $@)
	sv2v ${SV2V_ARGS} -w $@ -DSYNTHESIS

synth/yosys_generic/build/synth.v: synth/build/rtl.sv2v.v synth/yosys_generic/yosys.tcl
	mkdir -p $(dir $@)
	yosys -p 'tcl synth/yosys_generic/yosys.tcl synth/build/rtl.sv2v.v' -l synth/yosys_generic/build/yosys.log

icestorm_icebreaker_gls: synth/icestorm_icebreaker/build/synth.v
	verilator lint/verilator.vlt --Mdir ${TOP}_$@_dir -f synth/icestorm_icebreaker/gls.f -f dv/dv.f --binary -Wno-fatal --top ${TOP}
	./${TOP}_$@_dir/V${TOP} +verilator+rand+reset+2

synth/icestorm_icebreaker/build/synth.v synth/icestorm_icebreaker/build/synth.json: synth/build/rtl.sv2v.v synth/icestorm_icebreaker/icebreaker.v synth/icestorm_icebreaker/yosys.tcl
	mkdir -p $(dir $@)
	yosys -p 'tcl synth/icestorm_icebreaker/yosys.tcl' -l synth/icestorm_icebreaker/build/yosys.log

synth/icestorm_icebreaker/build/icebreaker.asc: synth/icestorm_icebreaker/build/synth.json synth/icestorm_icebreaker/nextpnr.py synth/icestorm_icebreaker/nextpnr.pcf
	nextpnr-ice40 \
	 --json synth/icestorm_icebreaker/build/synth.json \
	 --up5k \
	 --package sg48 \
	 --pre-pack synth/icestorm_icebreaker/nextpnr.py \
	 --pcf synth/icestorm_icebreaker/netpnr.pcf \
	 --asc $@

%.bit: %.asc
	icepack $< $@

icestorm_icebreaker_program: synth/icestorm_icebreaker/build/icebreaker.bit
	sudo $(shell which openFPGALoader) -b ice40_generic $<

icestorm_icebreaker_flash: synth/icestorm_icebreaker/build/icebreaker.bit
	sudo $(shell which openFPGALoader) -f -b ice40_generic $<

clean:
	rm -rf \
	 *sim_dir *gls_dir \
	 dump.vcd dump.fst \
	 synth/build \
	 synth/icestorm_icebreaker/build
