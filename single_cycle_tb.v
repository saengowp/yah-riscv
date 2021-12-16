`include "memory.v"
`include "pc.v"
`include "decode_unit.v"
`include "register.v"
`include "alu_unit.v"
`include "mem_unit.v"

module single_cycle_tb;

// Clock
reg clk = 0;

// Memory
wire [31:0] inst_addr;
wire [31:0] inst_from_mem;
wire [31:0] data_addr;
wire [31:0] data_to_mem;
wire [31:0] data_from_mem;
wire data_write;

memory #(.ROM_FILE("rom.vh")) s_memory(
	.line(data_addr[13:2]),
	.write_data(data_to_mem),
	.write(data_write),
	.clk(clk),
	.data(data_from_mem),
	.inst_line(inst_addr[13:2]),
	.inst_data(inst_from_mem)
);

wire [1:0] jmp_op;
wire [31:0] next_addr;
wire cmp;

pc s_pc(
	.stall(1'b0),
	.jmp_op(jmp_op),
	.next_addr(next_addr),
	.valid(1'b1),
	.cmp(cmp),
	.fault(1'b0),
	.clk(clk),
	.addr(inst_addr)
);

wire [2:0] funct3;
wire [4:0] rd, rs1, rs2;
wire [31:0] imm;
wire [2:0] alu_op;
wire [1:0] addr_alu_op, wb_op, mem_op;
wire decode_fault;

decode_unit s_decode_unit(
	.inst(inst_from_mem),
	.funct3(funct3),
	.rd(rd), .rs1(rs1), .rs2(rs2),
	.imm(imm),
	.alu_op(alu_op),
	.addr_alu_op(addr_alu_op), .wb_op(wb_op), .jmp_op(jmp_op), .mem_op(mem_op),
	.fault(decode_fault)
);

wire [31:0] reg_write_data;
wire reg_write_enable;
wire [31:0] data_rs1, data_rs2;

register s_register(
	.r1(rs1),
	.r2(rs2),
	.r_write(rd),
	.data_write(reg_write_data),
	.enable_write(reg_write_enable),
	.out_r1(data_rs1),
	.out_r2(data_rs2),
	.clk(clk)
);

wire [31:0] alu_out, addr_alu_out;
wire alu_fault;

alu_unit s_alu_unit(
	.alu_op(alu_op),
	.addr_alu_op(addr_alu_op),
	.imm(imm),
	.rs1(data_rs1),
	.rs2(data_rs2),
	.pc(inst_addr),
	.funct3(funct3),
	.alu_out(alu_out),
	.addr_alu_out(next_addr),
	.fault(alu_fault),
	.cmp_out(cmp)
);

wire [31:0] mem_unit_out;
wire mem_unit_fault;

assign reg_write_enable = wb_op != 0;
assign reg_write_data = mem_unit_out;

mem_unit s_mem_unit(
	.mem_op(mem_op),
	.alu_out(alu_out),
	.addr_alu_out(addr_alu_out),
	.funct3(funct3),
	.addr(data_addr),
	.read_data(data_from_mem),
	.write_data(data_to_mem),
	.write_enable(data_write),
	.out_data(mem_unit_out),
	.fault(mem_unit_fault)
);

wire fault;
assign fault = decode_fault || alu_fault || mem_unit_fault;

always #1 clk = ~clk;
initial begin
$dumpfile("test.vcd");
$dumpvars(0, single_cycle_tb);
$display("Single Cycle Simulation");
end

integer ri;

always @(posedge clk) begin
	if (fault || inst_from_mem[7:0] == 7'b1110011) begin
		$display("FAULT TRIGGERED: Fault: %d ECALL: %d", fault, inst_from_mem[7:0] == 7'b1110011);
		$display("PC: %h", inst_addr);
		$display("Fault: DECODE: %d ALU: %d MEM: %d", decode_fault, alu_fault, mem_unit_fault);
		$finish;
	end
end

endmodule
