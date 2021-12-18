# YAH-RISCV BootLoader
# This ROM listen to space-delimited hex string from UART
# then echo the character and copy it to a memory location
# If J is pressed, the system would jump to that location.

# riscv32-unknown-elf-gcc demo/boot.S -o boot.o -march=rv32i -mabi=ilp32 -nostdlib -Wl,-Ttext=0  -Wl,-Tdata=0x200

.equ UART_BASE_ADDR, 0x80000000

.text
.globl _start
_start:
	# Global register
	lla	sp, stack_mem
	
	# Print start_msg
	la	a0, start_msg
	jal	print_str

	li	s1, 0x2000		# s1 = Mem location
	li	s2, 0			# s2 = current byte
	li	s3, 32			# Number of valid bit needed in s2
_start_read:
	jal	uart_read		# Read character
	mv	s4, a0			# Current character

	jal	uart_write		# Echo the character

	# Switch case on s4
	# Ignore white space
	li	a0, ' '
	beq	a0, s4, _start_read
	li	a0, '\r'
	beq	a0, s4, _start_read
	li	a0, '\n'
	beq	a0, s4, _start_read
	# Write hex
	li	a1, 10
	addi	a0, s4, -'0'
	bgtu	a0, a1, _start_read_non_numeric	# Not numeric
	j	_start_read_is_hex		# Write a0
_start_read_non_numeric:
	li	a1, 5
	addi	a0, s4, -'a'
	bgtu	a0, a1, _start_read_not_hex	# Not a-f either
	addi	a0, a0, 10
	j	_start_read_is_hex
_start_read_is_hex:
	slli	s2, s2, 4			# Append to current byte
	or	s2, s2, a0
	addi	s3, s3, -4
	bnez	s3, _start_read			# Word not full, go back to read
	sw	s2, 0(s1)			# Write word
	addi	s1, s1, 4
	li	s3, 32
	la	a0, word_written_msg		# Print ack
	jal	print_str
	j	_start_read
_start_read_not_hex:
	li	a0, 'J'
	bne	a0, s4, _start_read_invalid_char
	la	a0, jump_msg
	jal	print_str
	li	a0, 0x2000
	jr	a0
_start_read_invalid_char:
	la	a0, invalid_char_msg
	jal	print_str
	j	_start_read
	

print_str:
	# Print str in a0 location, a0 must be non-null
	sw	ra, 0(sp)		# Push ra, s1
	sw	s1, 4(sp)
	addi	sp, sp, 4*2

	mv	s1, a0			# String ptr
print_str_loop:
	lb	a0, 0(s1)		# a0 = char
	beqz	a0, print_str_done	# Is a0 = null terminate
	jal	uart_write
	addi	s1, s1, 1		# Increment string ptr
	j	print_str_loop
print_str_done:
	addi	sp, sp, -4*2		# Pop s1, ra
	lw	ra, 0(sp)
	lw	s1, 4(sp)
	ret


uart_read:
	# Read a single char from uart. blocking. returning on a0
	sw	ra, 0(sp)		# Push ra
	addi	sp, sp, 4
uart_read_wait:
	jal	ra, uart_control	# Call uart_control
	la	t3, uart_c_read_head	# t3 = uart_c_read_head addr
	lw	t2, 0(t3)		# Get last read head
	beq	a0, t2, uart_read_wait	# Try again if no read
	addi	t1, a3, 0x10		# t1 = read buffer location
	add	t1, t1, t2
	lbu	a0, 0(t1)			# a0 = new character
	addi	t2, t2, 1		# increment current read head
	andi	t2, t2, 0xF
	sw	t2, 0(t3)		# Save uart_c_read_head
	addi	sp, sp, -4		# Pop ra
	lw	ra, 0(sp)			
	ret

uart_write:
	# Write a single char in register a0 to uart
	# save a0
	sw	ra, 0(sp)		# Push ra, a0
	sw	a0, 4(sp)
	addi	sp, sp, 4*2

	jal	ra, uart_control

	addi	sp, sp, -4		# Pop a0
	lw	a0, 0(sp)

	addi	t0, a3, 0x20		# t0 = Write buffer ptr
	add	t0, t0, a2
	sb	a0, 0(t0)
	addi	t1, a2, 1		# t1 = incremented write ptr
	sb	t1, 0(a3)
uart_write_wait:
	jal	ra, uart_control
	bne	a1, a2, uart_write_wait # Not yet transmitted

	addi	sp, sp, -4		# Pop ra
	lw	ra, 0(sp)
	ret

uart_control:
	# Read control reg, return a0, a1, a2, a3 = rx_ptr, tx_head, tx_ptr, UART_BASE_ADDR
	lui	a3, %hi(UART_BASE_ADDR)	# a3 = UART_BASE_ADDR
	lw	t0, 0(a3)			# t0 = uart control reg
	mv	a0, t0
	mv	a1, t0
	mv	a2, t0
	srli	a0, a0, 4*2
	srli	a1, a1, 4*1
	andi	a0, a0, 0xF
	andi	a1, a1, 0xF
	andi	a2, a2, 0xF
	ret


	

.data
uart_c_read_head:
	.word 0x0
start_msg:
	.string "YAH-RISCV Core Bootloader\r\nListening to program hex\r\nStarting at 0x2000\r\n"
word_written_msg:
	.string "\r\nWord acknowledged\r\n"
jump_msg:
	.string "\r\nJ Received. Control Transfer...\r\n"
invalid_char_msg:
	.string "Invalid char received\r\n"
stack_mem:
	.word 0x0
