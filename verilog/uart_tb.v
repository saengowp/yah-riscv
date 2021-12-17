`include "uart.v"

module uart_tb;

wire tx1rx2, tx2rx1;
reg [5:0] addr1, addr2;
wire [31:0] out1, out2;
reg [31:0] in1, in2;
reg write1, write2;
reg clk = 0;

uart #(.UART_PERIOD(5)) u1(
	.tx(tx1rx2),
	.rx(tx2rx1),
	.addr(addr1),
	.data_out(out1),
	.data_in(in1),
	.write_enable(write1),
	.clk(clk)
);

uart #(.UART_PERIOD(5)) u2(
	.tx(tx2rx1),
	.rx(tx1rx2),
	.addr(addr2),
	.data_out(out2),
	.data_in(in2),
	.write_enable(write2),
	.clk(clk)
);

always #5 clk = ~clk;

initial begin
$dumpfile("test.vcd");
$dumpvars(0, uart_tb);
addr1 = 'h20;
in1 = 'h00CCBBAA;
write1 = 1;
write2 = 0;
#10
addr1 = 'h24;
in1 = 'hABABABAB;
#10
addr1 = 0;
in1 = 5;
#10
write1 = 0;
#3000 // 10 unit/clk * 5 clk/bit * 10 bit/word * 4 word
addr2 = 0;
#10
addr2 = 'h10;
#10
$finish;
end

endmodule
