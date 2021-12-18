//
//
// riscv32-unknown-elf-elf2hex --input calculator.o --output demo/calculator.vh --bit-width 32
//
unsigned char *uart_dev = (unsigned char*) 0x80000000;
#define UART_WRITE_BUF_OFFSET 0x20

void uart_write(const char *c, int len);
unsigned int strlen(const char *c);

void _start()
{
	const char *hello = "Hello World!";
	uart_write(hello, strlen(hello));
}

void uart_write(const char *c, int len) 
{
	while (len) {
		unsigned char tx_ctrl = *uart_dev;
		unsigned char tx_cur = (tx_ctrl & 0xF0) >> 4;
		unsigned char tx_ptr = tx_ctrl & 0x0F;
		unsigned char tx_ptr_n = (tx_ptr + 1) & 0x0F;
		if (tx_ptr_n == tx_cur) //Overrun
			continue;
		*(uart_dev + UART_WRITE_BUF_OFFSET + tx_ptr) = *c;
		*uart_dev = tx_ptr_n;
		c++;
		len--;
	}
}

unsigned int strlen(const char *c)
{
	unsigned int l = 0;
	while (c) {
		l++;
		c++;
	}
	return l;
}

