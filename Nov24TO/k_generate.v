module k_generate (clk, rst_n, server_counter_start, k, startlevel);

input clk;
input rst_n;
input server_counter_start;

output reg [5:0] k;  
input [8:0] startlevel;
reg [5:0] k_next; // bug fix
reg [8:0] startlevel_next;
wire startlevel_unequal = (startlevel_next == startlevel) ? 1'b0 : 1'b1;
always@(posedge clk, negedge rst_n) begin //{
	if(rst_n == 1'b0) begin
	k_next <= 1'b0;
	end	
	else begin
	k_next <= k;
	end
end //}

always@(posedge clk, negedge rst_n) begin //{
	if(rst_n == 1'b0) begin
	startlevel_next <= 1'b0;
	end	
	else begin
	startlevel_next <= startlevel;
	end
end //}



always@(*) begin
	k = (rst_n == 1'b0) ? 5'd1 : (server_counter_start == 1'b0) ? 5'd1 : (startlevel_unequal == 1'b1) ? k_next + 1'b1 : k_next;
end

//wire rst_n_server_counter = rst_n & server_counter_start;
//always@(startlevel, rst_n) begin //{ may have some error
//	k <= (rst_n == 1'b0) ? 5'd1 : (server_counter_start == 1'b0) ? 5'd1 : (k_next + 1'b1);
//	//if(rst_n== 0 || server_counter_start == 1'b0) begin //{
//	//	k <= 1;
//	//end //}
//	//else begin //{
//	//	k <= k_next + 1;
//	//end //}
//end//}


endmodule
