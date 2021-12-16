`include "alu_unit.v"

module alu_unit_tb;

reg [2:0] alu_op;
reg [1:0] addr_alu_op;
reg [31:0] imm, rs1, rs2, pc;
reg [2:0] funct3;

wire [31:0] alu_out, addr_alu_out;
wire fault;

alu_unit alu(
	.alu_op(alu_op),
	.addr_alu_op(addr_alu_op),
	.imm(imm),
	.rs1(rs1),
	.rs2(rs2),
	.pc(pc),
	.funct3(funct3),
	.alu_out(alu_out),
	.addr_alu_out(addr_alu_out),
	.fault(fault)
);


initial begin

$monitor("Fault: %d", fault);

alu_op = 0;
imm = 'hFF;
#1 $display("%d", alu_out == 'hFF);

alu_op = 1;
pc = 4;
#1 $display(alu_out == 8);

alu_op = 4;
rs2 = 'hBB;
#1 $display(alu_out == 'hBB);

alu_op = 5;
funct3 = 0;
rs1 = 10;
imm = 22;
#1 $display(alu_out == 32);

funct3 = 2;
rs1 = 1;
imm = 32'hFFFF_FFFF;
#1 $display(alu_out == 0);

funct3 = 3;
#1 $display(alu_out == 1);

funct3 = 4;
rs1 = 2;
imm = 3;
#1 $display(alu_out == 1);

funct3 = 6;
#1 $display(alu_out == 3);

funct3 = 7;
#1 $display(alu_out == 2);

funct3 = 1;
imm = 2;
rs1 = 1;
#1 $display(alu_out == 4);

rs1 = 'hFFFF_FFFF;
imm = 12'h010;
funct3 = 5;
#1 $display(alu_out == 'h0000_FFFF);
imm = 12'h410;
#1 $display(alu_out == 'hFFFF_FFFF);

alu_op = 6;

funct3 = 0;
imm = 0;
rs1 = 1;
rs2 = 'hFFFF_FFFE; //-2
#1 $display(alu_out == 'hFFFF_FFFF);
imm = 'h400;
#1 $display(alu_out == 3);
imm = 0;
funct3 = 1;
rs2 = 4;
#1 $display(alu_out == 'h10);
funct3 = 2;
rs1 = 1;
rs2 = 'hFFFF_FFFF;
imm = 0;
#1 $display(alu_out == 0);
funct3 = 3;
#1 $display(alu_out == 1);
funct3 = 4;
rs1 = 'hF0;
rs2 = 'h0F;
#1 $display(alu_out == 'hFF);
funct3 = 'b101;
imm = 0;
rs1 = 'hFFFF_0000;
rs2 = 'hF000_0010;
#1 $display(alu_out == 'h0000_FFFF);
imm = 'h400;
#1 $display(alu_out == 'hFFFF_FFFF);
imm = 0;
funct3 = 'b110;
#1 $display(alu_out == 'hFFFF_0010);
funct3 = 'b111;
#1 $display(alu_out == 'hF000_0000);

addr_alu_op = 0;
pc = 'hF0;
imm = 3;
rs1 = 2;
addr_alu_op = 0;
#1 $display(addr_alu_out == 'hF0);
addr_alu_op = 1;
#1 $display(addr_alu_out == 'hF3);
addr_alu_op = 2;
#1 $display(addr_alu_out == 5);
addr_alu_op = 3;
#1 $display(addr_alu_out == 'hF4);

$finish;

end

endmodule
