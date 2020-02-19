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

module picorv_exec #(
	parameter integer XLEN = 32,
	parameter integer ILEN = 32,
	parameter integer CPI = 2
) (
	// control
	input            clock,
	input            reset,

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
	output            pcpi_wb_write,
	output [XLEN-1:0] pcpi_wb_data,
	output            pcpi_br_enable,
	output [XLEN-1:0] pcpi_br_nextpc
);
	reg insn_lui;
	reg insn_auipc;
	reg insn_jal;
	reg insn_jalr;
	reg insn_br;
	reg insn_alu;

	always @(posedge clock) begin
		if (reset || decode_valid || pcpi_ready) begin
			insn_lui <= 0;
			insn_auipc <= 0;
			insn_jal <= 0;
			insn_jalr <= 0;
			insn_br <= 0;
			insn_alu <= 0;
		end

		if (!reset && decode_valid && (decode_prefix[4:0] != 5'b 11111 || ILEN == 32)) begin
			(* parallel_case *)
			casez ({decode_insn, XLEN==64})
				33'b zzzzzzz_zzzzz_zzzzz_zzz_zzzzz_0110111_z: insn_lui <= 1;     // LUI
				33'b zzzzzzz_zzzzz_zzzzz_zzz_zzzzz_0010111_z: insn_auipc <= 1;   // AUIPC
				33'b zzzzzzz_zzzzz_zzzzz_zzz_zzzzz_1101111_z: insn_jal <= 1;     // JAL
				33'b zzzzzzz_zzzzz_zzzzz_000_zzzzz_1100111_z: insn_jalr <= 1;    // JALR

				33'b zzzzzzz_zzzzz_zzzzz_000_zzzzz_1100011_z: insn_br <= 1;      // BEQ
				33'b zzzzzzz_zzzzz_zzzzz_001_zzzzz_1100011_z: insn_br <= 1;      // BNE
				33'b zzzzzzz_zzzzz_zzzzz_100_zzzzz_1100011_z: insn_br <= 1;      // BLT
				33'b zzzzzzz_zzzzz_zzzzz_101_zzzzz_1100011_z: insn_br <= 1;      // BGE
				33'b zzzzzzz_zzzzz_zzzzz_110_zzzzz_1100011_z: insn_br <= 1;      // BLTU
				33'b zzzzzzz_zzzzz_zzzzz_111_zzzzz_1100011_z: insn_br <= 1;      // BGEU

				33'b zzzzzzz_zzzzz_zzzzz_000_zzzzz_0010011_z: insn_alu <= 1;     // ADDI
				33'b zzzzzzz_zzzzz_zzzzz_010_zzzzz_0010011_z: insn_alu <= 1;     // SLTI
				33'b zzzzzzz_zzzzz_zzzzz_011_zzzzz_0010011_z: insn_alu <= 1;     // SLTIU
				33'b zzzzzzz_zzzzz_zzzzz_100_zzzzz_0010011_z: insn_alu <= 1;     // XORI
				33'b zzzzzzz_zzzzz_zzzzz_110_zzzzz_0010011_z: insn_alu <= 1;     // ORI
				33'b zzzzzzz_zzzzz_zzzzz_111_zzzzz_0010011_z: insn_alu <= 1;     // ANDI

				33'b 0000000_zzzzz_zzzzz_001_zzzzz_0010011_z: insn_alu <= 1;     // SLLI
				33'b 0000000_zzzzz_zzzzz_101_zzzzz_0010011_z: insn_alu <= 1;     // SRLI
				33'b 0100000_zzzzz_zzzzz_101_zzzzz_0010011_z: insn_alu <= 1;     // SRAI

				33'b 0000000_zzzzz_zzzzz_000_zzzzz_0110011_z: insn_alu <= 1;     // ADD
				33'b 0100000_zzzzz_zzzzz_000_zzzzz_0110011_z: insn_alu <= 1;     // SUB
				33'b 0000000_zzzzz_zzzzz_001_zzzzz_0110011_z: insn_alu <= 1;     // SLL
				33'b 0000000_zzzzz_zzzzz_010_zzzzz_0110011_z: insn_alu <= 1;     // SLT
				33'b 0000000_zzzzz_zzzzz_011_zzzzz_0110011_z: insn_alu <= 1;     // SLTU
				33'b 0000000_zzzzz_zzzzz_100_zzzzz_0110011_z: insn_alu <= 1;     // XOR
				33'b 0000000_zzzzz_zzzzz_101_zzzzz_0110011_z: insn_alu <= 1;     // SRL
				33'b 0100000_zzzzz_zzzzz_101_zzzzz_0110011_z: insn_alu <= 1;     // SRA
				33'b 0000000_zzzzz_zzzzz_110_zzzzz_0110011_z: insn_alu <= 1;     // OR
				33'b 0000000_zzzzz_zzzzz_111_zzzzz_0110011_z: insn_alu <= 1;     // AND
			endcase
		end
	end

	reg insn_okay;

	always @* begin
		insn_okay = 1;

		if (insn_jalr && !pcpi_rs1_valid) begin
			insn_okay = 0;
		end

		if (insn_br && !(pcpi_rs1_valid && pcpi_rs2_valid)) begin
			insn_okay = 0;
		end

		if (insn_alu && !(pcpi_rs1_valid && (pcpi_rs2_valid || !pcpi_insn[5]))) begin
			insn_okay = 0;
		end
	end

	// -----------------------------------------------------------------------------------------------

	reg pcpi_ready_nxt;
	reg pcpi_wb_write_nxt;
	reg [XLEN-1:0] pcpi_wb_data_nxt;
	reg pcpi_br_enable_nxt;
	reg [XLEN-1:0] pcpi_br_nextpc_nxt;

	reg pcpi_ready_reg;
	reg pcpi_wb_write_reg;
	reg [XLEN-1:0] pcpi_wb_data_reg;
	reg pcpi_br_enable_reg;
	reg [XLEN-1:0] pcpi_br_nextpc_reg;

	generate if (CPI > 1) begin:ffs
		always @(posedge clock) begin
			pcpi_ready_reg     <= pcpi_ready_nxt && insn_okay;
			pcpi_wb_write_reg  <= pcpi_wb_write_nxt;
			pcpi_wb_data_reg   <= pcpi_wb_data_nxt;
			pcpi_br_enable_reg <= pcpi_br_enable_nxt;
			pcpi_br_nextpc_reg <= pcpi_br_nextpc_nxt;
		end
	end else begin:noffs
		always @* begin
			pcpi_ready_reg     = pcpi_ready_nxt && insn_okay;
			pcpi_wb_write_reg  = pcpi_wb_write_nxt;
			pcpi_wb_data_reg   = pcpi_wb_data_nxt;
			pcpi_br_enable_reg = pcpi_br_enable_nxt;
			pcpi_br_nextpc_reg = pcpi_br_nextpc_nxt;
		end
	end endgenerate

	assign pcpi_ready = pcpi_ready_reg && (!pcpi_wb_write_reg || pcpi_wb_valid);
	assign pcpi_wb_write = pcpi_wb_write_reg;
	assign pcpi_wb_data = pcpi_wb_data_reg;
	assign pcpi_br_enable = pcpi_br_enable_reg;
	assign pcpi_br_nextpc = pcpi_br_nextpc_reg;

	// -----------------------------------------------------------------------------------------------

	wire [XLEN-1:0] imm_itype = $signed(pcpi_insn[31:20]);
	wire [XLEN-1:0] imm_btype = $signed({pcpi_insn[31], pcpi_insn[7], pcpi_insn[30:25], pcpi_insn[11:8], 1'b0});
	wire [XLEN-1:0] imm_utype = $signed({pcpi_insn[31:12]});
	wire [XLEN-1:0] imm_jtype = $signed({pcpi_insn[31], pcpi_insn[19:12], pcpi_insn[20], pcpi_insn[30:21], 1'b0});

	wire [XLEN-1:0] next_pc = pcpi_pc + (pcpi_prefix[1:0] == 2'b11 ? 4 : 2);
	wire [XLEN-1:0] branch_pc = pcpi_pc + (insn_auipc ? imm_utype << 12 : insn_jal ? imm_jtype : imm_btype);
	wire [XLEN-1:0] jalr_addr = (pcpi_rs1_data + imm_itype) & ~1;

	wire [XLEN-1:0] alu_rs1 = pcpi_rs1_data;
	wire [XLEN-1:0] alu_rs2 = pcpi_insn[5] ? pcpi_rs2_data : imm_itype;
	wire [XLEN-1:0] alu_out;

	picorv_exec_alu #(
		.XLEN(32)
	) alu (
		.din1(alu_rs1),
		.din2(alu_rs2),
		.fun3(pcpi_insn[14:12]),
		.fun7(pcpi_insn[31:25]),
		.bflg(insn_br),
		.iflg(!pcpi_insn[5]),
		.dout(alu_out)
	);

	// -----------------------------------------------------------------------------------------------

	always @* begin
		pcpi_ready_nxt = 0;
		pcpi_wb_write_nxt = 0;
		pcpi_wb_data_nxt = 0;
		pcpi_br_enable_nxt = 0;
		pcpi_br_nextpc_nxt = 0;

		if (insn_lui) begin
			pcpi_ready_nxt = 1;
			pcpi_wb_write_nxt = 1;
			pcpi_wb_data_nxt = imm_utype << 12;
		end

		if (insn_auipc) begin
			pcpi_ready_nxt = 1;
			pcpi_wb_write_nxt = 1;
			pcpi_wb_data_nxt = branch_pc;
		end

		if (insn_jal) begin
			pcpi_ready_nxt = 1;
			pcpi_wb_write_nxt = 1;
			pcpi_wb_data_nxt = next_pc;
			pcpi_br_enable_nxt = 1;
			pcpi_br_nextpc_nxt = branch_pc;
		end

		if (insn_jalr) begin
			pcpi_ready_nxt = 1;
			pcpi_wb_write_nxt = 1;
			pcpi_wb_data_nxt = next_pc;
			pcpi_br_enable_nxt = 1;
			pcpi_br_nextpc_nxt = jalr_addr;
		end

		if (insn_br) begin
			pcpi_ready_nxt = 1;
			pcpi_br_enable_nxt = alu_out[0];
			pcpi_br_nextpc_nxt = branch_pc;
		end

		if (insn_alu) begin
			pcpi_ready_nxt = 1;
			pcpi_wb_write_nxt = 1;
			pcpi_wb_data_nxt = alu_out;
		end

		if (reset || (CPI > 1 && pcpi_ready)) begin
			pcpi_ready_nxt = 0;
			pcpi_wb_write_nxt = 0;
			pcpi_wb_data_nxt = 0;
			pcpi_br_enable_nxt = 0;
			pcpi_br_nextpc_nxt = 0;
		end
	end

endmodule

// -----------------------------------------------------------------------------------------------

module picorv_exec_alu #(
	parameter integer XLEN = 32
) (
	input  [XLEN-1:0] din1,
	input  [XLEN-1:0] din2,
	input  [     2:0] fun3,
	input  [     6:0] fun7,
	input             bflg,
	input             iflg,
	output [XLEN-1:0] dout
);
	wire alu_neg = (fun7[5] && !iflg) || bflg;
	wire [XLEN-1:0] din2_neg = alu_neg ? ~din2 : din2;

	reg [XLEN-1:0] alu_out;
	reg alu_eq, alu_lt;

	wire [XLEN:0] din1_sext = {!(bflg ? fun3[1] : fun3[0]) && din1[XLEN-1], din1};
	wire [XLEN:0] din2_sext = {!(bflg ? fun3[1] : fun3[0]) && din2[XLEN-1], din2};

	assign dout = alu_out;

	function [XLEN-1:0] reflect;
		input [XLEN-1:0] din;
		integer i;
		begin
			for (i = 0; i < XLEN; i=i+1)
				reflect[i] = din[XLEN-i-1];
		end
	endfunction

	always @* begin
		alu_out = 'bx;
		alu_eq = 'bx;
		alu_lt = 'bx;

		(* parallel_case, full_case *)
		casez ({bflg, fun3})
			// BEQ, BNE, BLT, BGE, BLTU, BGEU, ADDI, ADD, SUB, SLT, SLTU
			4'b 1_zzz, 4'b 0_000, 4'b 0_01z: begin
				alu_out = din1 + din2_neg + alu_neg;
				alu_eq = din1 == din2;
				alu_lt = $signed(din1_sext) < $signed(din2_sext);
				casez ({bflg, fun3})
					4'b 1_000: // BEQ
						alu_out = alu_eq;
					4'b 1_001: // BNE
						alu_out = !alu_eq;
					4'b 1_100, // BLT
					4'b 1_110, // BLTU
					4'b 0_010, // SLT
					4'b 0_011: // SLTU
						alu_out = alu_lt;
					4'b 1_101, // BGE
					4'b 1_111: // BGEU
						alu_out = !alu_lt;
				endcase
			end

			// SLLI, SRLI, SRAI, SLL, SRL, SRA
			4'b 0_z01: begin
				alu_out = fun3[2] ? din1 : reflect(din1);
				alu_out = {{XLEN{alu_out[XLEN-1] && fun7[5]}}, alu_out} >> (din2 & (XLEN-1));
				alu_out = fun3[2] ? alu_out : reflect(alu_out);
			end

			// XOR, XNOR
			4'b 0_100: begin
				alu_out = din1 ^ din2_neg;
			end

			// OR, ORN
			4'b 0_110: begin
				alu_out = din1 | din2_neg;
			end

			// AND, ANDN
			4'b 0_111: begin
				alu_out = din1 & din2_neg;
			end
		endcase
	end
endmodule
