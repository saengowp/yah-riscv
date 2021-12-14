module memory(
	input wire [11:0] addr,
	input wire [31:0] write_data,
	input wire write,
	input wire clk,
	output wire [31:0] data,
	input wire [11:0] inst_addr,
	output wire [31:0] inst_data);

reg [31:0] mem[0:4095];
assign data = mem[addr];
assign inst_data = mem[inst_addr];

always @(posedge clk) begin
	if (write) begin
		mem[addr] <= write_data;
	end
end

endmodule
