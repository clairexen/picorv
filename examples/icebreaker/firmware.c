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

#include <stdint.h>
#include <stdio.h>

#define REG_LEDS  (*((volatile uint8_t*)0x00000400))
#define REG_BTNS  (*((volatile uint8_t*)0x00000401))

#define REG_SPI   (*((volatile uint32_t*)0x00000404))

#define REG_PM1A_DI  (*((volatile uint8_t*)0x00000408))
#define REG_PM1A_DO  (*((volatile uint8_t*)0x00000409))
#define REG_PM1A_OE  (*((volatile uint8_t*)0x0000040a))

#define REG_PM1B_DI  (*((volatile uint8_t*)0x0000040c))
#define REG_PM1B_DO  (*((volatile uint8_t*)0x0000040d))
#define REG_PM1B_OE  (*((volatile uint8_t*)0x0000040e))

#define REG_UARTDIV (*((volatile uint32_t*)0x00000410))
#define REG_UARTDAT (*((volatile uint32_t*)0x00000414))

extern void pause(int cnt);

__asm__(
"pause:\n"
"1: addi a0, a0, -1\n"
"bgtz a0, 1b\n"
"ret\n"
);

// 7 SEGMENT:
//
//  s[7]=0    s[7]=1
//
//   --0--     --0--
//  |     |   |     |
//  5     1   5     1
//  |     |   |     |
//   --6--     --6--
//  |     |   |     |
//  4     2   4     2
//  |     |   |     |
//   --3--     --3--

void hexlo(int val)
{
#define s(n) &~(1<<n)
	switch (val & 15)
	{
	case   0: REG_PM1A_DO = 255 s(0)s(1)s(2)s(3)s(4)s(5)    ; break;
	case   1: REG_PM1A_DO = 255     s(1)s(2)                ; break;
	case   2: REG_PM1A_DO = 255 s(0)s(1)    s(3)s(4)    s(6); break;
	case   3: REG_PM1A_DO = 255 s(0)s(1)s(2)s(3)        s(6); break;
	case   4: REG_PM1A_DO = 255     s(1)s(2)        s(5)s(6); break;
	case   5: REG_PM1A_DO = 255 s(0)    s(2)s(3)    s(5)s(6); break;
	case   6: REG_PM1A_DO = 255 s(0)    s(2)s(3)s(4)s(5)s(6); break;
	case   7: REG_PM1A_DO = 255 s(0)s(1)s(2)                ; break;
	case   8: REG_PM1A_DO = 255 s(0)s(1)s(2)s(3)s(4)s(5)s(6); break;
	case   9: REG_PM1A_DO = 255 s(0)s(1)s(2)s(3)    s(5)s(6); break;
	case 0xa: REG_PM1A_DO = 255 s(0)s(1)s(2)s(3)s(4)    s(6); break;
	case 0xb: REG_PM1A_DO = 255         s(2)s(3)s(4)s(5)s(6); break;
	case 0xc: REG_PM1A_DO = 255             s(3)s(4)    s(6); break;
	case 0xd: REG_PM1A_DO = 255     s(1)s(2)s(3)s(4)    s(6); break;
	case 0xE: REG_PM1A_DO = 255 s(0)        s(3)s(4)s(5)s(6); break;
	case 0xF: REG_PM1A_DO = 255 s(0)            s(4)s(5)s(6); break;
	}
#undef s
}

void hexhi(int val)
{
#define s(n) &~(1<<n)
	switch (val & 15)
	{
	case   0: REG_PM1A_DO = 127 s(0)s(1)s(2)s(3)s(4)s(5)    ; break;
	case   1: REG_PM1A_DO = 127     s(1)s(2)                ; break;
	case   2: REG_PM1A_DO = 127 s(0)s(1)    s(3)s(4)    s(6); break;
	case   3: REG_PM1A_DO = 127 s(0)s(1)s(2)s(3)        s(6); break;
	case   4: REG_PM1A_DO = 127     s(1)s(2)        s(5)s(6); break;
	case   5: REG_PM1A_DO = 127 s(0)    s(2)s(3)    s(5)s(6); break;
	case   6: REG_PM1A_DO = 127 s(0)    s(2)s(3)s(4)s(5)s(6); break;
	case   7: REG_PM1A_DO = 127 s(0)s(1)s(2)                ; break;
	case   8: REG_PM1A_DO = 127 s(0)s(1)s(2)s(3)s(4)s(5)s(6); break;
	case   9: REG_PM1A_DO = 127 s(0)s(1)s(2)s(3)    s(5)s(6); break;
	case 0xa: REG_PM1A_DO = 127 s(0)s(1)s(2)s(3)s(4)    s(6); break;
	case 0xb: REG_PM1A_DO = 127         s(2)s(3)s(4)s(5)s(6); break;
	case 0xc: REG_PM1A_DO = 127             s(3)s(4)    s(6); break;
	case 0xd: REG_PM1A_DO = 127     s(1)s(2)s(3)s(4)    s(6); break;
	case 0xE: REG_PM1A_DO = 127 s(0)        s(3)s(4)s(5)s(6); break;
	case 0xF: REG_PM1A_DO = 127 s(0)            s(4)s(5)s(6); break;
	}
#undef s
}

int hexout(int val)
{
	int lo = (val >> 0) & 15;
	int hi = (val >> 4) & 15;

	for (int i = 0; i < 100; i++)
	{
		hexlo(lo);
		pause(1000);
		hexhi(hi);
		pause(1000);
	}

	REG_PM1A_DO = 255;
}

int decout(int val)
{
	int lo = val % 10;
	int hi = (val / 10) % 10;

	for (int i = 0; i < 100; i++)
	{
		hexlo(lo);
		pause(1000);
		hexhi(hi);
		pause(1000);
	}

	REG_PM1A_DO = 255;
}

int main()
{
	REG_UARTDIV = 104;
	REG_UARTDAT = 'B';
	printf("ooting.\n");

	REG_PM1A_DO = 255;
	REG_PM1A_OE = 255;

	for (int i = 1;; i++) {
		REG_LEDS = 0x60 ^ (1 << (i&7));
		if (REG_BTNS == 8)
			decout(i);
		else
			hexout(i);
	}

	return 0;
}
