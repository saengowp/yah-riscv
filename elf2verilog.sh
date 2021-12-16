#! /bin/bash

riscv32-unknown-elf-objcopy \
	-O verilog \
	-j .text.init \
	--set-start=0 \
	--reverse-bytes=4 \
	--verilog-data-width=4 \
	$1 \
	$2
