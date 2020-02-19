# PicoRV

Clean rewrite of PicoRV32, with improved flexibility and extensibility, support for RV64, and more.

**Early alpha. Work in progress.**


## Getting Started

```
# Generate picorv.v
make -C source generate

# icebreaker example design
cd examples/icebreaker/

# run simulation
make

# display sim waveform
gtkwave testbench.vcd testbench.gtkw

# run synthesis
make design.bin

# compile firmware
make firmware.bin

# program icebreaker board
make prog
```
