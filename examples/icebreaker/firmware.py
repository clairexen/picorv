#!/usr/bin/env python3
#
#  PicoRV -- A Small and Extensible RISC-V Processor
#
#  Copyright (C) 2019  Claire Wolf <claire@symbioticeda.com>
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

import sys

block_start = None
block_data = list()
flash_data = list()

def block_fin(start):
    global block_start, block_data, flash_data
    if block_start is not None:
        assert 0x10000 <= block_start
        assert block_start + len(block_data) <= 0x30000
        while len(block_data) % 4 != 0:
            block_data.append(0)
        if len(block_data) != 0:
            flash_data += [
                (len(block_data) >>  0) & 255,
                (len(block_data) >>  8) & 255,
                (len(block_data) >> 16) & 255,
                (len(block_data) >> 24) & 255,
                (block_start >>  0) & 255,
                (block_start >>  8) & 255,
                (block_start >> 16) & 255,
                (block_start >> 24) & 255,
            ] + block_data
    else:
        assert len(block_data) == 0
    block_start = start
    block_data = list()

for line in sys.stdin:
    line = line.split()
    if line[0].startswith("@"):
        block_fin(int(line[0][1:], 16))
        continue
    block_data += [int(v, 16) for v in line]

block_fin(None)

entry = int(sys.argv[1], 16)

flash_data += [
    0, 0, 0, 0,
    (entry >>  0) & 255,
    (entry >>  8) & 255,
    (entry >> 16) & 255,
    (entry >> 24) & 255,
] + block_data

with open("firmware.hex", "wt") as f:
    print("@100000", file=f)
    print(" ".join(["%02x" % v for v in flash_data]), file=f)

with open("firmware.bin", "wb") as f:
    f.write(bytes(flash_data))
