module pc(
	input wire stall, //Fetch unit processed the previous instruction
	input wire [1:0] jmp_op,
	input wire [31:0] next_addr,
	input wire valid, // ALU-WB valid
	input wire cmp,
	input wire fault,
	input wire clk,
	output [31:0] addr
);

reg [31:0] addr = 0;
reg [31:0] nxt_loc;
assign next_addr_aligned = next_addr[1:0] == 0;

always @* begin

if (valid) begin
	if (fault) begin
		nxt_loc = 0;
	end else
		case (jmp_op)
			0: nxt_loc = addr + 4;
			1: nxt_loc = next_addr_aligned ? next_addr : 0;
			2: begin
				if (cmp) begin
					nxt_loc = next_addr_aligned ? next_addr : 0;
				end else begin
					nxt_loc = addr + 4;
				end
			end
		endcase
end else begin
	nxt_loc = addr + 4;
end

end

always @(posedge clk) begin
	if (!stall)
		addr <= nxt_loc;
end

endmodule
