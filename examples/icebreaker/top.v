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

module top (
	input CLK,

	// LEDs
	output LED1,
	output LED2,
	output LED3,
	output LED4,
	output LED5,
	output LEDR_N,
	output LEDG_N,

	// Buttons
	input BTN1,
	input BTN2,
	input BTN3,
	input BTN_N,

	// PMOD 1A
	inout P1A1,
	inout P1A2,
	inout P1A3,
	inout P1A4,
	inout P1A7,
	inout P1A8,
	inout P1A9,
	inout P1A10,

	// PMOD 1B
	inout P1B1,
	inout P1B2,
	inout P1B3,
	inout P1B4,
	inout P1B7,
	inout P1B8,
	inout P1B9,
	inout P1B10,

	// FLASH
	output FLASH_SSB,
	output FLASH_SCK,
	inout  FLASH_IO0,
	inout  FLASH_IO1,
	inout  FLASH_IO2,
	inout  FLASH_IO3,

	// RS232
	input  RX,
	output TX
);
	// CLOCK AND RESET
	// ---------------

	wire clock = CLK;

	reg reset = 1;
	reg [4:0] reset_cnt = 0;

	always @(posedge clock) begin
		reset <= reset_cnt != 31;
		reset_cnt <= reset_cnt + (reset_cnt != 31);
	end


	// IOs
	// ---

	reg [6:0] leds;
	assign {LEDR_N, LEDG_N, LED5, LED4, LED3, LED2, LED1} = leds;

	wire flash_csb;
	wire flash_clk;

	wire flash_io0_oe, flash_io0_do, flash_io0_di;
	wire flash_io1_oe, flash_io1_do, flash_io1_di;
	wire flash_io2_oe, flash_io2_do, flash_io2_di;
	wire flash_io3_oe, flash_io3_do, flash_io3_di;

	reg [7:0] pmod1_oe, pmod1_do, pmod2_oe, pmod2_do;
	wire [7:0] pmod1_di, pmod2_di;

	assign FLASH_SSB = flash_csb;
	assign FLASH_SCK = flash_clk;

	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) flash_io_buf [3:0] (
		.PACKAGE_PIN({FLASH_IO3, FLASH_IO2, FLASH_IO1, FLASH_IO0}),
		.OUTPUT_ENABLE({flash_io3_oe, flash_io2_oe, flash_io1_oe, flash_io0_oe}),
		.D_OUT_0({flash_io3_do, flash_io2_do, flash_io1_do, flash_io0_do}),
		.D_IN_0({flash_io3_di, flash_io2_di, flash_io1_di, flash_io0_di})
	);

	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) pmod1_io_buf [7:0] (
		.PACKAGE_PIN({P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1}),
		.OUTPUT_ENABLE(pmod1_oe),
		.D_OUT_0(pmod1_do),
		.D_IN_0(pmod1_di)
	);

	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) pmod2_io_buf [7:0] (
		.PACKAGE_PIN({P1B10, P1B9, P1B8, P1B7, P1B4, P1B3, P1B2, P1B1}),
		.OUTPUT_ENABLE(pmod2_oe),
		.D_OUT_0(pmod2_do),
		.D_IN_0(pmod2_di)
	);


	// SYSTEM
	// ------

	wire        mem_valid;
	reg         mem_ready;
	wire        mem_insn;
	wire [31:0] mem_addr;
	wire [31:0] mem_rdata;
	wire [31:0] mem_wdata;
	wire [ 3:0] mem_wstrb;

	reg [31:0] mem_rdata_zpage_data;
	reg        mem_rdata_zpage_valid;

	reg [31:0] mem_rdata_regs_data;
	reg        mem_rdata_regs_valid;

	wire [31:0] mem_rdata_spram1_data;
	reg         mem_rdata_spram1_valid;

	wire [31:0] mem_rdata_spram2_data;
	reg         mem_rdata_spram2_valid;

	reg [31:0] zpage [0:255];

	initial begin
`ifdef PICORV_DEBUG
		$readmemh("boot.hex", zpage);
`else
		$readmemh("boot_tpl.hex", zpage);
