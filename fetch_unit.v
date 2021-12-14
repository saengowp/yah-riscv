module fetch_unit(
	input wire [31:0] inst,
	input wire inst_valid,
	input wire [31:0] busy_reg,
	input wire jmp_op_in_pipeline,

	output valid,
	output [2:0] funct3,
	output [4:0] rd,
	output [4:0] rs1,
	output [4:0] rs2,
	output [31:0] imm,
	output [31:0] active_reg,
	output [2:0] alu_op,
	output [1:0] addr_alu_op,
	output [1:0] wb_op,
	output [1:0] jmp_op,
	output fault,
	output [1:0] mem_op
);

// Split instruction into fields
wire [6:0] opcode;
assign opcode = inst[6:0];
wire [4:0] rd;
assign rd = inst[11:7];
wire [2:0] funct3;
assign funct3 = inst[14:12];
wire [4:0] rs1;
assign rs1 = inst[19:15];
wire [4:0] rs2;
assign rs2 = inst[24:20];
wire [6:0] funct7;
assign funct7 = inst[31:25];

// Immediate Field
reg [31:0] imm;
always @* begin
	case (itype)
		1: imm = { {21{inst[31]}}, inst[30:20] };
		2: imm = { {21{inst[31]}}, inst[30:25], inst[11:8], inst[7] };
		3: imm = { {20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
		4: imm = { inst[31:12], 12'b0 };
		5: imm = { {12{inst[31]}}, inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0};
		default: imm = 0;
	endcase
end

// Issue Instruction
wire valid;
assign valid = (active_reg & busy_reg) == 0 && inst_valid && !jmp_op_in_pipeline; 
/* Only issue when 
* 	- register are available
* 	- instruction is valid
* 	- no jump in pipeline
*/

reg [31:0] active_reg;
reg [2:0] active_reg_field; // rs2, rs1, rd
always @* begin
	active_reg_field = 0;
	case (itype)
		0: active_reg_field = 'b111;
		1: active_reg_field = 'b011;
		2: active_reg_field = 'b110;
		3: active_reg_field = 'b110;
		4: active_reg_field = 'b001;
		5: active_reg_field = 'b001;
		default: active_reg_field = 'b000;
	endcase;
	active_reg = 0;
	if (active_reg_field[2])
		active_reg = active_reg | (1 << rs2);
	if (active_reg_field[1])
		active_reg = active_reg | (1 << rs1);
	if (active_reg_field[0])
		active_reg = active_reg | (1 << rd);
end

//Instruction Type R, I, S, B, U, J
reg [2:0] itype; 

reg [2:0] alu_op; //TODO
/*
0 = imm
1 = PC + 4
2 = rs1 + imm
3 = rs1 - rs2
4 = rs2
5 = ALUI funct3
6 = ALUL funct3
*/

reg [1:0] addr_alu_op; //TODO

/*
0 = pc
1 = pc + imm
2 = rs1 + imm
3 = pc + imm (clearing LSB)
*/


reg [1:0] wb_op;
/*
0 = NOP
1 = ALU/MEM out to rd
2 = ADDR ALU out to rd
*/

reg [1:0] jmp_op;
/*
0 = PC + 4
1 = ADDR ALU to PC
2 = ADDR ALU to PC if CMP ALU
*/

reg fault = 0;
/*
0 = No Fault
1 = Unknown Instruction
*/

reg [1:0] mem_op = 0;
/*
0 = No Op
1 = Load Op Funct3 returning data
2 = Store Op Funct3 from ALU
*/

always @* begin
	alu_op = 0;
	wb_op = 0;
	itype = 0;
	addr_alu_op = 0;
	mem_op = 0;
	fault = 0;
	jmp_op = 0;
	case (opcode)
		//LUI 
		7'b0110111: begin
			itype = 4;
			alu_op = 0;
			wb_op = 1;
		end
		//AUIPC
		7'b0010111: begin
			itype = 4;
			addr_alu_op = 1;
			wb_op = 2;
		end
		//JAL
		7'b1101111: begin
			itype = 5;
			alu_op = 1;
			wb_op = 1;
			addr_alu_op = 1;
			jmp_op = 1;
		end
		//JALR
		7'b1100111:  begin
			itype = 1;
			if (funct3 == 'b000) begin
				alu_op = 1;
				addr_alu_op = 3;
				wb_op = 1;
				jmp_op = 1;
			end else
				fault = 1;
		end
		//Bxx
		7'b1100011: begin
			itype = 3;
			addr_alu_op = 1;
			jmp_op = 2;
		end
		//Lxx
		7'b0000011: begin
			itype = 1;
			addr_alu_op = 2;
			wb_op = 1;
			mem_op = 1;
		end
		//Sx
		7'b0100011: begin
			itype = 2;
			addr_alu_op = 2;
			alu_op = 4;
			mem_op = 2;
		end
		//ALUI
		7'b0010011: begin
			itype = 1;
			alu_op = 5;
			wb_op = 1;
		end
		//ALUL
		7'b0110011: begin
			itype = 0;
			alu_op = 6;
			wb_op = 1;
		end
		//FENCE
		7'b0001111: fault = 0;
		//ECALL
		7'b1110011:
			if (rd == 0 && rs1 == 0 && rs2 == 0 && (imm == 0 || imm == 1))
				fault = 0;
			else
				fault = 1;
		default:
			fault = 1;
	endcase
end


endmodule
