module memory(
	input wire [12:0] line,
	input wire [31:0] write_data,
	input wire write,
	input wire clk,
	output wire [31:0] data,
	input wire [12:0] inst_line,
	output wire [31:0] inst_data);

reg [31:0] mem[0:8192];
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
		$readmemh(ROM_FILE, mem);
	end else
		$display("NO MEM");
end

endmodule
