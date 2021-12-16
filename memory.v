module memory(
	input wire [11:0] line,
	input wire [31:0] write_data,
	input wire write,
	input wire clk,
	output wire [31:0] data,
	input wire [11:0] inst_line,
	output wire [31:0] inst_data);

reg [31:0] mem[0:4095];
assign data = mem[line];
assign inst_data = mem[inst_line];

parameter ROM_FILE = "NONE";

always @(posedge clk) begin
	if (write) begin
		mem[line] <= write_data;
	end
end

initial begin
	if (ROM_FILE != "NONE") begin
		$display("MEM LOADED");
		$readmemh("rom.txt", mem);
	end else
		$display("NO MEM");
end

endmodule
