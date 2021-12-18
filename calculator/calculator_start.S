# .text:
.text
.globl _start
_start:
	li	sp, 0x7000
	li	s0, 0x7000
	j	main
