`include "system.v"

module system_tb;

wire rx, tx;
reg clk = 0;

system #(.UART_BUAD(20000000)) sys(
	.CLK100MHZ(clk),
	.rx(rx),
	.tx(tx)
);

reg [5:0] u_addr;
reg [31:0] u_din;
wire [31:0] u_dout;
reg u_we = 0;
uart #(.UART_PERIOD(100000000/20000000)) u(
	.rx(1'b1),
	.tx(rx),
	.addr(u_addr),
	.data_in(u_din),
	.data_out(u_dout),
	.write_enable(u_we),
	.clk(clk)
);

always #5
	clk = ~clk;

initial begin
	$dumpfile("system.vcd");
	$dumpvars(0, system_tb);
	#100000 
	u_addr = 'h20;
	u_din = 'h30663066;
	u_we = 1;
	#10
	u_addr = 'h24;
	u_din = 'h30663066;
	#10;
	u_addr = 'h28;
	u_din = 'h4A;
	#10;
	u_addr = 0;
	u_din = 9;
	#10;
	u_we = 0;
	#500000
	$finish;
end

endmodule
