`timescale 1ns/1ps

module small_kyber_top
#(
    parameter r = 64, // Hash rate in bit
    parameter a = 12, //no of rounds 12 for P12
    parameter b = 12, // no of rounds 12 for P12
    parameter h = 256, // capacity size
    parameter l = 64*2000, // output xof size -- bits out genmatrix > 9*9*64*13, idea is to try to fill unless mem_fill 1
    //parameter y = 40
    parameter y = 64*2 //input message size -- bits
) 
(
input CLK,
input RST_N,
input start,
input [y-1:0]   message,
input [y-1:0]   encr_message,
input [y-1:0] genmat_message,
input v_path_decrypt,
input b_path_decrypt,
//input ic_read 
input [10:0] read_addr,
output [15:0] read_data1,
output [15:0] read_data2,
output [15:0] read_data3,
input read_external, 
output trigger,
output serial_out,
input [127:0] msg_in


);


wire start_keygen;
wire ready;
wire temp_coeff_array;
wire [7:0] x_addr;
wire [7:0] y_addr;
wire [10:0] addr_bias;
wire [10:0] addr_bias_genmat;
wire [10:0] addr_bias_mult;
wire server_counter_start;
wire op_done;
wire no_ntt;
wire debug_reset;
wire hash_h_start;
wire accumulate_start;
wire decrypt_start;
wire [10:0] ext_addr;
wire ntt_start_out;
wire external_write;
wire [15:0] external_data;
wire extr_mul;
wire no_error;
wire intt_start;
wire v_start;
wire decode_start;
wire ep_gen;
wire ep_accumulate;
wire [10:0] addr_bias_acc;
wire start_encr;
wire mem_pk_sk_transfer;
wire mem_sk_pk_transfer;
wire [10:0] addr_bias1;
wire b_out_en;
wire v_out_en;

small_kyber_top_fsm u_small_kyber_top_fsm(
	
	.CLK(CLK),
	.RST_N(RST_N),
	.start(start),
	.v_path_decrypt(v_path_decrypt),
	.b_path_decrypt(b_path_decrypt),
	.trigger(trigger),

	.start_keygen(start_keygen),
	.decrypt_start(decrypt_start),
	.ext_addr(ext_addr),
	.external_write(external_write),
	.external_data(external_data),
	.extr_mul(extr_mul),
	.intt_start(intt_start),
	.v_start(v_start),
	.decode_start(decode_start),
	.ep_gen(ep_gen),
	.ep_accumulate(ep_accumulate),
	.addr_bias_acc(addr_bias_acc),
	.start_encr(start_encr),
	.mem_pk_sk_transfer(mem_pk_sk_transfer),
	.mem_sk_pk_transfer(mem_sk_pk_transfer),
	.addr_bias1(addr_bias1),
	.b_out_en(b_out_en),
	.v_out_en(v_out_en),

	.ready(ready),
	.temp_coeff_array(temp_coeff_array),
	.x_addr(x_addr),
	.y_addr(y_addr),
	.addr_bias(addr_bias),
	.addr_bias_genmat(addr_bias_genmat),
	.addr_bias_mult(addr_bias_mult),
	.server_counter_start(server_counter_start),
	.op_done(op_done),
	.no_ntt(no_ntt),
	.debug_reset(debug_reset),
	.hash_h_start(hash_h_start),
	.accumulate_start(accumulate_start),
	.ntt_start_out(ntt_start_out),
	.no_error(no_error)
	);


//====================
//server_client_cca u_server_client(.clk(CLK), .rst_n(RST_N), .message(message/*128'h58256fdfef6a5f8fa09c171607a93bdd*//*f1331ed7b60e3046af42d91d554bfa45*/), .genmat_message(genmat_message/*128'hea97e8a6e6dd65e2873f1cc1d44098d8*/)
//,.start_keygen(start_keygen), .ready(), .temp_coeff_array(), .x_addr(x_addr), .y_addr(y_addr), .addr_bias(addr_bias), .addr_bias_genmat(addr_bias_genmat), .addr_bias_mult(addr_bias_mult), 
//.server_counter_start(server_counter_start), .op_done(op_done), .no_ntt(no_ntt), .debug_reset(debug_reset), .hash_g_start(1'b0), .hash_h_start(hash_h_start), .read_external(read_external)
//, .read_addr(read_addr) ,.accumulate_start(accumulate_start), .read_data1(read_data1), .read_data2(read_data2), .read_data3(read_data3), .decrypt_start(decrypt_start), .ext_addr(ext_addr), .ntt_start_out(ntt_start_out), .external_write(external_write), .external_data(external_data)
//,.extr_mul(extr_mul), .no_error(no_error), .intt_start(intt_start), .v_start(v_start), .decode_start(decode_start), .ep_gen(ep_gen), .ep_accumulate(ep_accumulate), .addr_bias_acc(addr_bias_acc), .start_encr(start_encr), .encr_message(encr_message), .msg_in(128'h0f0e0d0c0b0a09080706050403020100/*000102030405060708090a0b0c0d0e0f*/), .mem_pk_sk_transfer(mem_pk_sk_transfer), .mem_sk_pk_transfer(mem_sk_pk_transfer), .addr_bias1(addr_bias1), .b_out_en(b_out_en), .v_out_en(v_out_en)); //gen_a
//
server_client_cca u_server_client(
	.clk(CLK), 
	.rst_n(RST_N), 
	.message(message/*128'h58256fdfef6a5f8fa09c171607a93bdd*//*f1331ed7b60e3046af42d91d554bfa45*/), 
	.genmat_message(genmat_message/*128'hea97e8a6e6dd65e2873f1cc1d44098d8*/),
	.start_keygen(start_keygen), 
	.ready(), 
	.temp_coeff_array(), 
	.x_addr(x_addr), 
	.y_addr(y_addr), 
	.addr_bias(addr_bias), 
	.addr_bias_genmat(addr_bias_genmat), 
	.addr_bias_mult(addr_bias_mult), 
	.server_counter_start(server_counter_start),
	.op_done(op_done),
	.no_ntt(no_ntt),
	.debug_reset(debug_reset),
	.hash_g_start(1'b0),
	.hash_h_start(hash_h_start),
	.read_external(read_external), 
	.read_addr(read_addr),
	.accumulate_start(accumulate_start), 
	.read_data1(read_data1), 
	.read_data2(read_data2), 
	.read_data3(read_data3), 
	.decrypt_start(decrypt_start), 
	.ext_addr(ext_addr), 
	.ntt_start_out(ntt_start_out), 
	.external_write(external_write), 
	.external_data(external_data),
	.extr_mul(extr_mul), 
	.no_error(no_error), 
	.intt_start(intt_start), 
	.v_start(v_start), 
	.decode_start(decode_start), 
	.ep_gen(ep_gen), 
	.ep_accumulate(ep_accumulate), 
	.addr_bias_acc(addr_bias_acc), 
	.start_encr(start_encr), 
	.encr_message(encr_message), 
	.msg_in(msg_in), 
	.mem_pk_sk_transfer(mem_pk_sk_transfer), 
	.mem_sk_pk_transfer(mem_sk_pk_transfer), 
	.addr_bias1(addr_bias1), 
	.b_out_en(b_out_en), 
	.v_out_en(v_out_en)); //gen_a

serial_out u_serial_out (
        .clk(CLK),
        .rst_n(RST_N),
        .capture(read_external),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .read_data3(read_data3),
        .serial_out(serial_out)
    );


endmodule
