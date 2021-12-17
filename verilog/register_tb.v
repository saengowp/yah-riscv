`include "register.v"

module register_tb;

reg [4:0] r1, r2, r_write;
reg [31:0] data_write;
reg clk, enable_write;
wire [31:0] out_r1, out_r2;

register r(
	.r1(r1),
	.r2(r2),
	.r_write(r_write),
	.data_write(data_write),
	.enable_write(enable_write),
	.out_r1(out_r1),
	.out_r2(out_r2),
	.clk(clk)
);

initial begin
	r1 = 1;
	r2 = 2;

	clk = 0;
	r_write = 1;
	data_write = 'hAA;
	enable_write = 1;
	#5
	clk = 1;
	#5
	clk = 0;
	$display("Written r1 AA: %d", out_r1 == 'hAA);
	data_write = 'hBB;
	r_write = 2;
	#5
	clk = 1;
	#5
	clk = 0;
	$display("Written r2 BB: %d", out_r2 == 'hBB);
	r1 = 0;
	r2 = 0;
	#1 $display("Check r1 and r2 when zero: %d", out_r1 == 0 && out_r2 == 0);
	r1 = 2;
	r2 = 1;
	#1 $display("Check r1 and r2 persist: %d", out_r1 == 'hBB && out_r2 == 'hAA);
	$finish;
end

endmodule
