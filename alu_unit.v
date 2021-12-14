module alu_unit(
	input wire [2:0] alu_op,
	input wire [1:0] addr_alu_op,
	input wire [31:0] imm,
	input wire [31:0] rs1,
	input wire [31:0] rs2,
	input wire [31:0] pc,
	input wire [2:0] funct3,
	output reg [31:0] alu_out,
	output reg [31:0] addr_alu_out,
	output reg fault
);

reg [1:0] funct7md;

always @* begin
	fault = 0;
	alu_out = 0;
	case (imm[11:5])
		7'b0000000: funct7md = 0;
		7'b0100000: funct7md = 1;
		default: funct7md = 2;
	endcase
	case (alu_op)
		0: alu_out = imm;
		1: alu_out = pc + 4;
		4: alu_out = rs2;
		5: case (funct3)
			3'b000: alu_out = rs1 + imm;
			3'b010: alu_out = $signed(rs1) < $signed(imm);
			3'b011: alu_out = rs1 < imm;
			3'b100: alu_out = rs1 ^ imm;
			3'b110: alu_out = rs1 | imm;
			3'b111: alu_out = rs1 & imm;
			3'b001: begin
				alu_out = rs1 << imm[4:0];
				if (funct7md != 0)
					fault = 1;
			end
			3'b101: begin
				if (funct7md == 0)
					alu_out = rs1 >> imm[4:0];
				else if (funct7md == 1)
					alu_out = $signed(rs1) >>> imm[4:0];
				else
					fault = 1;
			end
		endcase
		6: case (funct3)
			3'b000: 
				if (funct7md == 0) 
					alu_out = rs1 + rs2;
				else if (funct7md == 1)
					alu_out = rs1 - rs2;
				else
					fault = 1;
			3'b001: 
				if (funct7md == 0)
					alu_out = rs1 << rs2[4:0];
				else
					fault = 1;
			3'b010:
				if (funct7md == 0)
					alu_out = $signed(rs1) < $signed(rs2);
				else
					fault = 1;
			3'b011:
				if (funct7md == 0)
					alu_out = rs1 < rs2;
				else
					fault = 1;
			3'b100:
				if (funct7md == 0)
					alu_out = rs1 ^ rs2;
				else
					fault = 1;
			3'b101:
				if (funct7md == 0)
					alu_out = rs1 >> rs2[4:0];
				else if (funct7md == 1)
					alu_out = $signed(rs1) >>> rs2[4:0];
				else
					fault = 1;
			3'b110:
				if (funct7md == 0)
					alu_out = rs1 | rs2;
				else
					fault = 1;
			3'b111:
				if (funct7md == 0)
					alu_out = rs1 & rs2;
				else
					fault = 1;
		endcase
	endcase
end

always @* begin
	addr_alu_out = 0;
	case (addr_alu_op)
		0: addr_alu_out = pc;
		1: addr_alu_out = pc + imm;
		2: addr_alu_out = rs1 + imm;
		3: addr_alu_out = (pc + imm) & (~32'b1);
	endcase
end

endmodule
