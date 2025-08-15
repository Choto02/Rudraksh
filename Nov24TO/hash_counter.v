module hash_counter (
    // general
    input [127:0] genmat_message,

    // block 1
    input hash_h_start,
    input [15:0] mem_rd_PK,
    output reg [3:0] hash_counter, hash_bit_bias,
    output reg [75:0] hash_buffer,

    // block 2
    output reg [63:0] hash_buffer_sel_buf,
    output reg [10:0] hash_read_addr,

    // block 3
    input server_counter_start,

    // block 4

    // clk & rst_n
    input clk,
    input rst_n
);

// block 1
always@(posedge clk) begin
	if(rst_n == 0) begin
		hash_buffer <= 0;
	end
	else if(hash_h_start & hash_bit_bias == 12 & hash_counter<5 & hash_counter>0) begin
		hash_buffer <= {mem_rd_PK, hash_buffer[75:13]};
	end
	else if(hash_h_start & (hash_counter<6) & (hash_counter>0) & (hash_bit_bias != 12/* & (hash_bit_bias != 0)*/)) begin
		hash_buffer <= {mem_rd_PK, hash_buffer[75:13]};
	end
	else if(hash_h_start)begin
		hash_buffer <= hash_buffer;
	end
	else hash_buffer <= hash_buffer;
end

// block 2
wire [63:0] hash_buffer_sel;
assign hash_buffer_sel = (hash_bit_bias == 12) ? hash_buffer[75:12] : hash_buffer[74-hash_bit_bias-:64];

always@(posedge clk, negedge rst_n) begin
	if(rst_n == 0) begin //{
		hash_buffer_sel_buf <= hash_buffer_sel; 
	end //}
	else if(hash_read_addr >=586) begin
		hash_buffer_sel_buf <= genmat_message[63:0]/*{genmat_message[64+7 :64+0 ], genmat_message[64+15:64+8], 
					genmat_message[64+23:64+16], genmat_message[64+31:64+24],
					genmat_message[64+39:64+32], genmat_message[64+47:64+40], 
					genmat_message[64+55:64+48], genmat_message[64+63:64+56]}*/; 
	end
	else if(hash_read_addr >=581) begin
		hash_buffer_sel_buf <= genmat_message[127:64]/*{genmat_message[7:0], genmat_message[15:8], 
					genmat_message[23:16], genmat_message[31:24],
					genmat_message[39:32], genmat_message[47:40], 
					genmat_message[55:48], genmat_message[63:56]}*/;  
	end
	else if (hash_counter == 5 & hash_bit_bias == 12) begin //{
		hash_buffer_sel_buf <= {hash_buffer_sel[7:0], hash_buffer_sel[15:8], hash_buffer_sel[23:16], hash_buffer_sel[31:24], hash_buffer_sel[39:32], hash_buffer_sel[47:40], hash_buffer_sel[55:48], hash_buffer_sel[63:56]};
	end //]
	else if(hash_counter == 6 & hash_bit_bias != 12) begin //{
		hash_buffer_sel_buf <= {hash_buffer_sel[7:0], hash_buffer_sel[15:8], hash_buffer_sel[23:16], hash_buffer_sel[31:24], hash_buffer_sel[39:32], hash_buffer_sel[47:40], hash_buffer_sel[55:48], hash_buffer_sel[63:56]};
	end //}
	else begin //{
		hash_buffer_sel_buf <= hash_buffer_sel_buf;
		
	end //}
end

// block 3: hash_counter & hash_bit_bias
always@(posedge clk, negedge server_counter_start) begin
    if(server_counter_start == 0) begin
		hash_counter <= 0;
		hash_bit_bias <= 0;
		//hash_debug_bit <= 0;
	end
	else if(hash_bit_bias == 12 && hash_counter == 13) begin
		hash_bit_bias <= 0;
		hash_counter <= 0;
		//hash_debug_bit <= 1;
		end
	else if(hash_counter == 13) begin //{ for absorb
		hash_counter <= 0;
		hash_bit_bias <= hash_bit_bias + 1'b1;
	end //}
	else if (hash_h_start) begin
		hash_counter <= hash_counter + 1'b1;
		hash_bit_bias <= hash_bit_bias;
	end
	else begin
		hash_counter <= hash_counter;
		hash_bit_bias <= hash_bit_bias;
	end
end

// block 4: hash_read_addr
always@(posedge clk) begin
	if(rst_n == 0) begin
		hash_read_addr <= 0;
	end
	else if(hash_h_start & (hash_counter<4) & hash_bit_bias == 12) begin
		hash_read_addr <= hash_read_addr + 1'b1;
	end
	else if(hash_h_start & (hash_counter<5) & (hash_bit_bias !=12)) begin
		hash_read_addr <= hash_read_addr + 1'b1;
	end
	else hash_read_addr <= hash_read_addr;
end
endmodule