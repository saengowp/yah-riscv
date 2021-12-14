`include "memory.v"

module memory_tb;

reg [31:0] addr, write_data, inst_addr;
reg write, clk;

wire [31:0] data, inst_data;

memory m(.addr(addr[11:0]), .write_data(write_data), .write(write), .clk(clk), .data(data), .inst_addr(inst_addr[11:0]), .inst_data(inst_data));

always #5 clk = ~clk;

initial begin
clk = 0;
write = 1;
addr = 0;
write_data = 'hFF;

#10 $display("Written 0 = FF");

addr = 1;
write_data = 'hBB;

#10 $display("Writted 1 = BB");

write = 0;
addr = 0;

#10 $display("Read back: %d", data == 'hFF);

addr = 1;
#10 $display("Read back: %d", data == 'hBB);

inst_addr = 1;
#10 $display("Read back: %d", data == 'hBB);


$finish;

end

endmodule
