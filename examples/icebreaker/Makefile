PCF = icebreaker.pcf
VLOG = top.v ../../picorv.v spimemio.v simpleuart.v
SIMLIB = $(shell yosys-config --datdir)/ice40/cells_sim.v
SHELL = bash

test: testbench boot.hex firmware.hex
	vvp -N testbench

testbench: testbench.v spiflash.v $(VLOG) $(SIMLIB)
	iverilog -DPICORV_DEBUG -s testbench -o testbench testbench.v spiflash.v $(VLOG) $(SIMLIB)

prog: design.bin firmware.bin
	iceprog design.bin
	iceprog -o 1M firmware.bin

prog_fw: firmware.bin
	iceprog -o 1M firmware.bin

boot.hex: boot.elf
	riscv32-unknown-elf-objcopy -O verilog boot.elf /dev/stdout | sed -r 's,(..) (..) (..) (..),\4\3\2\1,g' > boot.hex

boot_tpl.hex:
	icebram -g 32 256 > boot_tpl.hex

boot.elf: boot.s
	riscv32-unknown-elf-as -o boot.elf boot.s

firmware.bin: firmware.hex
firmware.hex: firmware.elf firmware.py
	riscv32-unknown-elf-objcopy -O verilog firmware.elf /dev/stdout | \
	python3 firmware.py `riscv32-unknown-elf-nm firmware.elf | grep ' T _start$$' | cut -f1 -d' '`

firmware.elf: firmware.c syscalls.c
	riscv32-unknown-elf-gcc -o firmware.elf firmware.c syscalls.c

design.json: $(VLOG) boot_tpl.hex
	yosys -l design_ys.log -p 'synth_ice40 -top top -json $@' $(VLOG)

design_tpl.asc: design.json $(PCF)
	nextpnr-ice40 -l design_pnr.log --up5k --package sg48 --asc design_tpl.asc --pcf $(PCF) --json design.json --placer heap

design.asc: design_tpl.asc boot_tpl.hex boot.hex
	icebram boot_tpl.hex <( egrep -v '^@0+\s$$' boot.hex; ) < design_tpl.asc > design.asc

design.bin: design.asc
	icepack design.asc design.bin

clean:
	rm -f testbench testbench.vcd
	rm -f firmware.elf firmware.hex
	rm -f boot.hex boot.elf firmware.bin
	rm -f design.json design.asc design.bin
	rm -f design_ys.log design_pnr.log
	rm -f boot_tpl.hex design_tpl.asc
