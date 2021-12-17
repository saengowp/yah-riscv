`include "memory.v"
`include "pc.v"
`include "decode_unit.v"
`include "register.v"
`include "alu_unit.v"
`include "mem_unit.v"

module pipelined_tb;

// Clock
reg clk = 0;

// PC
reg [31:0] p_addr = 0;
wire [31:0] p_inst;

// F-D buffer
reg [31:0] fd_inst, fd_pc;
reg fd_valid = 0;

// Decode
wire [2:0] d_funct3;
wire [4:0] d_rd, d_rs1, d_rs2;
wire [31:0] d_imm;
wire [2:0] d_alu_op;
wire [1:0] d_addr_alu_op, d_wb_op, d_jmp_op, d_mem_op;
wire [31:0] d_active_reg;
wire d_fault;

// D-R buffer
reg [2:0] dr_funct3;
reg [4:0] dr_rd, dr_rs1, dr_rs2;
reg [31:0] dr_imm, dr_pc;
reg [2:0] dr_alu_op;
reg [1:0] dr_addr_alu_op, dr_wb_op, dr_jmp_op, dr_mem_op;
reg dr_fault;
reg dr_valid = 0;

// Register
wire [31:0] r_out_r1, r_out_r2;

// R-A buffer
reg [2:0] ra_funct3;
reg [4:0] ra_rd;
reg [31:0] ra_imm, ra_data_rs1, ra_data_rs2, ra_pc;
reg [2:0] ra_alu_op;
reg [1:0] ra_addr_alu_op, ra_wb_op, ra_jmp_op, ra_mem_op;
reg ra_fault;
reg ra_valid = 0;

// ALU

wire [31:0] a_alu_out, a_addr_alu_out;
wire a_cmp_out, a_fault;

// A-M buffer
reg [2:0] am_funct3;
reg [4:0] am_rd;
reg [31:0] am_alu_out, am_addr_alu_out;
reg [1:0] am_wb_op, am_jmp_op, am_mem_op;
reg am_fault, am_cmp;
reg am_valid = 0;
reg [31:0] am_pc;
// Memory Unit
wire [31:0] m_addr, m_write_data, m_out_data, m_read_data;
wire m_fault, m_write_enable;

// M-W buffer
reg [4:0] mw_rd;
reg [31:0] mw_out_data, mw_addr_alu_out;
reg [1:0] mw_wb_op, mw_jmp_op;
reg mw_fault, mw_cmp;
reg mw_valid = 0;
reg [31:0] mw_pc;

//========================================

memory #(.ROM_FILE("rom.vh")) s_memory(
	.line(m_addr[14:2]),
	.write_data(m_write_data),
	.write(m_write_enable && am_valid),
	.clk(clk),
	.data(m_read_data),
	.inst_line(p_addr[14:2]),
	.inst_data(p_inst)
);

decode_unit s_decode_unit(
	.inst(fd_inst),
	.funct3(d_funct3),
	.rd(d_rd), .rs1(d_rs1), .rs2(d_rs2),
	.imm(d_imm),
	.alu_op(d_alu_op),
	.addr_alu_op(d_addr_alu_op), .wb_op(d_wb_op), .jmp_op(d_jmp_op), .mem_op(d_mem_op),
	.fault(d_fault),
	.active_reg(d_active_reg)
);

register s_register(
	.r1(dr_rs1),
	.r2(dr_rs2),
	.r_write(mw_rd),
	.data_write(mw_wb_op == 1 ? mw_out_data : mw_addr_alu_out),
	.enable_write(mw_wb_op != 0 && mw_valid),
	.out_r1(r_out_r1),
	.out_r2(r_out_r2),
	.clk(clk)
);

alu_unit s_alu_unit(
	.alu_op(ra_alu_op),
	.addr_alu_op(ra_addr_alu_op),
	.imm(ra_imm),
	.rs1(ra_data_rs1),
	.rs2(ra_data_rs2),
	.pc(ra_pc),
	.funct3(ra_funct3),
	.alu_out(a_alu_out),
	.addr_alu_out(a_addr_alu_out),
	.fault(a_fault),
	.cmp_out(a_cmp_out)
);

mem_unit s_mem_unit(
	.mem_op(am_mem_op),
	.alu_out(am_alu_out),
	.addr_alu_out(am_addr_alu_out),
	.funct3(am_funct3),
	.addr(m_addr),
	.read_data(m_read_data),
	.write_data(m_write_data),
	.write_enable(m_write_enable),
	.out_data(m_out_data),
	.fault(m_fault)
);

// ===============================================

