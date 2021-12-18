module uart(
	output reg tx,
	input wire rx,
	input wire [5:0] addr,
	output reg [31:0] data_out,
	input wire [31:0] data_in,
	input wire write_enable,
	input wire clk
);

/*
00 => [Padding (20) | Recv Ptr (4 bits, Read Only) | Write Head (4 bits, Read Only) | Write Ptr (4 bits, Writable)]
10 - 1F => Recv Buffer (Read only)
20 - 2F => Send Buffer (Writable)
*/

parameter UART_PERIOD = 10417;

reg [3:0] rx_ptr = 0, tx_ptr = 0, tx_head = 0;
reg [31:0] rx_buf[0:3], tx_buf[0:3];

reg [13:0] cnt = 0;

always @(posedge clk) begin
	if (cnt < UART_PERIOD)
		cnt <= cnt + 1;
	else
		cnt <= 0;
end

// IO Mem 
always @* begin
	if (addr == 0)
		data_out = {20'b0, rx_ptr, tx_head, tx_ptr};
	else if (addr[5:4] == 1)
	    data_out = rx_buf[addr[3:2]];
	else if (addr[5:4] == 2)
	    data_out = tx_buf[addr[3:2]];
end

// IO Mem Write
always @(posedge clk) begin
	if (write_enable) begin
		if (addr == 0)
			tx_ptr <= data_in[3:0];
		if (addr[5:4] == 2)
			tx_buf[addr[3:2]] <= data_in;
	end
end

reg [3:0] tx_state = 10;
reg [13:0] tx_start = 0;
reg [7:0] tx_data = 0;

wire [7:0] tx_buf_head[3:0];
assign {tx_buf_head[3], tx_buf_head[2], tx_buf_head[1], tx_buf_head[0]} = tx_buf[tx_head[3:2]];

// Transmit
always @(posedge clk) begin
	if (tx_state == 10 && tx_head != tx_ptr) begin
		// New data
		tx_state <= 0;
		tx <= 0;
		tx_start <= cnt;
		tx_data <= tx_buf_head[tx_head[1:0]];
		tx_head <= tx_head + 1;
		$display("UART printing: %h", tx_buf_head[tx_head[1:0]]);
	end else if (tx_state != 10) begin
		// Send data
		if (tx_state == 0)
			tx <= 0;
		else if (tx_state > 0 && tx_state < 9)
			tx <= tx_data[tx_state - 1];
		else
			tx <= 1;
		
		if (cnt == tx_start)
			tx_state <= tx_state + 1;
	end else begin
		tx <= 1;
	end
end

// Receive
reg brx;
reg [7:0] rx_data;
reg [3:0] rx_state = 10;
reg [13:0] rx_start = 0;

wire [7:0] crx_buf[3:0];
assign {crx_buf[3], crx_buf[2], crx_buf[1], crx_buf[0]} = rx_buf[rx_ptr[3:2]];

always @(posedge clk) begin
	brx <= rx;

	if (rx_state == 10) begin
		// Ready to RX
		if (!brx) begin
			rx_data <= 0;
			rx_state <= 0;
			rx_start <= cnt;
		end
	end else if (rx_state != 10) begin
		if (cnt == rx_start)
			rx_state <= rx_state + 1;

		if (cnt == (rx_start + UART_PERIOD/2 > UART_PERIOD ? rx_start - UART_PERIOD/2 : rx_start + UART_PERIOD/2)) begin
			if (rx_state == 0 && brx) begin
				//Huh. No more signal.
				rx_state <= 10;
			end
			if (rx_state == 9) begin
				if (brx) begin
					case (rx_ptr[1:0])
						0: rx_buf[rx_ptr[3:2]] <= {crx_buf[3], crx_buf[2], crx_buf[1], rx_data};
						1: rx_buf[rx_ptr[3:2]] <= {crx_buf[3], crx_buf[2], rx_data, crx_buf[0]};
						2: rx_buf[rx_ptr[3:2]] <= {crx_buf[3], rx_data, crx_buf[1], crx_buf[0]};
						3: rx_buf[rx_ptr[3:2]] <= {rx_data, crx_buf[2], crx_buf[1], crx_buf[0]};
					endcase
					rx_ptr <= rx_ptr + 1;
					$display("UART Receiving %h", rx_data);
				end
			end
			if (rx_state > 0 && rx_state < 9) begin
				rx_data <= (rx_data >> 1) | {brx, 7'b0};
			end
		end
	end
end

endmodule
