`include "pc.v"

module pc_tb;

reg fetch_unit_valid = 0;
reg [1:0] jmp_op = 0;
reg [31:0] next_addr = 0;
reg valid = 0;
reg cmp = 0;
reg fault = 0;

reg clk = 0;

wire [31:0] addr;

pc p(
	.fetch_unit_valid(fetch_unit_valid),
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
fetch_unit_valid = 0;
#10 $display("T: NOP when FU not ready: %d", addr == 0);
fetch_unit_valid = 1;
#10 $display("T: Increment when FU ready and no incoming signal: %d", addr == 4);
valid = 1;
jmp_op = 0;
#10 $display("T: Increment when FU ready and incoming NOP: %d", addr == 8);
next_addr = 20;
jmp_op = 1;
#10 $display("T: Jump when incoming is JMP: %d", addr == 20);
next_addr = 40;
jmp_op = 2;
cmp = 0;
#10 $display("T: Ignore when incoming JMP does not met condition: %d", addr == 20);
cmp = 1;
#10 $display("T: Jump when JMP does not met condition: %d", addr == 40);
fetch_unit_valid = 1;
valid = 0;
#10 $display("T: Continue increment: %d", addr == 44);
fetch_unit_valid = 0;
#10 $display("T: Stall: %d", addr == 44);
next_addr = 1;
valid = 1;
cmp = 0;
jmp_op = 2;
#10 $display("T: No fault when condition is not met: %d", addr == 44);
cmp = 1;
#10 $display("T: Fault when unaligned instruction addr: %d", addr == 0);

$finish;
end


endmodule