wire [31:0] write_pending_reg = 
	((dr_valid && dr_wb_op != 0) << dr_rd) |
	((ra_valid && ra_wb_op != 0) << ra_rd) |
	((am_valid && am_wb_op != 0) << am_rd);


wire jmp_in_pipeline = 
	(dr_valid && dr_jmp_op != 0) || 
	(ra_valid && ra_jmp_op != 0) || 
	(am_valid && am_jmp_op != 0) || 
	(mw_valid && mw_jmp_op != 0);

always @(posedge clk) begin
	if (mw_fault && mw_valid) begin
		// Fault!
		p_addr <= 0;
	end else if (fd_valid && ((d_active_reg & write_pending_reg) != 0)) begin
		// Pending instruction contains Data Hazard (RAW)
		// PC: (C+1), FD: (C), DR: (C-1)
		dr_valid <= 0;
		// PC: (C+1), FD: (C), DR: x
	end else if (fd_valid && d_jmp_op != 0) begin
		// Penging instruction is JMP
		// PC: (J+1), FD: (J)
		dr_valid <= 1; // Issue this instruction
		fd_valid <= 0;
		// PC: (J+1), FD: (x), DR: (J), JMP_IN_PIPELINE
	end else if (jmp_in_pipeline) begin
		// PC: (J+1), FD: (J), DR: ?
		if (mw_valid && mw_jmp_op != 0) begin
			// Jump finish
			case (mw_jmp_op)
				1: p_addr <= mw_addr_alu_out;
				2: p_addr <= mw_cmp ? mw_addr_alu_out : p_addr;
			endcase
			// Either
			// PC: N, FD: x, DR: x
			// PC: J+1, FD: x, DR: x
		end
		dr_valid <= 0;
		fd_valid <= 0;
	end else begin
		// Normal operation
		p_addr <= p_addr + 4;
		fd_valid <= 1;
		fd_inst <= p_inst;
		fd_pc <= p_addr;
		dr_valid <= fd_valid;
	end
end

always @(posedge clk) begin
	dr_funct3 <= d_funct3;
	dr_rd <= d_rd;
	dr_rs1 <= d_rs1;
	dr_rs2 <= d_rs2;
	dr_imm <= d_imm;
	dr_pc <= fd_pc;
	dr_alu_op <= d_alu_op;
	dr_addr_alu_op <= d_addr_alu_op;
	dr_wb_op <= d_wb_op;
	dr_jmp_op <= d_jmp_op;
	dr_mem_op <= d_mem_op;
	dr_fault <= d_fault ;
end


always @(posedge clk) begin
	ra_funct3 <= dr_funct3;
	ra_rd <= dr_rd;
	ra_imm <= dr_imm;
	ra_data_rs1 <= r_out_r1;
	ra_data_rs2 <= r_out_r2;
	ra_pc <= dr_pc;
	ra_alu_op <= dr_alu_op;
	ra_addr_alu_op <= dr_addr_alu_op;
	ra_wb_op <= dr_wb_op;
	ra_jmp_op <= dr_jmp_op;
	ra_mem_op <= dr_mem_op;
	ra_fault <= dr_fault;
	ra_valid <= dr_valid;
end


always @(posedge clk) begin
	am_funct3 <= ra_funct3;
	am_rd <= ra_rd;
	am_alu_out <= a_alu_out;
	am_addr_alu_out <= a_addr_alu_out;
	am_wb_op <= ra_wb_op;
	am_jmp_op <= ra_jmp_op;
	am_mem_op <= ra_mem_op;
	am_fault <= ra_fault || a_fault;
	am_valid <= ra_valid;
	am_cmp <= a_cmp_out;
	am_pc <= ra_pc;
end


always @(posedge clk) begin
	mw_rd <= am_rd;
	mw_out_data <= m_out_data;
	mw_addr_alu_out <= am_addr_alu_out;
	mw_wb_op <= am_wb_op;
	mw_jmp_op <= am_jmp_op;
	mw_fault <= m_fault || am_fault;
	mw_valid <= am_valid;
	mw_cmp <= am_cmp;
	mw_pc <= am_pc;
end



always #1 clk = ~clk;
initial begin
$dumpfile("test.vcd");
$dumpvars(0, pipelined_tb);
$display("Pipelined Simulation");
#4000
$finish;
end

integer ri;

always @(posedge clk) begin
	if (fd_valid && fd_inst == 'h00000073) begin
		$display("ECALL AT %h", fd_pc);
		$finish;
	end
	if (mw_valid && mw_fault) begin
		$display("FAULT TRIGGERED: Fault: %d", (mw_valid && mw_fault));
		$display("PC: FD=%h PC=%h",  fd_pc, p_addr);
		$finish;
	end
end

endmodule
