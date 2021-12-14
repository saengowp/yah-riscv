`include "decode_unit.v"

module decode_unit_tb;

reg [31:0] inst = 0;

wire fault;
wire [2:0] funct3;
wire [4:0] rd, rs1, rs2;
wire [31:0] imm, active_reg;
wire [2:0] alu_op;
wire [1:0] addr_alu_op, wb_op, jmp_op, mem_op;

decode_unit du(
	.inst(inst),
	.fault(fault),
	.funct3(funct3),
	.rd(rd), .rs1(rs1), .rs2(rs2),
	.imm(imm), .active_reg(active_reg),
	.alu_op(alu_op),
	.addr_alu_op(addr_alu_op), .wb_op(wb_op), .jmp_op(jmp_op), .mem_op(mem_op)
);

initial begin
$dumpfile("test.vcd");
$dumpvars(0, decode_unit_tb);

#1
$display("Decode Unit Test Suite");

inst = 0;
#1 $display("T: Zero inst is fault: %d", fault);

// Instruction Control Signal Test

$monitor("MONITOR: fault %d", fault);

// lui x1, 0xF
inst = {20'hFF, 5'd1, 7'b0110111};
#1 $display("T: LUI: %d", 
	rd == 1 && 
	imm == {20'hFF, 12'b0} && 
	alu_op == 0 && 
	mem_op == 0 &&
	jmp_op == 0 &&
	wb_op == 1);

// auipc x1, 0xF
inst  = {20'hFF, 5'd1, 7'b0010111};
#1 $display("T: AUIPC: %d",
	rd == 1 &&
	imm == {20'hFF, 12'b0} &&
	addr_alu_op == 1 &&
	wb_op == 2 &&
	jmp_op == 0 &&
	mem_op == 0);

// jal x1, 0b1_00000010_1_0000000001_0
inst = {20'b1_0000000001_1_00000010, 5'd1, 7'b1101111};
#1 $display("T: JAL: %d",
	rd == 1 &&
	imm == 32'b11111111111_1_00000010_1_0000000001_0 &&
	alu_op == 1 &&
	addr_alu_op == 1 &&
	wb_op == 1 &&
	jmp_op == 1 &&
	mem_op == 0);

// jalr x1, 0xF(x2)
inst = {12'hF, 5'd2, 3'b0, 5'd1, 7'b1100111};
#1 $display("T: JALR: %d",
	rd == 1 &&
	rs1 == 2 &&
	imm == 'hF &&
	alu_op == 1 &&
	addr_alu_op == 3 &&
	wb_op == 1 &&
	jmp_op == 1 &&
	mem_op == 0);

// bne x1, x2, -4
inst = {7'b1111111, 5'd2, 5'd1, 3'b001, 5'b11101, 7'b1100011};
#1 $display("T: BNE: %d",
	rs1 == 1 &&
	rs2 == 2 &&
	imm == 32'hFFFF_FFFC &&
	addr_alu_op == 1 &&
	wb_op == 0 &&
	jmp_op == 2 &&
	funct3 == 1 &&
	mem_op == 0);

// lw x1, 8(x2)
inst = {12'd8, 5'd2, 3'b010, 5'd1, 7'b0000011};
#1 $display("T: LW: %d",
	rd == 1 &&
	rs1 == 2 &&
	imm == 8 &&
	addr_alu_op == 2 &&
	wb_op == 1 &&
	jmp_op == 0 &&
	funct3 == 3'b010 &&
	mem_op == 1);

// sw x1, -1(x2)
inst = {7'b1111111, 5'd1, 5'd2, 3'b010, 5'b11111,  7'b0100011};
#1 $display("T: SW: %d",
	rs1 == 2 &&
	rs2 == 1 &&
	imm == 32'hFFFFFFFF &&
	addr_alu_op == 2 &&
	wb_op == 0 &&
	jmp_op == 0 &&
	funct3 == 3'b010 &&
	mem_op == 2);

// addi x3, x2, 1
inst = {12'd1, 5'd2, 3'b000, 5'd3, 7'b0010011};
#1 $display("T: ADDI: %d",
	rs1 == 2 &&
	funct3 == 0 &&
	rd == 3 &&
	imm == 1 &&
	alu_op == 5 &&
	wb_op == 1 &&
	jmp_op == 0 &&
	mem_op == 0);

// add x3, x1, x2
inst = {7'd0, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011};
#1 $display("T: ADD: %d",
	rs1 == 1 &&
	rs2 == 2 &&
	rd == 3 &&
	funct3 == 0 &&
	alu_op == 6 &&
	wb_op == 1 &&
	jmp_op == 0 &&
	mem_op == 0);

$finish;
end

endmodule
