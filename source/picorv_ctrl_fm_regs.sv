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

module top #(
	parameter integer XLEN = 32,
	parameter integer ILEN = 32,
	parameter integer IALIGN = 16,
	parameter integer RPORTS = 3
) (
	// control
	input            clock,
	input            reset,
	input [XLEN-1:0] rvec,

	// memory interface
	output            mem_valid,
	input             mem_ready,
	output [XLEN-1:0] mem_addr,
	input  [    31:0] mem_rdata,

	// pcpi
	output            pcpi_valid,
	output [ILEN-1:0] pcpi_insn,
	output [    15:0] pcpi_prefix,
	output [XLEN-1:0] pcpi_pc,
	output            pcpi_rs1_valid,
	output [XLEN-1:0] pcpi_rs1_data,
	output            pcpi_rs2_valid,
	output [XLEN-1:0] pcpi_rs2_data,
	output            pcpi_rs3_valid,
	output [XLEN-1:0] pcpi_rs3_data,
	input             pcpi_ready,
	output            pcpi_wb_valid,
	input             pcpi_wb_write,
	input             pcpi_wb_async,
	input  [XLEN-1:0] pcpi_wb_data,
	input             pcpi_br_enable,
	input  [XLEN-1:0] pcpi_br_nextpc,

	// async writeback
	input             awb_valid,
	output            awb_ready,
	input  [     4:0] awb_addr,
	input  [XLEN-1:0] awb_data
);
	wire [4:0] pcpi_rd_addr = pcpi_insn[11:7];
	wire [4:0] pcpi_rs1_addr = pcpi_insn[19:15];
	wire [4:0] pcpi_rs2_addr = pcpi_insn[24:20];
	wire [4:0] pcpi_rs3_addr = pcpi_insn[31:27];

	picorv_ctrl #(
		.XLEN(XLEN),
		.ILEN(ILEN),
		.IALIGN(IALIGN),
		.RPORTS(RPORTS)
	) uut (
		.clock          (clock         ),
		.reset          (reset         ),
		.rvec           (rvec          ),

		.mem_valid      (mem_valid     ),
		.mem_ready      (mem_ready     ),
		.mem_addr       (mem_addr      ),
		.mem_rdata      (mem_rdata     ),

		.pcpi_valid     (pcpi_valid    ),
		.pcpi_insn      (pcpi_insn     ),
		.pcpi_prefix    (pcpi_prefix   ),
		.pcpi_pc        (pcpi_pc       ),
		.pcpi_rs1_valid (pcpi_rs1_valid),
		.pcpi_rs1_data  (pcpi_rs1_data ),
		.pcpi_rs2_valid (pcpi_rs2_valid),
		.pcpi_rs2_data  (pcpi_rs2_data ),
		.pcpi_rs3_valid (pcpi_rs3_valid),
		.pcpi_rs3_data  (pcpi_rs3_data ),
		.pcpi_ready     (pcpi_ready    ),
		.pcpi_wb_valid  (pcpi_wb_valid ),
		.pcpi_wb_write  (pcpi_wb_write ),
		.pcpi_wb_async  (pcpi_wb_async ),
		.pcpi_wb_data   (pcpi_wb_data  ),
		.pcpi_br_enable (pcpi_br_enable),
		.pcpi_br_nextpc (pcpi_br_nextpc),

		.awb_valid      (awb_valid     ),
		.awb_ready      (awb_ready     ),
		.awb_addr       (awb_addr      ),
		.awb_data       (awb_data      )
	);

	rand const reg [4:0] shadow_addr;
	reg [XLEN-1:0] shadow_data;
	reg shadow_pending = 0;
	reg shadow_valid = 0;

	initial begin
		assume (reset);
		assume (shadow_addr != 0);
	end

	always @* begin
		if (!pcpi_wb_valid) begin
			assume (!pcpi_wb_write);
			assume (!pcpi_wb_async);
		end
		assume (!pcpi_wb_write || !pcpi_wb_async);
	end

	always @(posedge clock) begin
		if (!reset) begin
			if (awb_valid && awb_addr == shadow_addr) begin
				assume (shadow_pending);
				if (awb_ready) begin
					shadow_pending <= 0;
					shadow_valid <= 1;
					shadow_data <= awb_data;
				end
			end

			if (pcpi_valid) begin
				if (shadow_addr == pcpi_insn[19:15] && pcpi_rs1_valid) begin
					assert (!shadow_pending);
					assert (!shadow_valid || shadow_data == pcpi_rs1_data);
				end
				if (shadow_addr == pcpi_insn[24:20] && pcpi_rs2_valid) begin
					assert (!shadow_pending);
					assert (!shadow_valid || shadow_data == pcpi_rs2_data);
				end
				if (shadow_addr == pcpi_insn[31:27] && pcpi_rs3_valid) begin
					assert (!shadow_pending);
					assert (!shadow_valid || shadow_data == pcpi_rs3_data);
				end
				if (shadow_addr == pcpi_insn[11:7] && pcpi_valid && !shadow_pending) begin
					assert (pcpi_wb_valid);
				end
				if (shadow_addr == pcpi_insn[11:7] && pcpi_ready && pcpi_wb_write) begin
					assert (!shadow_pending);
					shadow_valid <= 1;
					shadow_data <= pcpi_wb_data;
				end
				if (shadow_addr == pcpi_insn[11:7] && pcpi_ready && pcpi_wb_async) begin
					assert (!shadow_pending);
					shadow_pending <= 1;
					shadow_valid <= 0;
				end
			end

			cover (awb_valid && awb_ready && awb_addr == shadow_addr);
		end else begin
			shadow_pending <= 0;
		end
	end
endmodule
