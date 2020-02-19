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

module test (
	// control
	input clock,
	input reset_d,

	// memory interface
	output reg        mem_valid_q,
	input             mem_ready_d,
	output reg        mem_insn_q,
	output reg [31:0] mem_addr_q,
	input      [31:0] mem_rdata_d,
	output reg [31:0] mem_wdata_q,
	output reg [ 3:0] mem_wstrb_q
);
	reg         reset_q;
	wire        mem_valid_d;
	reg         mem_ready_q;
	wire        mem_insn_d;
	wire [31:0] mem_addr_d;
	reg  [31:0] mem_rdata_q;
	wire [31:0] mem_wdata_d;
	wire [ 3:0] mem_wstrb_d;

	always @(posedge clock) begin
		reset_q     <= reset_d;
		mem_valid_q <= mem_valid_d;
		mem_ready_q <= mem_ready_d;
		mem_insn_q  <= mem_insn_d;
		mem_addr_q  <= mem_addr_d;
		mem_rdata_q <= mem_rdata_d;
		mem_wdata_q <= mem_wdata_d;
		mem_wstrb_q <= mem_wstrb_d;
	end

	picorv_core #(
		.CPI(2),
		.CSRS(0),
		.XLEN(32),
		.ILEN(32),
		.IALIGN(32),
		.RPORTS(3)
	) cpu (
		.clock          (clock         ),
		.reset          (reset_q       ),
		.rvec           (32'h 0        ),
		.mem_valid      (mem_valid_d   ),
		.mem_ready      (mem_ready_q   ),
		.mem_insn       (mem_insn_d    ),
		.mem_addr       (mem_addr_d    ),
		.mem_rdata      (mem_rdata_q   ),
		.mem_wdata      (mem_wdata_d   ),
		.mem_wstrb      (mem_wstrb_d   ),
		.decode_valid   (              ),
		.decode_insn    (              ),
		.decode_prefix  (              ),
		.pcpi_valid     (              ),
		.pcpi_insn      (              ),
		.pcpi_prefix    (              ),
		.pcpi_pc        (              ),
		.pcpi_rs1_valid (              ),
		.pcpi_rs1_data  (              ),
		.pcpi_rs2_valid (              ),
		.pcpi_rs2_data  (              ),
		.pcpi_rs3_valid (              ),
		.pcpi_rs3_data  (              ),
		.pcpi_ready     ( 1'b 0        ),
		.pcpi_wb_valid  (              ),
		.pcpi_wb_async  ( 1'b 0        ),
		.pcpi_wb_write  ( 1'b 0        ),
		.pcpi_wb_data   (32'b 0        ),
		.pcpi_br_enable ( 1'b 0        ),
		.pcpi_br_nextpc (32'b 0        ),
		.awb_valid      ( 1'b 0        ),
		.awb_ready      (              ),
		.awb_addr       ( 1'b 0        ),
		.awb_data       (32'b 0        )
	);
endmodule
