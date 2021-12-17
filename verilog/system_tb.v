`include "system.v"

module system_tb;

wire rx, tx;
reg clk = 0;

system #(.UART_BUAD(20000000)) sys(
	.CLK100MHZ(clk),
	.rx(rx),
	.tx(tx)
);

always #5
	clk = ~clk;

initial begin
	$dumpfile("system.vcd");
	$dumpvars(0, system_tb);
	#10000 $finish;
end

endmodule
