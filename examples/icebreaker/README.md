PicoRV icebreaker demo
======================

A simple demo system based on the [iCEBreaker FPGA development board](https://www.crowdsupply.com/1bitsquared/icebreaker-fpga).

This demo expects the 7-segment module attached to PMOD1A.

```
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
