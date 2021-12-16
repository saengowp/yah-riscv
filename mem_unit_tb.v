`include "mem_unit.v"

module mem_unit_tb;

reg [1:0] mem_op;
reg [31:0] alu_out;
reg [31:0] addr_alu_out;
reg [2:0] funct3;
reg [31:0] read_data;

wire [31:0] addr;
wire [31:0] write_data;
wire write_enable;
wire [31:0] out_data;
wire fault;

mem_unit mu(
	.mem_op(mem_op),
	.alu_out(alu_out),
	.addr_alu_out(addr_alu_out),
	.funct3(funct3),
	.addr(addr),
	.read_data(read_data),
	.write_data(write_data),
	.write_enable(write_enable),
	.out_data(out_data),
	.fault(fault)
);

initial begin

$dumpfile("test.vcd");
$dumpvars(0, mem_unit_tb);

$monitor("FAULT: %d", fault);

//NOP
mem_op = 0;
alu_out = 'hAAAA_BBBB;
#1 $display(out_data == 'hAAAA_BBBB);

//LB
mem_op = 1;
funct3 = 'b000;
addr_alu_out = 'hAAAA_0012;
read_data = 'h00FF_0000;
#1 $display(addr == 'hAAAA_0010 && out_data == 'hFFFF_FFFF);

//LBU
funct3 = 'b100;
#1 $display(out_data == 'h0000_00FF);

//LH
funct3 = 1;
addr_alu_out = 'hAAAA_0002;
read_data = 'hFFFF_0000;
#1 $display(addr == 'hAAAA_0000 && out_data == 'hFFFF_FFFF);

//LHU
funct3 = 'b101;
#1 $display(out_data == 'h0000_FFFF);

//LW
funct3 = 'b010;
addr_alu_out = 'hAAAA_0010;
read_data = 'hABCD_AAAA;
#1 $display(addr == 'hAAAA_0010 && out_data == 'hABCD_AAAA);


//SB
mem_op = 2;
funct3 = 'b000;
addr_alu_out = 'hAAAA_0003;
read_data = 'hAAAA_BBBB;
alu_out = 'h0000_FFFF;
#1 $display(addr == 'hAAAA_0000 && write_enable && write_data == 'hFFAA_BBBB);

//SH
addr_alu_out = 'hAAAA_0002;
funct3 = 1;
#1 $display(write_enable && write_data == 'hFFFF_BBBB);

//SW
funct3 = 2;
addr_alu_out = 'hAAAA_0010;
alu_out = 'hABCD_DCBA;
#1 $display(write_enable && addr == 'hAAAA_0010 && write_data == 'hABCD_DCBA);

$finish;
end

endmodule
