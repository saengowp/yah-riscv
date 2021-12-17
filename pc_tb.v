`include "pc.v"

module pc_tb;

reg stall = 0;
reg [1:0] jmp_op = 0;
reg [31:0] next_addr = 0;
reg valid = 0;
reg cmp = 0;
reg fault = 0;
reg clk = 0;

wire [31:0] addr;

pc p(
	.stall(stall),
	.jmp_op(jmp_op),
	.next_addr(next_addr),
	.valid(valid),
	.cmp(cmp),
	.fault(fault),
	.clk(clk),
	.addr(addr)
);

always #5 clk = ~clk;

initial begin
$dumpfile("test.vcd");
$dumpvars(0, pc_tb);

$display("PC Test Suite");
stall = 1;
#10 $display("Stall: %d", addr == 0);
stall = 0;
#10 $display("No Stall: %d", addr == 4);
valid = 1;
jmp_op = 0;
#10 $display("JMP NOP: %d", addr == 8);
jmp_op = 1;
next_addr = 12;
#10 $display("JMP : %d", addr == 12);
jmp_op = 2;
next_addr = 80;
cmp = 0;
#10 $display("JMP COND FALSE: %d", addr == 16);
cmp = 1;
#10 $display("JMP COND TRUE: %d", addr == 80);
next_addr = 21;
#10 $display("JMP MISALLIGNED: %d", addr == 0);
stall = 1;
valid = 1;
jmp_op = 1;
next_addr = 12;
#10 $display("JMP even when stall: %d", addr == 12);
$finish;
end


endmodule
