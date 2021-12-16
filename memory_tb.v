`include "memory.v"

module memory_tb;

reg [31:0] line, write_data, inst_line;
reg write, clk;

wire [31:0] data, inst_data;

memory m(.line(line[11:0]), .write_data(write_data), .write(write), .clk(clk), .data(data), .inst_line(inst_line[11:0]), .inst_data(inst_data));

always #5 clk = ~clk;

initial begin
clk = 0;
write = 1;
line = 0;
write_data = 'hFF;

#10 $display("Written 0 = FF");

line = 1;
write_data = 'hBB;

#10 $display("Writted 1 = BB");

write = 0;
line = 0;

#10 $display("Read back: %d", data == 'hFF);

line = 1;
#10 $display("Read back: %d", data == 'hBB);

inst_line = 1;
#10 $display("Read back: %d", data == 'hBB);


$finish;

end

endmodule