`endif
	end

	// 0x00000000 - 0x000003ff
	wire zpage_valid = mem_valid && mem_addr[31:10] == 0;

	// 0x00000400 - 0x000007ff
	wire regs_valid       = mem_valid && mem_addr[31:10] == 1;
	wire ledreg_valid     = mem_valid && mem_addr == 32'h 00000400;
	wire spireg_valid     = mem_valid && mem_addr == 32'h 00000404;
	wire pmodareg_valid   = mem_valid && mem_addr == 32'h 00000408;
	wire pmodbreg_valid   = mem_valid && mem_addr == 32'h 0000040C;
	wire uartdivreg_valid = mem_valid && mem_addr == 32'h 00000410;
	wire uartdatreg_valid = mem_valid && mem_addr == 32'h 00000414;

	// 0x00010000 - 0x0002ffff
	wire spram1_valid = mem_valid && mem_addr[31:16] == 1;
	wire spram2_valid = mem_valid && mem_addr[31:16] == 2;

	// 0x01000000 - 0x01f1ffff
	wire spi_valid = mem_valid && mem_addr[31:24] == 1;

	wire spi_ready;
	wire [31:0] spi_rdata;
	wire [31:0] spireg_do;

	wire [31:0] uartdivreg_do;
	wire [31:0] uartdatreg_do;
	wire uartdatreg_wait;

	always @(posedge clock) begin
		mem_ready <= 0;
		mem_rdata_zpage_data <= 'bx;
		mem_rdata_zpage_valid <= 0;
		mem_rdata_regs_data <= 'bx;
		mem_rdata_regs_valid <= 0;
		mem_rdata_spram1_valid <= 0;
		mem_rdata_spram2_valid <= 0;

		(* parallel_case *)
		case (1)
			zpage_valid: begin
				mem_ready <= 1;
				mem_rdata_zpage_data <= zpage[mem_addr[9:2]];
				mem_rdata_zpage_valid <= 1;
				if (mem_wstrb[0]) zpage[mem_addr[9:2]][ 7: 0] <= mem_wdata[ 7: 0];
				if (mem_wstrb[1]) zpage[mem_addr[9:2]][15: 8] <= mem_wdata[15: 8];
				if (mem_wstrb[2]) zpage[mem_addr[9:2]][23:16] <= mem_wdata[23:16];
				if (mem_wstrb[3]) zpage[mem_addr[9:2]][31:24] <= mem_wdata[31:24];
			end
			regs_valid: begin
				mem_ready <= 1;
				mem_rdata_regs_valid <= 1;
				(* parallel_case *)
				case (1)
					ledreg_valid: begin
						if (mem_wstrb[0]) leds <= mem_wdata;
						mem_rdata_regs_data <= {BTN_N, BTN3, BTN2, BTN1, 1'b0, leds};
					end
					pmodareg_valid: begin
						if (mem_wstrb[1]) pmod1_do <= mem_wdata[15:8];
						if (mem_wstrb[2]) pmod1_oe <= mem_wdata[23:16];
						mem_rdata_regs_data <= {pmod1_oe, pmod1_do, pmod1_di};
					end
					pmodbreg_valid: begin
						if (mem_wstrb[1]) pmod2_do <= mem_wdata[15:8];
						if (mem_wstrb[2]) pmod2_oe <= mem_wdata[23:16];
						mem_rdata_regs_data <= {pmod2_oe, pmod2_do, pmod2_di};
					end
					spireg_valid: begin
						mem_rdata_regs_data <= spireg_do;
					end
					uartdivreg_valid: begin
						mem_rdata_regs_data <= uartdivreg_do;
					end
					uartdatreg_valid: begin
						if (uartdatreg_wait)
							mem_ready <= 0;
						mem_rdata_regs_data <= uartdatreg_do;
					end
				endcase
			end
			spram1_valid: begin
				mem_ready <= 1;
				mem_rdata_spram1_valid <= 1;
			end
			spram2_valid: begin
				mem_ready <= 1;
				mem_rdata_spram2_valid <= 1;
			end
			spi_valid: begin
				mem_ready <= spi_ready;
				mem_rdata_regs_data <= spi_rdata;
				mem_rdata_regs_valid <= 1;
			end
		endcase

		if (mem_ready || reset) begin
			mem_ready <= 0;
		end
	end

        SB_SPRAM256KA spram1_lo (
                .ADDRESS(mem_addr[15:2]),
                .DATAIN(mem_wdata[15:0]),
                .MASKWREN({{2{spram1_valid && mem_wstrb[1]}}, {2{spram1_valid && mem_wstrb[0]}}}),
                .WREN(spram1_valid && mem_wstrb),
                .CHIPSELECT(1'b1),
                .CLOCK(clock),
                .STANDBY(1'b0),
                .SLEEP(1'b0),
                .POWEROFF(1'b1),
                .DATAOUT(mem_rdata_spram1_data[15:0])
        );

        SB_SPRAM256KA spram1_hi (
                .ADDRESS(mem_addr[15:2]),
                .DATAIN(mem_wdata[31:16]),
                .MASKWREN({{2{spram1_valid && mem_wstrb[3]}}, {2{spram1_valid && mem_wstrb[2]}}}),
                .WREN(spram1_valid && mem_wstrb),
                .CHIPSELECT(1'b1),
                .CLOCK(clock),
                .STANDBY(1'b0),
                .SLEEP(1'b0),
                .POWEROFF(1'b1),
                .DATAOUT(mem_rdata_spram1_data[31:16])
        );

        SB_SPRAM256KA spram2_lo (
                .ADDRESS(mem_addr[15:2]),
                .DATAIN(mem_wdata[15:0]),
                .MASKWREN({{2{spram2_valid && mem_wstrb[1]}}, {2{spram2_valid && mem_wstrb[0]}}}),
                .WREN(spram2_valid && mem_wstrb),
                .CHIPSELECT(1'b1),
                .CLOCK(clock),
                .STANDBY(1'b0),
                .SLEEP(1'b0),
                .POWEROFF(1'b1),
                .DATAOUT(mem_rdata_spram2_data[15:0])
        );

        SB_SPRAM256KA spram2_hi (
                .ADDRESS(mem_addr[15:2]),
                .DATAIN(mem_wdata[31:16]),
                .MASKWREN({{2{spram2_valid && mem_wstrb[3]}}, {2{spram2_valid && mem_wstrb[2]}}}),
                .WREN(spram2_valid && mem_wstrb),
                .CHIPSELECT(1'b1),
                .CLOCK(clock),
                .STANDBY(1'b0),
                .SLEEP(1'b0),
                .POWEROFF(1'b1),
                .DATAOUT(mem_rdata_spram2_data[31:16])
        );

	spimemio spi (
		.clk          (clock),
		.resetn       (!reset),

		.valid        (spi_valid),
		.ready        (spi_ready),
		.addr         (mem_addr[23:0]),
		.rdata        (spi_rdata),

		.flash_csb    (flash_csb),
		.flash_clk    (flash_clk),
		.flash_io0_oe (flash_io0_oe),
		.flash_io1_oe (flash_io1_oe),
		.flash_io2_oe (flash_io2_oe),
		.flash_io3_oe (flash_io3_oe),
		.flash_io0_do (flash_io0_do),
		.flash_io1_do (flash_io1_do),
		.flash_io2_do (flash_io2_do),
		.flash_io3_do (flash_io3_do),
		.flash_io0_di (flash_io0_di),
		.flash_io1_di (flash_io1_di),
		.flash_io2_di (flash_io2_di),
		.flash_io3_di (flash_io3_di),

		.cfgreg_we    (spireg_valid ? mem_wstrb : 4'b 0000),
		.cfgreg_di    (mem_wdata),
		.cfgreg_do    (spireg_do)
	);

	simpleuart uart (
		.clk          (clock),
		.resetn       (!reset),

		.ser_tx       (TX),
		.ser_rx       (RX),

		.reg_div_we   (uartdivreg_valid ? mem_wstrb : 4'b 0000),
		.reg_div_di   (mem_wdata),
		.reg_div_do   (uartdivreg_do),

		.reg_dat_we   (uartdatreg_valid ? |mem_wstrb : 1'b 0),
		.reg_dat_re   (uartdatreg_valid && !mem_wstrb),
		.reg_dat_di   (mem_wdata),
		.reg_dat_do   (uartdatreg_do),
		.reg_dat_wait (uartdatreg_wait)
	);

	assign mem_rdata =
		mem_rdata_zpage_valid ? mem_rdata_zpage_data :
		mem_rdata_regs_valid ? mem_rdata_regs_data :
		mem_rdata_spram1_valid ? mem_rdata_spram1_data :
		mem_rdata_spram2_valid ? mem_rdata_spram2_data : 'bx;

	picorv_ez #(
		.CPI(2),
		.XLEN(32)
	) cpu (
		.clock (clock),
		.reset (reset),
		.mem_valid (mem_valid),
		.mem_ready (mem_ready),
		.mem_insn  (mem_insn ),
		.mem_addr  (mem_addr ),
		.mem_rdata (mem_rdata),
		.mem_wdata (mem_wdata),
		.mem_wstrb (mem_wstrb)
	);
endmodule
