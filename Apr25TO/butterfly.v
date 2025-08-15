`timescale 1ns/1ps

module butterfly(clk, mode, in0, in1, zeta, out0, out1, pipeline_bit);
//pipeline_bit used for 2 stage mult or 
input [1:0] mode; //mode 0 ntt, mode 1 intt, mode 2 multiplication
input [15:0] in0, in1, zeta;
output reg [15:0] out0, out1;
input clk;
input pipeline_bit;
//output [31:0] mul_out;

reg [15:0] in0_buf, in1_buf, zeta_buf; //This may break the design; needs to be checked
reg [15:0] in0_buf2, in0_buf3, in1_buf2, in1_buf3;
reg [15:0] in0_buf4, in0_buf5, in1_buf4, in1_buf5, in0_buf6;
reg [15:0] zeta_buf2, zeta_buf3;
always@(posedge clk) begin //{
    in0_buf <= in0;
    in1_buf <= in1;
    zeta_buf <= zeta;
end //}

parameter KEM_Q = 7681;
wire [15:0] zeta1 = /*(mode == 2 & pipeline_bit) ? 4613 : (mode == 3) ? in0:*/(mode == 2) ? in0_buf : (mode == 1) ? zeta_buf3 : zeta_buf;

wire [15:0] rjlen_temp_ntt;
wire [15:0] dsp_input;
wire [15:0] dsp_input1;
reg [15:0] buffer_for_pipeline;
//reg pipeline_bit;
wire [31:0] t1 = zeta1 * dsp_input; 
reg [31:0] t1_pipeline_buffer;
//wire [31:0] t1 = (mode ==2 & pipeline_bit) ? 4613*in1 : zeta1 * dsp_input; // dsp reduced by using single multiplier  
//wire [31:0] dsp_input1 = 4613*in1;
wire [15:0] t;


prime_reduce u_modred(.clk (clk), .in(t1_pipeline_buffer[26:0]), .out(t));
//K2_reduction_7681 u_modred(.clk (clk), .in(t1_pipeline_buffer), .out(t));
//K2_reduction_7681 u_modred1(.in(4613*in1), .out(dsp_input1)); //2nd mod red for reducing after mult

//wire [15:0] rjlen_temp = (mode == 0) ? (in0 - t) : (in1 - in0); 
//wire [15:0] rj_temp = (mode == 0) ? (in0 + t) : (in0 + in1); // else part is valid for mode 1
reg [15:0] rjlen_temp, rj_temp;
//pipelining intermediate
always@(posedge clk) begin
    if(mode == 0 ) begin //{
        rjlen_temp <= (in0_buf4 - {3'b0, buffer_for_pipeline[12:0]}); //ntt bug fix
        rj_temp <= (in0_buf4 + {3'b0,buffer_for_pipeline[12:0]});
    end //}
//    else if(mode == 1) begin
//        rjlen_temp <= in1_buf - in0_buf;
//        rj_temp <= in0_buf + in1_buf;
//    end
    else begin //{
        rjlen_temp <= in1_buf - in0_buf; 
        rj_temp <= in0_buf + in1_buf;
    end //}
end
//extra pipelining
always@(posedge clk) begin //{
    in0_buf2 <= in0_buf;
    in0_buf3 <= (mode == 1)? ((rj_temp > KEM_Q) ? (rj_temp - KEM_Q) : rj_temp ) :in0_buf2;
    in0_buf4 <= (mode == 1) ? (in0_buf3[15:1] + (in0_buf3[0]*(KEM_Q+1)/2)) : in0_buf3;
    in0_buf5 <= in0_buf4;
    in0_buf6 <= in0_buf5;
    in1_buf2 <= in1_buf;
    in1_buf3 <= (mode == 1) ? (rjlen_temp[15] ? (rjlen_temp + KEM_Q) : rjlen_temp):in1_buf2;
    in1_buf4 <= in1_buf3;
    in1_buf5 <= in1_buf4;
    zeta_buf2 <= zeta_buf;
    zeta_buf3 <= zeta_buf2;
end //}
//pipelining between multiplication and reduction
always@(posedge clk) begin //{
    t1_pipeline_buffer <= t1;
end //}

//pipelining for mult
always@(posedge clk) begin //{
    //if(pipeline_bit)
    buffer_for_pipeline <= t;
end //}


assign rjlen_temp_ntt = rjlen_temp[15] ? (rjlen_temp + KEM_Q) : rjlen_temp;

assign dsp_input = /*(mode == 3) ? KEM_Q:*/ (mode == 0) ? in1_buf : (mode == 1) ? /*rjlen_temp_ntt*/in1_buf3 : /*(mode == 2 & pipeline_bit) ? buffer_for_pipeline :*/ (mode == 2) ? in1_buf : 0;  

//assign out0 =(rj_temp >= KEM_Q) ? (rj_temp - KEM_Q) : (rj_temp);
//assign out1 = (mode == 1 || mode ==2) ? buffer_for_pipeline : (mode == 0) ? rjlen_temp_ntt : 0; //else logic will be improved

always@(posedge clk) begin
    out0 <= (mode == 1) ? in0_buf6 : (rj_temp >= KEM_Q) ? (rj_temp - KEM_Q) : (rj_temp);
    out1 <= (mode ==2)? {3'b0, buffer_for_pipeline[12:0]} : (mode == 1) ? ({4'b0, buffer_for_pipeline[12:1]} + (buffer_for_pipeline[0]*(KEM_Q+1)/2)) : (mode == 0) ? rjlen_temp_ntt : 0; //else logic will be improved
end
// assign mul_out = t1;
endmodule
//module butterfly(level,zeta, p_j, p_j_plus_1shiftlevel, out_j, out_j_1shiftlevel);
//parameter KEM_Q = 7681;
//input [31:0] level;
//input [15:0] zeta, p_j, p_j_plus_1shiftlevel; //can zeta be negative?
//output [15:0] out_j, out_j_1shiftlevel; //out address can be controlled from controller
//
//wire [15:0] t;
//wire [15:0] temp2;
//wire [15:0] temp3, temp4;
//wire [31:0] temp1;
//
//assign temp1 = zeta*p_j_plus_1shiftlevel;
//montgomery_reduce u_mr(.a(temp1), .out(t));
//
////if(PRIME_Q == 12289)
////assign temp2 = p_j+3*PRIME_Q-t;
////else if(PRIME_Q == 7681)
//assign temp2 = p_j+4*PRIME_Q-t;
////end
//
//
//barret_reduce u_br(.a(temp2), .out(temp3));
//
//assign out_j_1shiftlevel = temp3;
//
//barret_reduce u_br1(.a(p_j+t), .out(temp4));
//
//assign out_j = (level[0]) ? (p_j +t) : temp4; 
//
//endmodule
