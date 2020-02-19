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

module testbench;
	localparam integer XLEN = 32;
	localparam integer ILEN = 32;
	localparam integer IALIGN = 16;

	reg                  clock;
	reg                  reset = 1;
	wire [XLEN-1:0]      rvec = `START;

	wire                 mem_valid;
	reg                  mem_ready;
	wire                 mem_insn;
	wire [XLEN-1:0]      mem_addr;
	wire [31:0]          mem_wdata;
	wire [31:0]          mem_rdata;
	wire [ 3:0]          mem_wstrb;

	wire                 pcpi_valid;
	wire [ILEN-1:0]      pcpi_insn;
	wire [    15:0]      pcpi_prefix;
	wire [XLEN-1:0]      pcpi_pc;
	wire                 pcpi_rs1_valid;
	wire [XLEN-1:0]      pcpi_rs1_data;
	wire                 pcpi_rs2_valid;
	wire [XLEN-1:0]      pcpi_rs2_data;
	wire                 pcpi_rs3_valid;
	wire [XLEN-1:0]      pcpi_rs3_data;
	reg                  pcpi_ready = 0;
	reg                  pcpi_wb_write = 0;
	reg                  pcpi_wb_async = 0;
	reg  [XLEN-1:0]      pcpi_wb_data = 0;
	reg                  pcpi_br_enable = 0;
	reg  [XLEN-1:0]      pcpi_br_nextpc = 0;

	reg             awb_valid = 0;
	wire            awb_ready;
	reg  [     4:0] awb_addr;
	reg  [XLEN-1:0] awb_data;

	always #5 clock = clock === 1'b0;
	always @(posedge clock) reset <= 0;

	reg [7:0] memory [0:2**20-1];
	reg fastmode;

	initial begin
		fastmode = $test$plusargs("fast");
		$readmemh(`HEXFILE, memory);
		if ($test$plusargs("vcd")) begin
			$dumpfile("testbench.vcd");
			$dumpvars(0, testbench);
		end
		repeat (1000000) @(posedge clock);
		$display("TIMEOUT");
		$finish;
	end

	integer stallcnt = 0;
	integer termcnt = 0;
	always @(posedge clock) begin
		stallcnt <= mem_valid ? 0 : stallcnt + 1;
		termcnt <= termcnt - |termcnt;
		if (stallcnt > 100) begin
			$display("STALLED");
			$finish;
		end
		if (termcnt == 1) begin
			$display("TERMINATED");
			$finish;
		end
	end

	reg mem_arb;

	always @(posedge clock) begin
		mem_arb <= ($random & 1) || fastmode;
	end

	always @* begin
		mem_ready = mem_valid && mem_arb;
	end

	assign mem_rdata[ 7: 0] = mem_valid && mem_ready ? memory[mem_addr + 2'd 0] : 'bx;
	assign mem_rdata[15: 8] = mem_valid && mem_ready ? memory[mem_addr + 2'd 1] : 'bx;
	assign mem_rdata[23:16] = mem_valid && mem_ready ? memory[mem_addr + 2'd 2] : 'bx;
	assign mem_rdata[31:24] = mem_valid && mem_ready ? memory[mem_addr + 2'd 3] : 'bx;

	always @(posedge clock) begin
		if (mem_valid && mem_ready && mem_addr < 2**20) begin
			// if (mem_wstrb) begin
			// 	$display("[W:%b:%08x:%08x]", mem_wstrb, mem_addr, mem_wdata);
			// 	if (mem_wstrb != 4'b0001 && mem_wstrb != 4'b0010 && mem_wstrb != 4'b0100 && mem_wstrb != 4'b1000 &&
			// 			mem_wstrb != 4'b0011 && mem_wstrb != 4'b1100 && mem_wstrb != 4'b1111)
			// 		termcnt = termcnt ? termcnt : 10;
			// end
			if (mem_wstrb[0]) memory[mem_addr + 2'd 0] <= mem_wdata[ 7: 0];
			if (mem_wstrb[1]) memory[mem_addr + 2'd 1] <= mem_wdata[15: 8];
			if (mem_wstrb[2]) memory[mem_addr + 2'd 2] <= mem_wdata[23:16];
			if (mem_wstrb[3]) memory[mem_addr + 2'd 3] <= mem_wdata[31:24];
		end
		if (mem_valid && mem_ready && mem_addr == 2**20) begin
			if (mem_wdata[7:0]) begin
				$write("%c", mem_wdata[7:0]);
				$fflush;
			end else begin
				$display("EOF");
				$finish;
			end
		end
	end

	picorv_core #(
		.XLEN(XLEN),
		.ILEN(ILEN),
		.IALIGN(IALIGN),
		.SPINIT(2**20-16),
		.CPI(1)
	) uut (
		.clock          (clock          ),
		.reset          (reset          ),
		.rvec           (rvec           ),

		.mem_valid      (mem_valid      ),
		.mem_ready      (mem_ready      ),
		.mem_insn       (mem_insn       ),
		.mem_addr       (mem_addr       ),
		.mem_rdata      (mem_rdata      ),
		.mem_wdata      (mem_wdata      ),
		.mem_wstrb      (mem_wstrb      ),

		.pcpi_valid     (pcpi_valid     ),
		.pcpi_insn      (pcpi_insn      ),
		.pcpi_prefix    (pcpi_prefix    ),
		.pcpi_pc        (pcpi_pc        ),
		.pcpi_rs1_valid (pcpi_rs1_valid ),
		.pcpi_rs1_data  (pcpi_rs1_data  ),
		.pcpi_rs2_valid (pcpi_rs2_valid ),
		.pcpi_rs2_data  (pcpi_rs2_data  ),
		.pcpi_rs3_valid (pcpi_rs3_valid ),
		.pcpi_rs3_data  (pcpi_rs3_data  ),
		.pcpi_ready     (pcpi_ready     ),
		.pcpi_wb_write  (pcpi_wb_write  ),
		.pcpi_wb_async  (pcpi_wb_async  ),
		.pcpi_wb_data   (pcpi_wb_data   ),
		.pcpi_br_enable (pcpi_br_enable ),
		.pcpi_br_nextpc (pcpi_br_nextpc ),

		.awb_valid      (awb_valid      ),
		.awb_ready      (awb_ready      ),
		.awb_addr       (awb_addr       ),
		.awb_data       (awb_data       )
	);
endmodule
