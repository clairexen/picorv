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

	// decode
	output            decode_valid,
	output [ILEN-1:0] decode_insn,
	output [    15:0] decode_prefix,

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

		.decode_valid   (decode_valid  ),
		.decode_insn    (decode_insn   ),
		.decode_prefix  (decode_prefix ),

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

	reg [7:0] memory [0:4096];
	reg [31:0] expected_pc;
	reg [2:0] cover_tags = 0;

	initial begin
		assume (reset);
	end

	always @* begin
		if (pcpi_valid && pcpi_rs1_valid && pcpi_rs1_addr == awb_addr)
			assume (!awb_valid);
		if (pcpi_valid && pcpi_rs2_valid && pcpi_rs2_addr == awb_addr)
			assume (!awb_valid);
		if (pcpi_valid && pcpi_rs3_valid && pcpi_rs3_addr == awb_addr)
			assume (!awb_valid);

		if (mem_valid && mem_ready) begin
			assert (mem_addr[1:0] == 0);
			assume (mem_rdata[ 7: 0] == memory[mem_addr[11:0] + 12'd 0]);
			assume (mem_rdata[15: 8] == memory[mem_addr[11:0] + 12'd 1]);
			assume (mem_rdata[23:16] == memory[mem_addr[11:0] + 12'd 2]);
			assume (mem_rdata[31:24] == memory[mem_addr[11:0] + 12'd 3]);
		end
		if (pcpi_valid) begin
			assert (pcpi_prefix[ 7:0] == memory[pcpi_pc[11:0] + 12'd 0]);
			assert (pcpi_prefix[15:8] == memory[pcpi_pc[11:0] + 12'd 1]);
			if (pcpi_prefix[1:0] == 3) begin
				assert (pcpi_insn[15:0] == pcpi_prefix[15:0]);
				assert (pcpi_insn[23:16] == memory[pcpi_pc[11:0] + 12'd 2]);
				assert (pcpi_insn[31:24] == memory[pcpi_pc[11:0] + 12'd 3]);
			end
		end

		assume (rvec[0] == 0);
		assume (pcpi_br_nextpc[0] == 0);
	end

	always @(posedge clock) begin
		if (!reset) begin
			assert ($past(decode_valid) == (pcpi_valid && $past(pcpi_ready || !pcpi_valid)));
			if ($past(decode_valid)) begin
				assert ($past(decode_insn) == pcpi_insn);
				assert ($past(decode_prefix) == pcpi_prefix);
			end
			if (pcpi_valid && pcpi_ready) begin
				if (pcpi_br_enable) begin
					cover_tags[0] <= 1;
					expected_pc <= pcpi_br_nextpc;
				end else if (pcpi_prefix[1:0] == 3) begin
					cover_tags[1] <= 1;
					expected_pc <= pcpi_pc + 4;
				end else begin
					cover_tags[2] <= 1;
					expected_pc <= pcpi_pc + 2;
				end
				cover (&cover_tags);
			end
			if (pcpi_valid) begin
				assert (pcpi_pc == expected_pc);
				if ($past(pcpi_valid) && !$past(pcpi_ready)) begin
					assert ($stable(pcpi_insn));
					assert ($stable(pcpi_prefix));
					assert ($stable(pcpi_pc));
					if (pcpi_rs1_valid && $past(pcpi_rs1_valid))
						assert ($stable(pcpi_rs1_data));
					if (pcpi_rs2_valid && $past(pcpi_rs2_valid))
						assert ($stable(pcpi_rs2_data));
					if (pcpi_rs3_valid && $past(pcpi_rs3_valid))
						assert ($stable(pcpi_rs3_data));
				end
			end
		end else begin
			expected_pc <= rvec;
			cover_tags <= 0;
		end
	end
endmodule
