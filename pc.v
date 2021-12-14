module pc(
	input wire fetch_unit_valid, //Fetch unit processed the previous instruction
	input wire [1:0] jmp_op,
	input wire [31:0] next_addr,
	input wire valid, // ALU-WB valid
	input wire cmp,
	input wire clk,
	input wire fault,
	output [31:0] addr
);

reg [31:0] addr = 0;
wire [31:0] next_addr_checked;
assign next_addr_checked = next_addr[1:0] == 0 ? next_addr : 0;

always @(posedge clk) begin
	if (valid) begin
		//Incoming WB
		if (fault) begin
			// Reset due to fault
			addr <= 0;
		end else begin
			case (jmp_op)
				// No jump, PC will increment once current
				// instruction is completed
				0: addr <= fetch_unit_valid ? addr + 4 : addr;
				// Unconditional jump. discard current PC
				1: addr <= next_addr_checked;
				// Conditional jump. 
				// If branch, then discard current PC
				// else fallthrough, then wait for current pc
				// to be processed.
				// Note that since we are seeing jump, the
				// fetch unit also see it, so it would have
				// not yet emit current pc
				2: addr <=  cmp ? next_addr_checked : addr;
			endcase
		end
	end else begin
		// Bubble in the pipeline. Ignore.
		addr <= fetch_unit_valid ? addr + 4 : addr;
	end
end

endmodule
