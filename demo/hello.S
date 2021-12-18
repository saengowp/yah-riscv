# Hello Test Program

# riscv32-unknown-elf-gcc hello.S -o hello.o -nostdlib -Wl,--section-start=.text=0 -march=rv32i -mabi=ilp32
# riscv32-unknown-elf-elf2hex --bit-width 32 --input hello.o --output rom.vh
# riscv32-unknown-elf-objdump -S -D hello.o

.equ UART_DEV_ADDR, 0x80000000

.text
.globl _start
_start:
	lui	x1, %hi(UART_DEV_ADDR)	# Set UART_DEV
hello:
	lui	x2, %hi(hello_str)	# char ptr
	addi	x2, x2, %lo(hello_str)

hello_loop:
	lb	x3, 0(x2)		# character for hello
	beqz 	x3, hello		# check for null terminate

	lbu 	x4, 0x0(x1)		# Read write ptr
	andi 	x4, x4, 0x0F
	add 	x5, x4, x1		# Calculate write buf addr
	addi 	x5, x5, 0x20
	sb 	x3, 0(x5)		# Push to buffer
	addi 	x4, x4, 1		# Increment write ptr
	andi	x4, x4, 0xF		# Wrap around
	sb	x4, 0x0(x1)		# Request transmit
wait_transmit:
	lbu	x5, 0x0(x1)		# Get transmit status
	andi	x5, x5, 0xF0
	srli	x5, x5, 4
	bne	x4, x5, wait_transmit	# Continue waiting

	addi	x2, x2, 1		# Increment char ptr
	j	hello_loop

.data
hello_str:
	.string "Hello World\r\n"
