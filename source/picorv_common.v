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

module picorv_ez #(
	parameter integer CPI = 1,
	parameter integer XLEN = 32,
	parameter integer ILEN = 32,
	parameter integer IALIGN = 32,
	parameter [0:0] PCPI = 0,
	parameter [0:0] PCPI_RS3 = 0,
	parameter [XLEN-1:0] SPINIT = 1,
	parameter [XLEN-1:0] RST_VECTOR = 0,
	parameter [XLEN-1:0] ISR_VECTOR = 0
) (
	// control
	input            clock,
	input            reset,

	// interrupt control
	input            irq_req,
	output           irq_ack,

	// memory interface
	output            mem_valid,
	input             mem_ready,
	output            mem_insn,
	output [XLEN-1:0] mem_addr,
	input  [    31:0] mem_rdata,
	output [    31:0] mem_wdata,
	output [     3:0] mem_wstrb,

	// pcpi
	output            pcpi_valid,
	output [ILEN-1:0] pcpi_insn,
	output [    15:0] pcpi_prefix,
	output [XLEN-1:0] pcpi_pc,
	output [XLEN-1:0] pcpi_rs1_data,
	output [XLEN-1:0] pcpi_rs2_data,
	output [XLEN-1:0] pcpi_rs3_data,
	input             pcpi_ready,
	input             pcpi_wb_write,
	input  [XLEN-1:0] pcpi_wb_data,
	input             pcpi_br_enable,
	input  [XLEN-1:0] pcpi_br_nextpc
);
	wire pcpi_valid_raw;
	wire pcpi_rs1_valid;
	wire pcpi_rs2_valid;
	wire pcpi_rs3_valid;
	wire pcpi_wb_valid;

	wire [XLEN-1:0] pcpi_rs3_data_raw;
	assign pcpi_rs3_data = PCPI_RS3 ? pcpi_rs3_data_raw : 0;

	assign pcpi_valid = pcpi_valid_raw && pcpi_rs1_valid && pcpi_rs2_valid && (PCPI_RS3 && pcpi_rs3_valid) && pcpi_wb_valid;

	assign irq_ack = 0;

	picorv_core #(
		.CPI(CPI),
		.XLEN(XLEN),
		.ILEN(ILEN),
		.IALIGN(IALIGN),
		.SPINIT(SPINIT)
	) core (
		.clock          (clock         ),
		.reset          (reset         ),
		.rvec           (RST_VECTOR    ),

		.mem_valid      (mem_valid     ),
		.mem_ready      (mem_ready     ),
		.mem_insn       (mem_insn      ),
		.mem_addr       (mem_addr      ),
		.mem_rdata      (mem_rdata     ),
		.mem_wdata      (mem_wdata     ),
		.mem_wstrb      (mem_wstrb     ),

		.decode_valid   (              ),
		.decode_insn    (              ),
		.decode_prefix  (              ),

		.pcpi_valid     (pcpi_valid_raw),
		.pcpi_insn      (pcpi_insn     ),
		.pcpi_prefix    (pcpi_prefix   ),
		.pcpi_pc        (pcpi_pc       ),
		.pcpi_rs1_valid (pcpi_rs1_valid),
		.pcpi_rs1_data  (pcpi_rs1_data ),
		.pcpi_rs2_valid (pcpi_rs2_valid),
		.pcpi_rs2_data  (pcpi_rs2_data ),
		.pcpi_rs3_valid (pcpi_rs3_valid),
		.pcpi_rs3_data  (pcpi_rs3_data_raw),
		.pcpi_ready     (PCPI && pcpi_ready),
		.pcpi_wb_valid  (pcpi_wb_valid ),
		.pcpi_wb_async  (1'b 0         ),
		.pcpi_wb_write  (PCPI && pcpi_ready ? pcpi_wb_write  : 1'b 0),
		.pcpi_wb_data   (PCPI && pcpi_ready ? pcpi_wb_data   : {XLEN{1'b0}}),
		.pcpi_br_enable (PCPI && pcpi_ready ? pcpi_br_enable : 1'b 0),
		.pcpi_br_nextpc (PCPI && pcpi_ready ? pcpi_br_nextpc : {XLEN{1'b0}}),

		.awb_valid      (1'b 0         ),
		.awb_ready      (              ),
		.awb_addr       (5'd 0         ),
		.awb_data       ({XLEN{1'b0}}  )
	);
endmodule
