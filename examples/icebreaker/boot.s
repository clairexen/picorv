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

start:
li ra, 0
li sp, 0
li gp, 0
li tp, 0
li t0, 0
li t1, 0
li t2, 0
li s0, 0
li s1, 0
li a0, 0
li a1, 0
li a2, 0
li a3, 0
li a4, 0
li a5, 0
li a6, 0
li a7, 0
li s2, 0
li s3, 0
li s4, 0
li s5, 0
li s6, 0
li s7, 0
li s8, 0
li s9, 0
li s10, 0
li s11, 0
li t3, 0
li t4, 0
li t5, 0
li t6, 0
li sp, 0x00020000-16
sw zero, 0(sp)
sw zero, 4(sp)
sw zero, 8(sp)
sw zero, 12(sp)
li t0, 0x01100000
1:
lw a0, 0(t0)
lw a1, 4(t0)
addi t0, t0, 8
beqz a0, 3f
2:
lw a2, 0(t0)
addi t0, t0, 4
sw a2, 0(a1)
addi a1, a1, 4
addi a0, a0, -4
beqz a0, 1b
j 2b
3:
jalr ra, 0(a1)
4:
j 4b
