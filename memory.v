module memory(
	input [11:0] addr,
	input [31:0] write_data,
	input write,
	input clk,
	output [31:0] data);

reg [31:0] mem[0:4095];
assign data = mem[addr];

always @(posedge clk) begin
	if (write) begin
		mem[addr] <= write_data;
	end
end

endmodule
