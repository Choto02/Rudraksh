module prime_reduce(clk, in, out);

input clk;
input [26:0] in;
output [15:0] out;

localparam KEM_Q = 7681;

reg [12:0] c0;
reg [3:0] c1, c2, c3;
reg [1:0] c4;

wire [4:0] temp0;
wire [5:0] temp1;
wire [6:0] temp2;
wire [7:0] temp3;
wire [11:0] temp4;
wire [15:0] temp5;
wire [15:0] res, result1, result2;
//wire for bug fix
wire [15:0] res1, res2, res3;

always@(posedge clk)
	begin //{
		c0 <= in[12:0];
		c1 <= in[16:13];
		c2 <= in[20:17];
		c3 <= in[24:21];
		c4 <= in[26:25];
	end //}

assign temp0 = c4 + c3;
assign temp1 = c4 + c3 + c2;
assign temp2 = c4 + c3 + c2 + c1;
assign temp3 = {temp2, 1'b0} - {temp0};
assign temp4 = {temp3, 4'b0} - (temp1);
assign temp5 = {temp4, 4'b0} - (temp2);
assign res = temp5 + c0 - {c4, 12'b0};
//assign res2 = res - 2*KEM_Q;
//assign res1 = res - KEM_Q;
//assign out = res[15] ? (res + KEM_Q) : (res > KEM_Q) ? (res - KEM_Q) : ((res - KEM_Q) > KEM_Q) ? res - {KEM_Q, 1'b0}: ((res - 2*KEM_Q) > KEM_Q) ?  res - {KEM_Q, 1'b0} - KEM_Q :res;
//assign out = res[15] ? (res + KEM_Q) : ((res2) > KEM_Q & (~res2[15])) ?  res2 - KEM_Q : 
//((res1) > KEM_Q & (~res1[15])) ? res - {KEM_Q, 1'b0}: (res > KEM_Q) ? (res - KEM_Q) :res;  
assign out = res[15] ? (res + KEM_Q) : ((res) > 23043) ?  res - {KEM_Q, 1'b0} - KEM_Q : 
((res) > 15362) ? res - {KEM_Q, 1'b0}: (res > KEM_Q) ? (res - KEM_Q) :res;  
  
//assign result2 = (result1 > KEM_Q ) ? (result1 - KEM_Q) : result1;
//assign out = (result2 > KEM_Q ) ? (result2 - KEM_Q) : result2;


endmodule
