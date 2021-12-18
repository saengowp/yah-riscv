//
// riscv32-unknown-elf-gcc calculator_start.S -o calculator_start.o  -march=rv32i -mabi=ilp32 -nostdlib -T calculator.ld -c
// riscv32-unknown-elf-gcc calculator.c  -o calculator.o -march=rv32i -mabi=ilp32 -nostdlib -T calculator.ld -fpie -static-pie
// riscv32-unknown-elf-elf2hex --input calculator.o --output demo/calculator.vh --bit-width 32
//
unsigned char *uart_dev = (unsigned char*) 0x80000000;
#define UART_WRITE_BUF_OFFSET 0x20
#define UART_READ_BUF_OFFSET 0x10

void uart_write(const char *c, int len);
unsigned int strlen(const char *c);

unsigned int uart_lastread;

# ifndef MOCK_UART

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

char uart_read()
{
	unsigned char rx_ctrl;
	do {
		rx_ctrl = *(uart_dev + 1);
		rx_ctrl &= 0x0F;
	} while (uart_lastread == rx_ctrl);
	char c = *(uart_dev + UART_READ_BUF_OFFSET + uart_lastread);
	uart_lastread = (uart_lastread + 1) & 0x0F;
	return c;
}

#else

#include <stdio.h>

char uart_read()
{
	return getchar();
}

void uart_write(const char *c, int len)
{
	for (int i = 0; i < len; i++)
		putchar(c[i]);
}

#endif

unsigned int strlen(const char *c)
{
	unsigned int l = 0;
	while (*c) {
		l++;
		c++;
	}
	return l;
}

const unsigned int sign_mask = 0xFFFF0000;
#define LEN 8

struct bignum
{
	unsigned int num[LEN];
};

struct bignum zero()
{
	struct bignum n;
	for (int i = 0; i < LEN; i++)
		n.num[i] = 0;
	return n;
}

struct bignum add(struct bignum a, struct bignum b)
{
	struct bignum r = zero();
	for (int i = 0; i < LEN; i++) {
		r.num[i] = a.num[i] + b.num[i] + r.num[i];
		if ((r.num[i] & sign_mask) != 0) {
			r.num[i] &= ~sign_mask;
			if (i != LEN - 1)
				r.num[i+1] = 1;
		}
	}
	return r;
}

struct bignum sub(struct bignum a, struct bignum b)
{
	struct bignum r = zero();
	for (int i = 0; i < LEN; i++) {
		r.num[i] = a.num[i] - b.num[i] - r.num[i];
		if ((r.num[i] & sign_mask) != 0) {
			r.num[i] &= ~sign_mask;
			if (i != LEN - 1)
				r.num[i+1] = 1;
		}
	}
	return r;
}

struct bignum mul(struct bignum a, struct bignum b)
{
	struct bignum r = zero();
	for (int i = 0; i < 16*LEN; i++) {
		if (b.num[i/16] & (1 << (i%16))) {
			r = add(r, a);
		}
		a = add(a, a);
	}
	return r;
}

int isneg(struct bignum a)
{
	return (a.num[LEN-1] << 1) & sign_mask;
}

struct bignum rightshift(struct bignum a)
{
	struct bignum r = a;
	for (int i = 0; i < LEN; i++) {
		r.num[i] >>= 1;
		if (i != LEN - 1)
			r.num[i] |= (r.num[i+1] & 1) << 15;
		else
			r.num[i] |= (r.num[i] & (1 << 14)) << 1;
	}
	return r;
}

struct bignum div(struct bignum a, struct bignum b, struct bignum *rmd)
{
	int nega = isneg(a), negb = isneg(b);
	if (nega)
		a = sub(zero(), a);
	if (negb)
		b = sub(zero(), b);

	struct bignum r = zero();
	struct bignum p = zero();
	p.num[0] = 1;
	for (int i = 0; i < 63; i++) {
		p = add(p, p);
		b = add(b, b);
	}

	for (int i = 63; i >= 0; i--) {
		struct bignum k = sub(a, b);

		if (!isneg(k)) {
			r = add(r, p);
			a = k;
		}
		p = rightshift(p);
		b = rightshift(b);
	}

	*rmd = a;
	return r;
}

int eq(struct bignum a, struct bignum b)
{
	for (int i = 0; i < LEN; i++)
		if (a.num[i] != b.num[i])
			return 0;
	return 1;
}

struct bignum ten;
struct bignum ten3;
struct bignum ten6;
struct bignum ten12;


struct bignum sqrt(struct bignum a)
{
	struct bignum s, e, o;
	s = zero();
	e = ten12;
	o = zero();
	o.num[0] = 1;
	while (!eq(s, e)) {
		struct bignum mid = rightshift(add(s, e));
		struct bignum sq = mul(mid, mid);
		if (isneg(sub(sq, a))) {
			s = add(mid, o);
		}  else if (eq(a, sq)) {
			return mid;
		} else {
			e = mid;
		}
	}
	return s;
}


