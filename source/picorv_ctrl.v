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

module picorv_ctrl #(
	parameter integer XLEN = 32,
	parameter integer ILEN = 32,
	parameter integer IALIGN = 16,
	parameter integer RPORTS = 3,
	parameter [XLEN-1:0] SPINIT = 1
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
	input             pcpi_wb_async,
	input             pcpi_wb_write,
	input  [XLEN-1:0] pcpi_wb_data,
	input             pcpi_br_enable,
	input  [XLEN-1:0] pcpi_br_nextpc,

	// async writeback
	input             awb_valid,
	output            awb_ready,
	input  [     4:0] awb_addr,
	input  [XLEN-1:0] awb_data
);
	reg [XLEN-1:0] registerfile [0:30];

	reg [30:0] scoreboard;
	reg [XLEN-1:0] pc;

	reg [4:0] bypass_addr;
	reg [XLEN-1:0] bypass_data;

	reg [     4:0] wport_addr;
	reg [XLEN-1:0] wport_data;

	reg [4:0] rport1_addr;
	reg [4:0] rport2_addr;
	reg [4:0] rport3_addr;

	reg [XLEN-1:0] rport1_data;
	reg [XLEN-1:0] rport2_data;
	reg [XLEN-1:0] rport3_data;

	wire spreset = reset && !SPINIT[0];

	always @(posedge clock) begin
		bypass_addr <= 0;
		if (spreset || (!reset && wport_addr)) begin
			registerfile[spreset ? 5'd 29 : ~wport_addr] <= spreset ? SPINIT : wport_data;
			bypass_addr <= wport_addr;
			bypass_data <= wport_data;
		end
		if (RPORTS > 0)
			rport1_data <= registerfile[~rport1_addr];
		if (RPORTS > 1)
			rport2_data <= registerfile[~rport2_addr];
		if (RPORTS > 2)
			rport3_data <= registerfile[~rport3_addr];
`ifdef PICORV_DEBUG
		if (RPORTS < 1 || scoreboard[~rport1_addr])
			rport1_data <= 'bx;
		if (RPORTS < 2 || scoreboard[~rport2_addr])
			rport2_data <= 'bx;
		if (RPORTS < 3 || scoreboard[~rport3_addr])
			rport3_data <= 'bx;
`endif
		if (reset) begin
			bypass_addr <= 0;
		end
	end

	reg [XLEN-1:0] rs1_reg;
	reg [XLEN-1:0] rs2_reg;
	reg [XLEN-1:0] rs3_reg;

	reg [XLEN-1:0] rs1_rdata;
	reg [XLEN-1:0] rs2_rdata;
	reg [XLEN-1:0] rs3_rdata;

	always @(posedge clock) begin
		rs1_reg <= rs1_rdata;
		rs2_reg <= rs2_rdata;
		rs3_reg <= rs3_rdata;
	end

`ifdef PICORV_DEBUG
	wire [XLEN-1:0] reg__x1__ra = scoreboard[~5'd 1] ? 'bx : registerfile[~5'd 1];
	wire [XLEN-1:0] reg__x2__sp = scoreboard[~5'd 2] ? 'bx : registerfile[~5'd 2];
	wire [XLEN-1:0] reg__x3__gp = scoreboard[~5'd 3] ? 'bx : registerfile[~5'd 3];
	wire [XLEN-1:0] reg__x4__tp = scoreboard[~5'd 4] ? 'bx : registerfile[~5'd 4];
	wire [XLEN-1:0] reg__x5__t0 = scoreboard[~5'd 5] ? 'bx : registerfile[~5'd 5];
	wire [XLEN-1:0] reg__x6__t1 = scoreboard[~5'd 6] ? 'bx : registerfile[~5'd 6];
	wire [XLEN-1:0] reg__x7__t2 = scoreboard[~5'd 7] ? 'bx : registerfile[~5'd 7];
	wire [XLEN-1:0] reg__x8__fp = scoreboard[~5'd 8] ? 'bx : registerfile[~5'd 8];
	wire [XLEN-1:0] reg__x9__s1 = scoreboard[~5'd 9] ? 'bx : registerfile[~5'd 9];
	wire [XLEN-1:0] reg_x10__a0 = scoreboard[~5'd10] ? 'bx : registerfile[~5'd10];
	wire [XLEN-1:0] reg_x11__a1 = scoreboard[~5'd11] ? 'bx : registerfile[~5'd11];
	wire [XLEN-1:0] reg_x12__a2 = scoreboard[~5'd12] ? 'bx : registerfile[~5'd12];
	wire [XLEN-1:0] reg_x13__a3 = scoreboard[~5'd13] ? 'bx : registerfile[~5'd13];
	wire [XLEN-1:0] reg_x14__a4 = scoreboard[~5'd14] ? 'bx : registerfile[~5'd14];
	wire [XLEN-1:0] reg_x15__a5 = scoreboard[~5'd15] ? 'bx : registerfile[~5'd15];
	wire [XLEN-1:0] reg_x16__a6 = scoreboard[~5'd16] ? 'bx : registerfile[~5'd16];
	wire [XLEN-1:0] reg_x17__a7 = scoreboard[~5'd17] ? 'bx : registerfile[~5'd17];
	wire [XLEN-1:0] reg_x18__s2 = scoreboard[~5'd18] ? 'bx : registerfile[~5'd18];
	wire [XLEN-1:0] reg_x19__s3 = scoreboard[~5'd19] ? 'bx : registerfile[~5'd19];
	wire [XLEN-1:0] reg_x20__s4 = scoreboard[~5'd20] ? 'bx : registerfile[~5'd20];
	wire [XLEN-1:0] reg_x21__s5 = scoreboard[~5'd21] ? 'bx : registerfile[~5'd21];
	wire [XLEN-1:0] reg_x22__s6 = scoreboard[~5'd22] ? 'bx : registerfile[~5'd22];
	wire [XLEN-1:0] reg_x23__s7 = scoreboard[~5'd23] ? 'bx : registerfile[~5'd23];
	wire [XLEN-1:0] reg_x24__s8 = scoreboard[~5'd24] ? 'bx : registerfile[~5'd24];
	wire [XLEN-1:0] reg_x25__s9 = scoreboard[~5'd25] ? 'bx : registerfile[~5'd25];
	wire [XLEN-1:0] reg_x26_s10 = scoreboard[~5'd26] ? 'bx : registerfile[~5'd26];
	wire [XLEN-1:0] reg_x27_s11 = scoreboard[~5'd27] ? 'bx : registerfile[~5'd27];
	wire [XLEN-1:0] reg_x28__t3 = scoreboard[~5'd28] ? 'bx : registerfile[~5'd28];
	wire [XLEN-1:0] reg_x29__t4 = scoreboard[~5'd29] ? 'bx : registerfile[~5'd29];
	wire [XLEN-1:0] reg_x30__t5 = scoreboard[~5'd30] ? 'bx : registerfile[~5'd30];
	wire [XLEN-1:0] reg_x31__t6 = scoreboard[~5'd31] ? 'bx : registerfile[~5'd31];
`endif

	integer i;

	localparam integer ibuf_len = ILEN + 16*(IALIGN == 16);

	reg mem_kill_reg;
	reg mem_valid_reg;
	reg [XLEN-1:0] mem_addr_reg;
	reg [XLEN-1:0] next_mem_addr;
	reg [ibuf_len-1:0] insn_buf;
	reg [2:0] insn_buf_vld;

	assign mem_valid = mem_valid_reg;
	assign mem_addr = mem_addr_reg & ~64'd3;

	reg [XLEN-1:0] next_pc;
	reg [ibuf_len-1:0] next_insn_buf;
	reg [2:0] next_insn_buf_vld;

	reg next_pcpi_valid;
	reg [ILEN-1:0] next_pcpi_insn;
	reg [15:0] next_pcpi_prefix;

	reg pcpi_valid_reg;
	reg [ILEN-1:0] pcpi_insn_reg;
	reg [15:0] pcpi_prefix_reg;

	reg [XLEN-1:0] pcpi_pc_reg;

	reg pcpi_rs1_zreg;
	reg pcpi_rs2_zreg;
	reg pcpi_rs3_zreg;

	reg pcpi_rs1_vreg;
	reg pcpi_rs2_vreg;
	reg pcpi_rs3_vreg;

	assign pcpi_valid = pcpi_valid_reg;
	assign pcpi_insn = pcpi_insn_reg;
	assign pcpi_prefix = pcpi_prefix_reg;
	assign pcpi_pc = pcpi_pc_reg;

	wire [4:0] rd_addr = pcpi_insn[11:7];
	wire [4:0] rs1_addr = pcpi_insn[19:15];
	wire [4:0] rs2_addr = pcpi_insn[24:20];
	wire [4:0] rs3_addr = pcpi_insn[31:27];

	assign pcpi_rs1_data = pcpi_rs1_zreg ? 0 : bypass_addr == rs1_addr ? bypass_data : rs1_rdata;
	assign pcpi_rs2_data = pcpi_rs2_zreg ? 0 : bypass_addr == rs2_addr ? bypass_data : rs2_rdata;
	assign pcpi_rs3_data = pcpi_rs3_zreg ? 0 : bypass_addr == rs3_addr ? bypass_data : rs3_rdata;

	assign pcpi_rs1_valid = pcpi_rs1_zreg || (pcpi_rs1_vreg && !scoreboard[~rs1_addr]) || bypass_addr == rs1_addr;
	assign pcpi_rs2_valid = pcpi_rs2_zreg || (pcpi_rs2_vreg && !scoreboard[~rs2_addr]) || bypass_addr == rs2_addr;
	assign pcpi_rs3_valid = pcpi_rs3_zreg || (pcpi_rs3_vreg && !scoreboard[~rs3_addr]) || bypass_addr == rs3_addr;
	assign pcpi_wb_valid = !(scoreboard[~rd_addr] && rd_addr);

	always @(posedge clock) begin
		if (RPORTS == 1) begin
			pcpi_rs2_vreg <= pcpi_rs1_vreg;
			pcpi_rs3_vreg <= pcpi_rs3_vreg;
		end
		if (RPORTS == 2) begin
			pcpi_rs3_vreg <= pcpi_rs1_vreg;
		end
		if (next_pcpi_valid) begin
			pcpi_rs1_vreg <= RPORTS > 0;
			pcpi_rs2_vreg <= RPORTS > 1;
			pcpi_rs3_vreg <= RPORTS > 2;

			pcpi_rs1_zreg <= !next_pcpi_insn[19:15];
			pcpi_rs2_zreg <= !next_pcpi_insn[24:20];
			pcpi_rs3_zreg <= !next_pcpi_insn[31:27];
		end
	end

	wire [31:0] cur_insn = next_pcpi_valid ? next_pcpi_insn : pcpi_insn;

	always @* begin
		rport1_addr = 0;
		rport2_addr = 0;
		rport3_addr = 0;

		rs1_rdata = 'bx; 
		rs2_rdata = 'bx; 
		rs3_rdata = 'bx; 

		if (RPORTS == 1) begin
			if (next_pcpi_valid) begin
				rport1_addr = cur_insn[19:15];
			end else if (!pcpi_rs2_vreg) begin
				rport1_addr = cur_insn[24:20];
			end else begin
				rport1_addr = cur_insn[31:27];
			end

			if (!pcpi_rs2_vreg) begin
				rs1_rdata = rport1_data;
				rs2_rdata = rport1_data;
				rs3_rdata = rport1_data;
			end else if (!pcpi_rs3_vreg) begin
				rs1_rdata = rs1_reg;
				rs2_rdata = rport1_data;
				rs3_rdata = rport1_data;
			end else begin
				rs1_rdata = rs1_reg;
				rs2_rdata = rs2_reg;
				rs3_rdata = rport1_data;
			end
		end

		if (RPORTS == 2) begin
			if (next_pcpi_valid) begin
				rport1_addr = cur_insn[19:15];
				rport2_addr = cur_insn[24:20];
			end else begin
				rport1_addr = cur_insn[31:27];
			end

			if (!pcpi_rs3_vreg) begin
				rs1_rdata = rport1_data;
				rs2_rdata = rport2_data;
				rs3_rdata = rport1_data;
			end else begin
				rs1_rdata = rs1_reg;
				rs2_rdata = rs2_reg;
				rs3_rdata = rport1_data;
			end
		end

		if (RPORTS == 3) begin
			rport1_addr = cur_insn[19:15];
			rport2_addr = cur_insn[24:20];
			rport3_addr = cur_insn[31:27];

			rs1_rdata = rport1_data;
			rs2_rdata = rport2_data;
			rs3_rdata = rport3_data;
		end
	end

	reg [15:0] rvc;
	reg [1:0] rvc_op;
	reg [2:0] rvc_f3;
	reg [3:0] rvc_f4;
	reg [5:0] rvc_f6;
	reg [1:0] rvc_f2;
	reg [4:0] rvc_rs1;
	reg [4:0] rvc_rs2;
	reg [4:0] rvc_rs1_prime;
	reg [4:0] rvc_rs2_prime;

	always @* begin
		next_pc = pc;
		next_insn_buf = insn_buf;
		next_insn_buf_vld = insn_buf_vld;

		if (mem_valid && mem_ready && !mem_kill_reg) begin
			for (i = 0; i < ibuf_len/16-1; i = i+1) begin
				if (next_insn_buf_vld == i)
					next_insn_buf[16*i +: 32] = {mem_rdata[31:16],
							(mem_addr_reg[1] && IALIGN == 16) ? mem_rdata[31:16] : mem_rdata[15:0]};
			end
			next_insn_buf_vld = next_insn_buf_vld + (mem_addr_reg[1] ? 1 : 2);
		end

		next_mem_addr = next_pc + 2*next_insn_buf_vld;

		next_pcpi_valid = 0;
		next_pcpi_insn = next_insn_buf;
		next_pcpi_prefix = next_insn_buf;

		rvc = next_insn_buf;
		rvc_op = rvc[1:0];
		rvc_f3 = rvc[15:13];
		rvc_f4 = rvc[15:12];
		rvc_f6 = rvc[15:10];
		rvc_f2 = rvc[6:5];
		rvc_rs1 = rvc[11:7];
		rvc_rs2 = rvc[6:2];
		rvc_rs1_prime = {2'b 01, rvc[9:7]};
		rvc_rs2_prime = {2'b 01, rvc[4:2]};

		if (next_insn_buf[1:0] != 3 && IALIGN == 16) begin
			(* parallel_case, full_case *)
			case (rvc_op)
				// RVC, Quadrant 0
				0: begin
					(* parallel_case *)
					case (1)
						rvc_f3 == 3'b 000 && rvc[12:5]: // C.ADDI4SPN
							next_pcpi_insn = {2'b 00, rvc[10:7], rvc[12:11], rvc[5], rvc[6], 2'b00, 5'd 2, 3'b 000, rvc_rs2_prime, 7'b 0010011};
						rvc_f3 == 3'b 010: // C.LW
							next_pcpi_insn = {5'b 00000, rvc[5], rvc[12], rvc[11:10], rvc[6], 2'b 00, rvc_rs1_prime, 3'b 010, rvc_rs2_prime, 7'b 0000011};
						rvc_f3 == 3'b 110: // C.SW
							next_pcpi_insn = {5'b 00000, rvc[5], rvc[12], rvc_rs2_prime, rvc_rs1_prime, 3'b 010, rvc[11:10], rvc[6], 2'b 00, 7'b 0100011};
					endcase
				end
				// RVC, Quadrant 1
				1: begin
					(* parallel_case *)
					case (1)
						rvc_f3 == 3'b 000: // C.NOP, C.ADDI
							next_pcpi_insn = {{7{rvc[12]}}, rvc[6:2], rvc_rs1, 3'b 000, rvc_rs1, 7'b 0010011};
						rvc_f3 == 3'b 001 && XLEN == 32: // C.JAL
							next_pcpi_insn = {rvc[12], rvc[8], rvc[10:9], rvc[6], rvc[7], rvc[2], rvc[11],
									rvc[5], rvc[4], rvc[3], {9{rvc[12]}}, 5'd 1, 7'b 1101111};
						rvc_f3 == 3'b 010: // C.LI
							next_pcpi_insn = {{7{rvc[12]}}, rvc[6:2], 5'd 0, 3'b 000, rvc_rs1, 7'b 0010011};
						rvc_f3 == 3'b 011 && rvc_rs1 == 2 && {rvc[12], rvc[6:2]}: // C.ADDI16SP
							next_pcpi_insn = {{3{rvc[12]}}, rvc[4:3], rvc[5], rvc[2], rvc[6], 4'b 0000, 5'd 2, 3'b 000, rvc_rs1, 7'b 0010011};
						rvc_f3 == 3'b 011 && rvc_rs1 != 2 && {rvc[12], rvc[6:2]}: // C.LUI
							next_pcpi_insn = {{15{rvc[12]}}, rvc[6:2], rvc_rs1, 7'b 0110111};
						rvc_f3 == 3'b 100 && (XLEN == 64 || !rvc[12]) && rvc[11:10] == 2'b 00: // C.SRLI
							next_pcpi_insn = {6'b 000000, rvc[12], rvc[6:2], rvc_rs1_prime, 3'b 101, rvc_rs1_prime, 7'b 0010011};
						rvc_f3 == 3'b 100 && (XLEN == 64 || !rvc[12]) && rvc[11:10] == 2'b 01: // C.SRAI
							next_pcpi_insn = {6'b 010000, rvc[12], rvc[6:2], rvc_rs1_prime, 3'b 101, rvc_rs1_prime, 7'b 0010011};
						rvc_f3 == 3'b 100 && rvc[11:10] == 2'b 10: // C.ANDI
							next_pcpi_insn = {{7{rvc[12]}}, rvc[6:2], rvc_rs1_prime, 3'b 111, rvc_rs1_prime, 7'b 0010011};
						rvc_f6 == 6'b 100_0_11 && rvc_f2 == 2'b 00: // C.SUB
							next_pcpi_insn = {7'b 0100000, rvc_rs2_prime, rvc_rs1_prime, 3'b 000, rvc_rs1_prime, 7'b 0110011};
						rvc_f6 == 6'b 100_0_11 && rvc_f2 == 2'b 01: // C.XOR
							next_pcpi_insn = {7'b 0000000, rvc_rs2_prime, rvc_rs1_prime, 3'b 100, rvc_rs1_prime, 7'b 0110011};
						rvc_f6 == 6'b 100_0_11 && rvc_f2 == 2'b 10: // C.OR
							next_pcpi_insn = {7'b 0000000, rvc_rs2_prime, rvc_rs1_prime, 3'b 110, rvc_rs1_prime, 7'b 0110011};
						rvc_f6 == 6'b 100_0_11 && rvc_f2 == 2'b 11: // C.AND
							next_pcpi_insn = {7'b 0000000, rvc_rs2_prime, rvc_rs1_prime, 3'b 111, rvc_rs1_prime, 7'b 0110011};
						rvc_f3 == 3'b 101: // C.J
							next_pcpi_insn = {rvc[12], rvc[8], rvc[10:9], rvc[6], rvc[7], rvc[2], rvc[11],
									rvc[5], rvc[4], rvc[3], {9{rvc[12]}}, 5'd 0, 7'b 1101111};
						rvc_f3 == 3'b 110: // C.BEQZ
							next_pcpi_insn = {{4{rvc[12]}}, rvc[6:5], rvc[2], 5'd 0, rvc_rs1_prime, 3'b 000, rvc[11:10], rvc[4:3], rvc[12], 7'b 1100011};
						rvc_f3 == 3'b 111: // C.BNEZ
							next_pcpi_insn = {{4{rvc[12]}}, rvc[6:5], rvc[2], 5'd 0, rvc_rs1_prime, 3'b 001, rvc[11:10], rvc[4:3], rvc[12], 7'b 1100011};
					endcase
				end
				// RVC, Quadrant 2
				2: begin
					(* parallel_case *)
					case (1)
						rvc_f3 == 3'b 000 && (XLEN == 64 || !rvc[12]): // C.SLLI
							next_pcpi_insn = {6'b 000000, rvc[12], rvc[6:2], rvc_rs1, 3'b 001, rvc_rs1, 7'b 0010011};
						rvc_f3 == 3'b 010 && rvc_rs1: // C.LWSP
							next_pcpi_insn = {4'b 0000, rvc[3:2], rvc[12], rvc[6:4], 2'b 00, 5'd 2, 3'b 010, rvc_rs1, 7'b 0000011};
						rvc_f4 == 4'b 100_0 && rvc_rs1 && !rvc_rs2: // C.JR
							next_pcpi_insn = {12'd 0, rvc_rs1, 3'b 000, 5'd 0, 7'b 1100111};
						rvc_f4 == 4'b 100_0 && rvc_rs2: // C.MV
							next_pcpi_insn = {7'd 0, rvc_rs2, 5'd 0, 3'b 000, rvc_rs1, 7'b 0110011};
						rvc_f4 == 4'b 100_1 && !rvc_rs2: // C.JALR
							next_pcpi_insn = {12'd 0, rvc_rs1, 3'b 000, 5'd 1, 7'b 1100111};
						rvc_f4 == 4'b 100_1 && rvc_rs2: // C.ADD
							next_pcpi_insn = {7'd 0, rvc_rs2, rvc_rs1, 3'b 000, rvc_rs1, 7'b 0110011};
						rvc_f3 == 3'b 110: // C.SWSP
							next_pcpi_insn = {4'b 0000, rvc[8:7], rvc[12], rvc_rs2, 5'd 2, 3'b 010, rvc[11:9], 2'b 00, 7'b 0100011};
					endcase
				end
			endcase
		end

		if (!pcpi_valid || pcpi_ready) begin
			(* parallel_case *)
			case (1)
				next_insn_buf_vld >= 2 && (next_insn_buf[1:0] == 3 || IALIGN == 32): begin
					next_pc = next_pc + 4;
					next_insn_buf_vld = next_insn_buf_vld - 2;
					next_insn_buf = next_insn_buf >> 32;
					next_pcpi_valid = 1;
				end
				next_insn_buf_vld >= 1 && (next_insn_buf[1:0] != 3 && IALIGN == 16): begin
					next_pc = next_pc + 2;
					next_insn_buf_vld = next_insn_buf_vld - 1;
					next_insn_buf = next_insn_buf >> 16;
					next_pcpi_valid = 1;
				end
			endcase
		end
	end

	assign decode_valid = next_pcpi_valid && !(pcpi_valid && pcpi_ready && pcpi_br_enable);
	assign decode_insn = next_pcpi_insn;
	assign decode_prefix = next_pcpi_prefix;

	reg awb_ready_reg;
	assign awb_ready = awb_ready_reg;

	always @* begin
		wport_addr = 0;
		wport_data = pcpi_wb_data;
		awb_ready_reg = 0;

		if (pcpi_valid && pcpi_ready && pcpi_wb_write && pcpi_insn[11:7]) begin
			wport_addr = pcpi_insn[11:7];
		end else begin
			awb_ready_reg = 1;
			if (awb_valid && awb_addr) begin
				wport_addr = awb_addr;
				wport_data = awb_data;
			end
		end
	end

	always @(posedge clock) begin
		pc <= next_pc;
		insn_buf <= next_insn_buf;
		insn_buf_vld <= next_insn_buf_vld;

		if (mem_valid && mem_ready) begin
			mem_kill_reg <= 0;
		end

		if (!mem_valid || mem_ready) begin
			mem_valid_reg <= next_insn_buf_vld < ibuf_len/16 - 1;
			mem_addr_reg <= next_mem_addr;
		end

		if (pcpi_valid && pcpi_ready) begin
			pcpi_valid_reg <= 0;
			if (pcpi_wb_async && pcpi_insn[11:7])
				scoreboard[~pcpi_insn[11:7]] <= 1;
			if (pcpi_br_enable) begin
				mem_kill_reg <= 1;
				pc <= pcpi_br_nextpc;
				insn_buf_vld <= 0;
			end
		end

		if (next_pcpi_valid && !(pcpi_valid && pcpi_ready && pcpi_br_enable)) begin
			// if (next_pcpi_prefix[1:0] != 3) begin
			// 	$display("--C--");
			// 	$display(".half 0x%04x", next_pcpi_prefix);
			// 	$display(".word 0x%08x", next_pcpi_insn);
			// end
			pcpi_valid_reg <= 1;
			pcpi_insn_reg <= next_pcpi_insn;
			pcpi_prefix_reg <= next_pcpi_prefix;
			pcpi_pc_reg <= pc;
		end

		if (wport_addr) begin
			scoreboard[~wport_addr] <= 0;
		end

		if (reset) begin
			mem_kill_reg <= 0;
			insn_buf_vld <= 0;
			mem_valid_reg <= 0;
			pcpi_valid_reg <= 0;
			scoreboard <= 0;
			pc <= rvec;
		end
	end
endmodule
