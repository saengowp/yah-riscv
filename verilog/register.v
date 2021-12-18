module register(
	input wire [4:0] r1,
	input wire [4:0] r2,
	input wire [4:0] r_write,
	input wire [31:0] data_write,
	input wire enable_write,
	output wire [31:0] out_r1,
	output wire [31:0] out_r2,
	input wire clk
);

reg [31:0] r[1:31];

assign out_r1 = r1 == 0 ? 0 : r[r1];
assign out_r2 = r2 == 0 ? 0 : r[r2];

always @(posedge clk) begin
	if (enable_write && r_write != 0) begin
		r[r_write] <= data_write;
	end
end

integer i;
initial begin
	for (i = 0; i < 32; i = i + 1) begin
		r[i] = 0;
	end
end

endmodule