void tobase10(struct bignum a, char out[12])
{
	struct bignum r;
	for (int i = 0; i < 12; i++) {
		a = div(a, ten, &r);
		out[i] = r.num[0];
	}
}



void print_str(const char *c)
{
	uart_write(c, strlen(c));
}

void print_num(struct bignum a)
{
	if (isneg(a)) {
		print_str("-");
		a = sub(zero(), a);
	} else {
		print_str(" ");
	}

	char out[12];
	tobase10(a, out);

	int z = 1;

	for (int i = 11; i >= 0; i--) {
		if (i == 6)
			z = 0;
		if (out[i] == 0) {
			if (z)
				print_str(" ");
			else
				print_str("0");
		} else {
			z = 0;
			char c;
			c = '0' + out[i];
			uart_write(&c, 1);
		}
		if (i == 6)
			print_str(".");
	}

}

struct calculator_state
{
	int input_u;
	struct bignum x, y, z, t;
	int nanflag;
	int xresult;
	char lastkey;
} cal_state;

void init_calculator() 
{
	ten = zero();
	ten.num[0] = 10;

	ten6 = zero();
	ten6.num[0] = 1;
	for (int i = 0; i < 6; i++) {
		if (i == 3)
			ten3 = ten6;
		ten6 = mul(ten6, ten);
	}

	ten12 = mul(ten6, ten6);

	cal_state.input_u = 0;
	cal_state.x = cal_state.y = cal_state.z = cal_state.t = zero();
	cal_state.nanflag = 0;
	cal_state.xresult = 0;
	cal_state.lastkey = ' ';
}

void calculator_process_input(char c)
{
	int nantrig = 0;
	struct bignum t = zero(), t2;

	if (c >= '0' && c <= '9') {
		cal_state.lastkey = c;
		if (cal_state.xresult) {
			cal_state.xresult = 0;
			cal_state.t = cal_state.z;
			cal_state.z = cal_state.y;
			cal_state.y = cal_state.x;
			cal_state.x = zero();
		}

		int n = c - '0';
		if (cal_state.input_u == 0) {
			cal_state.x = mul(cal_state.x, ten);
			t.num[0] = n;
			cal_state.x = add(cal_state.x, mul(t, ten6));
		} else if (cal_state.input_u != 7) {
			t = ten6;
			for (int i = 0; i < cal_state.input_u; i++) {
				t = div(t, ten, &t2);
			}
			t2 = zero();
			t2.num[0] = n;
			cal_state.x = add(cal_state.x, mul(t, t2));
			cal_state.input_u++;
		}
	} else if (c == '.') {
		if (cal_state.input_u == 0) {
			cal_state.input_u = 1;
			cal_state.lastkey = '.';
		}
	} else if (c == '\r') {
		cal_state.lastkey = ';';
		cal_state.t = cal_state.z;
		cal_state.z = cal_state.y;
		cal_state.y = cal_state.x;
		cal_state.x = zero();
		cal_state.input_u = 0;
	} else if (c == 'r') {
		init_calculator();
	}

	if (c == '+' || c == '-' || c == '*' || c == '/') {
		cal_state.lastkey = c;

		if (c == '+')
			cal_state.x = add(cal_state.x, cal_state.y);
		if (c == '-')
			cal_state.x = sub(cal_state.y, cal_state.x);
		if (c == '*')
			cal_state.x = div(mul(cal_state.x, cal_state.y), ten6, &t);
		if (c == '/')
			cal_state.x = mul(div(cal_state.y, cal_state.x, &t), ten6);
		cal_state.y = cal_state.z;
		cal_state.z = cal_state.t;
		cal_state.xresult = 1;
	}

	if (c == 's') {
		cal_state.x = sqrt(mul(cal_state.x, ten6));
		cal_state.xresult = 1;
	}

	if (cal_state.nanflag && c != '\r' && c != '\n')
		cal_state.nanflag = 0;

	t = cal_state.x;
	if (isneg(t))
		t = sub(zero(), t);
	if (!isneg(sub(t, ten12))) {
		cal_state.nanflag = 1;
		cal_state.x = zero();
	}
		
}

void main()
{
	uart_lastread = 0;
	init_calculator();
	
	

	print_str("YAR-Calculator\r\n");

	while (1) {
		print_str("\x1B [2J\x1B [;H");
		print_str("\x1B [30;46m YAR-Processor Application Demo: RPN Calculator\x1B [0m\n\r");
		print_str("\tT: "); print_num(cal_state.t); print_str("\n\r");
		print_str("\tZ: "); print_num(cal_state.z); print_str("\n\r");
		print_str("\tY: "); print_num(cal_state.y); print_str("\n\r");
		print_str("\t\x1B [37;44mX: \x1B [0m"); print_num(cal_state.x); print_str("\n\r");
		if (cal_state.nanflag)
			print_str("\x1B [37;41mWARNING: Overflow\x1B [0m");
		print_str("\n\r"); 
		print_str("Last Key: "); uart_write(&cal_state.lastkey, 1);
		calculator_process_input(uart_read());
	}
}
