module cbd(a, r_coeff);
input [3:0] a;
output [13-1:0] r_coeff; // need to ask size of r.coeefs
parameter KEM_Q = 7681;
//actually HW & HD is there
//Hamming weight calculation
wire [1:0] temp_a;
wire [1:0] temp_b;
assign temp_a = a[4-1-2]+a[4-2-2]; 
assign temp_b = a[3]+a[2];
assign r_coeff = temp_a + KEM_Q - temp_b; 

//genvar ii;
//
//generate
//	for (ii=1; ii<9;ii = ii+1) begin //{
//		assign temp_a[ii*2-1: ii*2-2] = a[ii*4-1-2]+a[ii*4-2-2]; 
//		assign temp_b[ii*2-1: ii*2-2] = a[ii*4-1-0]+a[ii*4-2-0];
//		assign r_coeff[ii*13-1:ii*13-13] = temp_a[ii*2-1: ii*2-2] + KEM_Q - temp_b[ii*2-1: ii*2-2];
//	end //}
//endgenerate


endmodule
