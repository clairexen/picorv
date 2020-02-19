/*
 *  PicoRV -- A Small and Extensible RISC-V Processor
 *
 *  Copyright (C) 2019  Claire Wolf <claire@symbioticeda.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`timescale 1 ns / 1 ps

module testbench;
	reg CLK;
	integer i;

	initial begin
		$dumpfile("testbench.vcd");
		$dumpvars(0, testbench);

		#5 CLK = 0;
		for (i = 0; i < 100; i = i+1) begin
			repeat (6000) #5 CLK = ~CLK;
			if (i%10 == 0) begin
				if (i)
					$display();
				$write("Running [%2d%%] ", i);
				$fflush;
			end else begin
				$write(".");
				$fflush;
			end
		end

		$display();
		$display("DONE");
	end

	wire LED1;
	wire LED2;
	wire LED3;
	wire LED4;
	wire LED5;

	wire FLASH_SSB;
	wire FLASH_SCK;
	wire FLASH_IO0;
	wire FLASH_IO1;
	wire FLASH_IO2;
	wire FLASH_IO3;

	spiflash spiflash (
		.csb(FLASH_SSB),
		.clk(FLASH_SCK),
		.io0(FLASH_IO0),
		.io1(FLASH_IO1),
		.io2(FLASH_IO2),
		.io3(FLASH_IO3)
	);

	top uut (
		.CLK (CLK),

		.LED1 (LED1),
		.LED2 (LED2),
		.LED3 (LED3),
		.LED4 (LED4),
		.LED5 (LED5),

		.FLASH_SSB (FLASH_SSB),
		.FLASH_SCK (FLASH_SCK),
		.FLASH_IO0 (FLASH_IO0),
		.FLASH_IO1 (FLASH_IO1),
		.FLASH_IO2 (FLASH_IO2),
		.FLASH_IO3 (FLASH_IO3),

		.RX (RX),
		.TX (TX)
	);
endmodule
