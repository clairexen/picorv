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

module picorv_ldst #(
	parameter integer XLEN = 32,
	parameter integer ILEN = 32
) (
	// control
	input            clock,
	input            reset,

	// memory interface
	output            mem_reqst,
	input             mem_grant,
	output            mem_valid,
	input             mem_ready,
	output [XLEN-1:0] mem_addr,
	input  [    31:0] mem_rdata,
	output [    31:0] mem_wdata,
	output [     3:0] mem_wstrb,

	// decode
	input             decode_valid,
	input  [ILEN-1:0] decode_insn,
	input  [    15:0] decode_prefix,

	// pcpi
	input             pcpi_valid,
	input  [ILEN-1:0] pcpi_insn,
	input  [    15:0] pcpi_prefix,
	input  [XLEN-1:0] pcpi_pc,
	input             pcpi_rs1_valid,
	input  [XLEN-1:0] pcpi_rs1_data,
	input             pcpi_rs2_valid,
	input  [XLEN-1:0] pcpi_rs2_data,
	input             pcpi_rs3_valid,
	input  [XLEN-1:0] pcpi_rs3_data,
	output            pcpi_ready,
	input             pcpi_wb_valid,
	output            pcpi_wb_async,
	output            pcpi_wb_write,
	output [XLEN-1:0] pcpi_wb_data,

	// async writeback
	output            awb_valid,
	input             awb_ready,
	output [     4:0] awb_addr,
	output [XLEN-1:0] awb_data
);
	reg insn_ld;
	reg insn_st;

	always @(posedge clock) begin
		if (reset || decode_valid || pcpi_ready) begin
			insn_ld <= 0;
			insn_st <= 0;
		end

		if (!reset && decode_valid && (decode_prefix[4:0] != 5'b 11111 || ILEN == 32)) begin
			(* parallel_case *)
			casez ({decode_insn, XLEN==64})
				33'b zzzzzzz_zzzzz_zzzzz_000_zzzzz_0000011_z: insn_ld <= 1;      // LB
				33'b zzzzzzz_zzzzz_zzzzz_001_zzzzz_0000011_z: insn_ld <= 1;      // LH
				33'b zzzzzzz_zzzzz_zzzzz_010_zzzzz_0000011_z: insn_ld <= 1;      // LW
				33'b zzzzzzz_zzzzz_zzzzz_011_zzzzz_0000011_1: insn_ld <= 1;      // LD
				33'b zzzzzzz_zzzzz_zzzzz_100_zzzzz_0000011_z: insn_ld <= 1;      // LBU
				33'b zzzzzzz_zzzzz_zzzzz_101_zzzzz_0000011_z: insn_ld <= 1;      // LHU
				33'b zzzzzzz_zzzzz_zzzzz_110_zzzzz_0000011_1: insn_ld <= 1;      // LWU

				33'b zzzzzzz_zzzzz_zzzzz_000_zzzzz_0100011_z: insn_st <= 1;      // SB
				33'b zzzzzzz_zzzzz_zzzzz_001_zzzzz_0100011_z: insn_st <= 1;      // SH
				33'b zzzzzzz_zzzzz_zzzzz_010_zzzzz_0100011_z: insn_st <= 1;      // SW
				33'b zzzzzzz_zzzzz_zzzzz_011_zzzzz_0100011_1: insn_st <= 1;      // SD
			endcase
		end
	end

	reg insn_okay;

	always @* begin
		insn_okay = mem_grant;

		if (insn_ld && !pcpi_rs1_valid) begin
			insn_okay = 0;
		end

		if (insn_st && !(pcpi_rs1_valid && pcpi_rs2_valid)) begin
			insn_okay = 0;
		end
	end

	// -----------------------------------------------------------------------------------------------

	reg mem_valid_reg;
	reg [XLEN-1:0] mem_addr_reg;
	reg [31:0] mem_rdata_processed;
	reg [31:0] mem_wdata_reg;
	reg [3:0] mem_wstrb_reg;
	reg [2:0] mem_funct3;
	reg [1:0] mem_shift;

	always @* begin
		mem_rdata_processed = mem_rdata >> (8*mem_shift);
		case (mem_funct3)
			3'b 000: mem_rdata_processed = $signed(mem_rdata_processed[7:0]);
			3'b 001: mem_rdata_processed = $signed(mem_rdata_processed[15:0]);
			3'b 100: mem_rdata_processed = mem_rdata_processed[7:0];
			3'b 101: mem_rdata_processed = mem_rdata_processed[15:0];
		endcase
	end

	assign mem_reqst = insn_ld || insn_st || mem_valid_reg;
	assign mem_valid = mem_valid_reg;
	assign mem_addr = mem_addr_reg;
	assign mem_wdata = mem_wdata_reg;
	assign mem_wstrb = mem_wstrb_reg;

	reg awb_valid_reg;
	reg [4:0] awb_addr_reg;
	reg [XLEN-1:0] awb_data_reg;

	assign awb_valid = awb_valid_reg;
	assign awb_addr = awb_addr_reg;
	assign awb_data = awb_data_reg;

	reg pcpi_ready_reg;
	reg pcpi_wb_write_reg;
	reg pcpi_wb_async_reg;

	assign pcpi_ready = pcpi_ready_reg && (!pcpi_wb_write_reg || pcpi_wb_valid);
	assign pcpi_wb_write = pcpi_wb_write_reg;
	assign pcpi_wb_async = pcpi_wb_async_reg;
	assign pcpi_wb_data = 0;

	// -----------------------------------------------------------------------------------------------

	wire [XLEN-1:0] imm_itype = $signed(pcpi_insn[31:20]);
	wire [XLEN-1:0] imm_stype = $signed({pcpi_insn[31:25], pcpi_insn[11:7]});

	wire [XLEN-1:0] ldst_addr = pcpi_rs1_data + (insn_st ? imm_stype : imm_itype);
	wire [3:0] ldst_mask = {pcpi_insn[13], pcpi_insn[13], pcpi_insn[13] || pcpi_insn[12], 1'b1};

	always @(posedge clock) begin
		pcpi_ready_reg <= 0;
		pcpi_wb_async_reg <= 0;
		pcpi_wb_write_reg <= 0;

		if (insn_ld && insn_okay && !mem_valid_reg && !awb_valid_reg && pcpi_wb_valid) begin
			pcpi_ready_reg <= 1;
			mem_valid_reg <= 1;
			mem_addr_reg <= ldst_addr & ~3;
			mem_wstrb_reg <= 0;
			mem_funct3 <= pcpi_insn[14:12];
			mem_shift <= ldst_addr & 3;
			pcpi_wb_async_reg <= 1;
			awb_addr_reg <= pcpi_insn[11:7];
		end

		if (insn_st && insn_okay && !mem_valid_reg) begin
			pcpi_ready_reg <= 1;
			mem_valid_reg <= 1;
			mem_addr_reg <= ldst_addr & ~3;
			mem_wdata_reg <= pcpi_rs2_data << 8*(ldst_addr & 3);
			mem_wstrb_reg <= ldst_mask << (ldst_addr & 3);
		end

		if (mem_valid && mem_ready) begin
			mem_valid_reg <= 0;
			if (!mem_wstrb_reg) begin
				awb_valid_reg <= 1;
				awb_data_reg <= mem_rdata_processed;
			end
		end

		if (awb_valid && awb_ready) begin
			awb_valid_reg <= 0;
		end

		if (reset || pcpi_ready) begin
			pcpi_ready_reg <= 0;
			pcpi_wb_async_reg <= 0;
			pcpi_wb_write_reg <= 0;
		end

		if (reset) begin
			mem_valid_reg <= 0;
			awb_valid_reg <= 0;
		end
	end
endmodule
