module mem_unit(
	input wire [1:0] mem_op,
	input wire [31:0] alu_out,
	input wire [31:0] addr_alu_out,
	input wire [2:0] funct3,
	output reg [31:0] addr,
	input wire [31:0] read_data,
	output reg [31:0] write_data,
	output reg write_enable,
	output reg [31:0] out_data,
	output reg fault
);

wire [7:0] slice[3:0];
assign slice[0] = read_data[7:0];
assign slice[1] = read_data[15:8];
assign slice[2] = read_data[23:16];
assign slice[3] = read_data[31:24];

wire [1:0] offset;
assign offset = addr_alu_out[1:0];
wire [5:0] offsetb = offset << 3;

always @* begin
	addr = addr_alu_out & (~'b11);
	write_data = 0;
	write_enable = 0;
	out_data = 0;
	fault = 0;

	case (mem_op)
		0: out_data = alu_out;
		1: 
		case (funct3)
			//LB
			0: out_data = $signed(slice[offset]);
			//LH
			1: if (offset[0] == 0)
				out_data = $signed({slice[offset + 1], slice[offset]});
			   else
				fault = 1;
			//LW
			2: if (offset == 0)
				out_data = read_data;
			else
				fault = 1;
			//LBU
			4: out_data = slice[offset];
			//LHU
			5: if (offset[0] == 0)
				out_data = {slice[offset + 1], slice[offset]};
			default:
				fault = 1;
		endcase
		2: begin
			write_enable = 1;
			case (funct3)
				0: write_data = (read_data & ~(8'hFF << offsetb)) | (('hFF & alu_out) << offsetb);
				1: if (offset[0] == 0)
					write_data = (read_data & ~(16'hFFFF << offsetb)) | ((16'hFFFF & alu_out) << offsetb);
				   else 
					fault = 1;
				2: if (offset == 0)
					write_data = alu_out;
				   else
					fault = 1;
			endcase
		end
	endcase
end

endmodule
