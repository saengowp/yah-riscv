SECTIONS {
	. : { calculator_start.o (.text) }
	.text : { *(.text) }
}
