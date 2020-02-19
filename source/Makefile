
PICORV_V = picorv_common.v picorv_core.v picorv_ctrl.v picorv_exec.v picorv_ldst.v

test: testbench firmware.hex
	vvp -N testbench +vcd

firmware.hex: firmware.elf
	riscv32-unknown-elf-objcopy -O verilog firmware.elf firmware.hex

testbench: testbench.v $(PICORV_V) firmware.elf
	iverilog -DPICORV_DEBUG -DSTART="32'h`riscv32-unknown-elf-nm firmware.elf | grep ' T _start$$' | cut -f1 -d' '`" -o $@ \
		-D'HEXFILE="firmware.hex"' -s testbench testbench.v $(PICORV_V)

firmware.elf: firmware.S firmware.c
	riscv32-unknown-elf-gcc -march=rv32ic -Os -Wall -Wextra -o firmware.elf firmware.S firmware.c -ffreestanding -nostdlib

picorv_core.v: picorv_core.py
	python3 picorv_core.py > picorv_core.v

test.json: test.v $(PICORV_V)
	yosys -v2 -l test_yosys.log -p 'synth_ice40 -retime -json test.json -top test' test.v $(PICORV_V)

test.asc: test.json
	nextpnr-ice40 -l test_nextpnr.log --hx8k --package ct256 --pcf-allow-unconstrained \
		--freq 50 --json test.json --placer heap --asc test.asc

vivado: test.v $(PICORV_V)
	rm -rf .Xil test_vivado.log
	vivado -mode batch -source test.tcl -nojournal -log test_vivado.log

dhry: dhry.vvp dhry.hex
	vvp -N dhry.vvp +vcd +fast

dhry.hex: dhry.elf
	riscv32-unknown-elf-objcopy -O verilog dhry.elf dhry.hex

dhry.vvp: testbench.v $(PICORV_V) dhry.elf
	iverilog -DPICORV_DEBUG -DSTART="32'h`riscv32-unknown-elf-nm dhry.elf | grep ' T _start$$' | cut -f1 -d' '`" -o $@ \
		-D'HEXFILE="dhry.hex"' -s testbench testbench.v $(PICORV_V)

dhry.elf: dhry_1.o dhry_2.o syscalls.o
	riscv32-unknown-elf-gcc -march=rv32ic -o dhry.elf dhry_1.o dhry_2.o syscalls.o

dhry_1.o: dhry_1.c dhry.h
	riscv32-unknown-elf-gcc -march=rv32ic -DRISCV -O3 -c -o dhry_1.o dhry_1.c -Wno-implicit-int -Wno-implicit-function-declaration

dhry_2.o: dhry_2.c dhry.h
	riscv32-unknown-elf-gcc -march=rv32ic -DRISCV -O3 -c -o dhry_2.o dhry_2.c -Wno-implicit-int -Wno-implicit-function-declaration

syscalls.o: syscalls.c
	riscv32-unknown-elf-gcc -march=rv32ic -DRISCV -O3 -c -o syscalls.o syscalls.c

disasm:
	riscv32-unknown-elf-objdump -M numeric,no-aliases -s -d firmware.elf

generate: $(PICORV_V)
	echo "// --------------------------------------------------------------------" > ../picorv.v.new
	echo "// GENERATED WITH 'make -C source generate' IN PICORV SOURCE REPOSITORY" >> ../picorv.v.new
	echo "// --------------------------------------------------------------------" >> ../picorv.v.new
	for f in $(PICORV_V); do echo; echo "// ---- $$f ----"; cat $$f; done >> ../picorv.v.new
	mv ../picorv.v.new ../picorv.v

clean:
	rm -rf picorv_core.v testbench firmware.hex firmware.elf testbench.vcd
	rm -rf test.json test.asc test_yosys.log test_nextpnr.log
	rm -rf dhry.elf dhry.hex dhry.vvp dhry_1.o dhry_2.o syscalls.o
	rm -rf .Xil test_vivado.log
