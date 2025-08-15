`timescale 1ns/1ps

module small_kyber_top_fsm
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
input v_path_decrypt,
input b_path_decrypt,
output trigger,

output reg start_keygen,
output reg decrypt_start,
output reg [10:0] ext_addr,
output reg external_write,
output wire [15:0] external_data,
output reg extr_mul,
output reg intt_start,
output reg v_start,
output reg decode_start,
output reg ep_gen,
output reg ep_accumulate,
output reg [10:0] addr_bias_acc,
output reg start_encr,
output reg mem_pk_sk_transfer,
output reg mem_sk_pk_transfer,
output reg [10:0] addr_bias1,
output reg b_out_en,
output reg v_out_en,

output ready,
output temp_coeff_array,
output reg [7:0] x_addr,
output reg [7:0] y_addr,
output reg [10:0] addr_bias,
output reg [10:0] addr_bias_genmat,
output reg [10:0] addr_bias_mult,
output reg server_counter_start,
input op_done,
output reg no_ntt,
output reg debug_reset,
output reg hash_h_start,
output reg accumulate_start,
output reg ntt_start_out,
output reg no_error

);



//register and wires
reg [6:0] state, next_state;
reg [7:0] error_y_addr, x_addr_reg;
reg test_secret_gen;
reg [2:0] dummy_wait;
reg [10:0] addr_bias_next;
reg [10:0] addr_bias1_next;
reg [7:0] y_addr_next;
reg [10:0] addr_bias_acc_next;
reg [10:0] addr_bias_mult_next;
reg [7:0] error_y_addr_next, x_addr_reg_next;
reg [2:0] dummy_wait_next;
reg [10:0] addr_bias_genmat_next;
// Additional signals that didn't have _next
reg start_keygen_next;
reg decrypt_start_next;
reg external_write_next;
reg extr_mul_next;
reg intt_start_next;
reg v_start_next;
reg decode_start_next;
reg ep_gen_next;
reg ep_accumulate_next;
reg start_encr_next;
reg mem_pk_sk_transfer_next;
reg mem_sk_pk_transfer_next;
reg b_out_en_next;
reg v_out_en_next;
reg no_ntt_next;
reg debug_reset_next;
reg hash_h_start_next;
reg accumulate_start_next;
reg ntt_start_out_next;
reg no_error_next;
reg x_addr_next;
reg ext_addr_next;
reg test_secret_gen_next;
reg server_counter_start_next;

//Default register value to write at 0 location
assign external_data = 16'h5055;
// Define next states for output registers
always @(posedge CLK, negedge RST_N) begin
if(RST_N == 0) begin
    start_keygen_next <= 0;
    decrypt_start_next <= 0;
    external_write_next <= 0;
    extr_mul_next <= 0;
    intt_start_next <= 0;
    v_start_next <= 0;
    decode_start_next <= 0;
    ep_gen_next <= 0;
    ep_accumulate_next <= 0;
    start_encr_next <= 0;
    mem_pk_sk_transfer_next <= 0;
    mem_sk_pk_transfer_next <= 0;
    addr_bias1_next <= 0; // assuming addr_bias1 is a reg
    b_out_en_next <= 0;
    v_out_en_next <= 0;
    no_ntt_next <= 0;
    debug_reset_next <= 0;
    hash_h_start_next <= 0;
    accumulate_start_next <= 0;
    ntt_start_out_next <= 0;
    no_error_next <= 0;
    x_addr_next <= 0;
    ext_addr_next <= 0;
    test_secret_gen_next <= 0; 
    ///addr_bias_acc_next <= 0;
    dummy_wait_next <= 0;
    ///x_addr_reg_next <= 0;
    ///error_y_addr_next <= 0;
    server_counter_start_next <= 0;
end
else 
begin
    start_keygen_next <= start_keygen; // Assign current values
    decrypt_start_next <= decrypt_start;
    external_write_next <= external_write;
    extr_mul_next <= extr_mul;
    intt_start_next <= intt_start;
    v_start_next <= v_start;
    decode_start_next <= decode_start;
    ep_gen_next <= ep_gen;
    ep_accumulate_next <= ep_accumulate;
    start_encr_next <= start_encr;
    mem_pk_sk_transfer_next <= mem_pk_sk_transfer;
    mem_sk_pk_transfer_next <= mem_sk_pk_transfer;
    addr_bias1_next <= addr_bias1; // assuming addr_bias1 didn't have _next
    b_out_en_next <= b_out_en;
    v_out_en_next <= v_out_en;
    no_ntt_next <= no_ntt;
    debug_reset_next <= debug_reset;
    hash_h_start_next <= hash_h_start;
    accumulate_start_next <= accumulate_start;
    ntt_start_out_next <= ntt_start_out;
    no_error_next <= no_error;
    x_addr_next <= x_addr;
    ext_addr_next <= ext_addr;
    test_secret_gen_next <= test_secret_gen; 
    //addr_bias_acc_next <= addr_bias_acc;
    dummy_wait_next <= dummy_wait;
    //x_addr_reg_next <= x_addr_reg;
    //error_y_addr_next <= error_y_addr;
    server_counter_start_next <= server_counter_start;
end
end
assign trigger = (state == 7'd64); 


always @(posedge CLK, negedge RST_N) begin // plaintext counter setup
    if(RST_N == 1'b0) begin
        state <= 1'b0;
    end else begin
        state <= next_state;
    end
end
always @(posedge CLK, negedge RST_N) begin // plaintext counter setup
    if(RST_N == 1'b0) begin
        x_addr_reg_next <= 8'b0;
	error_y_addr_next <= 8'b0;
	//dummy_wait_next <= 3'b0;
	addr_bias_genmat_next <= 11'b0;
    end else begin
        x_addr_reg_next <= x_addr_reg;
	error_y_addr_next <= error_y_addr;
	//dummy_wait_next <= dummy_wait;
	addr_bias_genmat_next <= addr_bias_genmat;
    end
end

always @(posedge CLK, negedge RST_N) begin // plaintext counter setup
    if(RST_N == 1'b0) begin
        addr_bias_next <= 11'b0;
    end else begin
        addr_bias_next <= addr_bias;
    end
end
always @(posedge CLK, negedge RST_N) begin // plaintext counter setup
    if(RST_N == 1'b0) begin
        y_addr_next <= 8'b0;
    end else begin
        y_addr_next <= y_addr;
    end
end
always @(posedge CLK, negedge RST_N) begin // plaintext counter setup
    if(RST_N == 1'b0) begin
        addr_bias_acc_next <= 11'b0;
    end else begin
        addr_bias_acc_next <= addr_bias_acc;
    end
end
always @(posedge CLK, negedge RST_N) begin // plaintext counter setup
    if(RST_N == 1'b0) begin
        addr_bias_mult_next <= 11'b0;
    end else begin
        addr_bias_mult_next <= addr_bias_mult;
    end
end

// Mode FSM Next state logic
always @(*) begin
    next_state = state;
    case (state)
        7'b0:begin 
    //         if(start) begin //This state for idle
	// 		next_state = 3'd1;
	// 		y_addr = 0;
	// 		x_addr = 0;
	// 		external_write = 0;
	// 		ext_addr = 0;
	// 		ntt_start_out = 0;
	// 		decode_start = 0;
	// 		v_start = 0;
	// 		intt_start = 0;
	// 		no_error = 0;
	// 		extr_mul = 0;
	// 		debug_reset = 0;
	// 		hash_h_start = 0;
	// 		//read_external = 0;
	// 		//read_addr = 0;
	// 		accumulate_start = 0;
	//  		server_counter_start = 0;
	// 		ep_gen = 0;
	// 		decrypt_start = 0;
	// 		addr_bias_acc = 0;
	// 		start_keygen = 1;
	// 		start_encr = 0;
	// 		ep_accumulate = 0;
	// 		mem_pk_sk_transfer = 0; 
	// 		mem_sk_pk_transfer = 0;
	// 		addr_bias1 = 0;
	// 		addr_bias = 0;
	// 		b_out_en = 0; 
	// 		v_out_en = 0;
	// 		test_secret_gen = 0; 
	// 		dummy_wait = 0;
	// 		x_addr_reg = 8'd0;
	// addr_bias_genmat = 11'd64;
	// addr_bias_mult = 11'h0;
	// error_y_addr = 0;

                    //   end
			next_state = start ? 7'd1 : 0;
			y_addr = start ? 0 : 0;
			x_addr = start ? 0 : 0;
			external_write = start ? 0 : 0;
			ext_addr = start ? 0 : 0;
			ntt_start_out = start ? 0 : 0;
			decode_start = start ? 0 : 0;
			v_start = start ? 0 : 0;
			intt_start = start ? 0 : 0;
			no_error = start ? 0 : 0;
			extr_mul = start ? 0 : 0;
			debug_reset = start ? 0 : 0;
			hash_h_start = start ? 0 : 0;
			//read_external = start ? 0 : 0;
			//read_addr = start ? 0 : 0;
			accumulate_start = start ? 0 : 0;
			server_counter_start = start ? 0 : 0;
			ep_gen = start ? 0 : 0;
			decrypt_start = start ? 0 : 0;
			addr_bias_acc = start ? 0 : 0;
			start_keygen = start ? 1 : 0;
			start_encr = start ? 0 : 0;
			ep_accumulate = start ? 0 : 0;
			mem_pk_sk_transfer = start ? 0 : 0;
			mem_sk_pk_transfer = start ? 0 : 0;
			addr_bias1 = start ? 0 : 0;
			addr_bias = start ? 0 : 0;
			b_out_en = start ? 0 : 0;
			v_out_en = start ? 0 : 0;
			test_secret_gen = start ? 0 : 0;
			dummy_wait = start ? 0 : 0;
			x_addr_reg = start ? 8'd0 : 0;
			addr_bias_genmat = start ? 11'd64 : 0;
			addr_bias_mult = start ? 11'h0 : 0;
			error_y_addr = start ? 0 : 0;
			no_ntt = start ? 0 : 0;
/*
			next_state = start ? 3'd1 : state;
			y_addr = start ? 0 : y_addr;
			x_addr = start ? 0 : x_addr;
			external_write = start ? 0 : external_write;
			ext_addr = start ? 0 : ext_addr;
			ntt_start_out = start ? 0 : ntt_start_out;
			decode_start = start ? 0 : decode_start;
			v_start = start ? 0 : v_start;
			intt_start = start ? 0 : intt_start;
			no_error = start ? 0 : no_error;
			extr_mul = start ? 0 : extr_mul;
			debug_reset = start ? 0 : debug_reset;
			hash_h_start = start ? 0 : hash_h_start;
			//read_external = start ? 0 : read_external;
			//read_addr = start ? 0 : read_addr;
			accumulate_start = start ? 0 : accumulate_start;
			server_counter_start = start ? 0 : server_counter_start;
			ep_gen = start ? 0 : ep_gen;
			decrypt_start = start ? 0 : decrypt_start;
			addr_bias_acc = start ? 0 : addr_bias_acc;
			start_keygen = start ? 1 : start_keygen;
			start_encr = start ? 0 : start_encr;
			ep_accumulate = start ? 0 : ep_accumulate;
			mem_pk_sk_transfer = start ? 0 : mem_pk_sk_transfer;
			mem_sk_pk_transfer = start ? 0 : mem_sk_pk_transfer;
			addr_bias1 = start ? 0 : addr_bias1;
			addr_bias = start ? 0 : addr_bias;
			b_out_en = start ? 0 : b_out_en;
			v_out_en = start ? 0 : v_out_en;
			test_secret_gen = start ? 0 : test_secret_gen;
			dummy_wait = start ? 0 : dummy_wait;
			x_addr_reg = start ? 8'd0 : x_addr_reg;
			addr_bias_genmat = start ? 11'd64 : addr_bias_genmat;
			addr_bias_mult = start ? 11'h0 : addr_bias_mult;
			error_y_addr = start ? 0 : error_y_addr;
				*/
        end
 	7'd1:begin // This state is for error generation 
            		 begin

			external_write = 0;
			ext_addr = 0;
			ntt_start_out = 0;
			decode_start = 0;
			v_start = 0;
			intt_start = 0;
			no_error = 0;
			extr_mul = 0;
			debug_reset = 0;
			hash_h_start = 0;
			accumulate_start = 0;
			ep_gen = 0;
			decrypt_start = 0;
			addr_bias_acc = 0;
			start_keygen = 1;
			start_encr = 0;
			ep_accumulate = 0;
			mem_pk_sk_transfer = 0; 
			mem_sk_pk_transfer = 0;
			addr_bias1 = 0;
			b_out_en = 0; 
			v_out_en = 0;
			test_secret_gen = 0; 
			dummy_wait = 0;
			x_addr_reg = 8'd0;
			error_y_addr = error_y_addr;

			//	next_state = 3'd1;
			x_addr = 8'h0;
			y_addr = 8'd9;
			no_ntt = 0;
			addr_bias = 11'd576;
			addr_bias_genmat = 11'd64;
			addr_bias_mult = 11'h0;
			server_counter_start = 1; 
			// if(op_done) 
			// 	next_state = 3'd2;
			// else 
			// 	next_state = state;
			next_state = op_done ? 7'd2 : state;
        end
	    
        end
	7'd2: begin //{
//			x_addr = x_addr;
//			external_write = external_write;
//			ext_addr = ext_addr;
//			ntt_start_out = ntt_start_out;
//			decode_start = decode_start;
//			v_start = v_start;
//			intt_start = intt_start;
//			no_error = no_error;
//			extr_mul = extr_mul;
//			debug_reset = debug_reset;
//			hash_h_start = hash_h_start;
//			accumulate_start = accumulate_start;
//			ep_gen = ep_gen;
//			decrypt_start = decrypt_start;
//			addr_bias_acc = addr_bias_acc;
//			start_keygen = start_keygen;
//			start_encr = start_encr;
//			ep_accumulate = ep_accumulate;
//			mem_pk_sk_transfer = mem_pk_sk_transfer; 
//			mem_sk_pk_transfer = mem_sk_pk_transfer;
//			addr_bias1 = addr_bias1;
//			b_out_en = b_out_en; 
//			v_out_en = v_out_en;
//			test_secret_gen = test_secret_gen; 
//			dummy_wait = dummy_wait;
//			x_addr_reg = x_addr_reg;
			//	error_y_addr = error_y_addr;
			//==============================================
			x_addr = x_addr_next;
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			error_y_addr = error_y_addr_next;

//===============================================
			server_counter_start = 0;	
			next_state = 7'd3;
			addr_bias = 11'h0;
			addr_bias_genmat = 11'd576;	
			addr_bias_mult = 11'h0;
			y_addr = 0;
			no_ntt = 0;	
	end //}

	7'd3: begin //{
			x_addr = x_addr_next;
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next; // Archisman check
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_genmat = addr_bias_genmat_next;
			error_y_addr = error_y_addr_next;


			server_counter_start = 1;


			next_state = (op_done & y_addr_next == 8 & test_secret_gen) ? 7'd53 :
				(op_done & y_addr_next == 9) ? 7'd5 :
				(op_done) ? 7'd4 : state;

			y_addr = (op_done) ? ((op_done & y_addr_next == 8 & test_secret_gen) ? y_addr_next :
								(op_done & y_addr_next == 9) ? y_addr_next :
								y_addr_next + 1) : y_addr_next;

			addr_bias = (op_done) ? addr_bias_next + ((op_done & y_addr_next == 8 & test_secret_gen) ? 0 : 
													(op_done & y_addr_next == 9) ? 0 : 32) : addr_bias_next;

			addr_bias_mult = (op_done) ? ((op_done & y_addr_next == 8 & test_secret_gen) ? addr_bias_mult_next :
										(op_done & y_addr_next == 9) ? addr_bias_mult_next :
										(y_addr == 1) ? addr_bias_mult_next : addr_bias_mult_next + 64) : addr_bias_mult_next;

	end //}
	7'd4: begin //{
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			error_y_addr = error_y_addr_next;

//======================================
			server_counter_start = 0;
			x_addr = 0;
			y_addr = y_addr_next;
			addr_bias = addr_bias_next;
			addr_bias_genmat = 11'd576;	
			next_state = 7'd3;
	end //}
	7'd5: begin //{
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			//accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start; 
			//addr_bias = addr_bias;
			//accumulate_start = accumulate_start;
//======================================
			server_counter_start = 0; 
			addr_bias = addr_bias_next;
			accumulate_start = 1;
			next_state = 7'd6;	
	end //}
	7'd6: begin //{
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			//addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			//x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			//error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start; 
			//addr_bias = addr_bias;
			//accumulate_start = accumulate_start;

//========================
			server_counter_start = 1;
			addr_bias = addr_bias_next;
			error_y_addr = 8'd10;
			x_addr_reg = 8'd0;
			// if(op_done) begin 
			// 	next_state = 3'd7;
			// 	//server_counter_start = 0;
			// 	addr_bias_acc = addr_bias_acc_next + 64;
			// end
			// else begin
			// 	next_state = state;
			// 	addr_bias_acc = addr_bias_acc_next;
			// end	
			next_state = op_done ? 7'd7 : state;
			addr_bias_acc = op_done ? addr_bias_acc_next + 64 : addr_bias_acc_next;

	end //}
	7'd7: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			//x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;
			accumulate_start = accumulate_start_next;

//==================================
			server_counter_start = 0;
			next_state = 7'd8;
			x_addr = x_addr;
			addr_bias = addr_bias;
			//error_y_addr = 8'd10;
	end
	7'd8: begin //{
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			//accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			//x_addr_reg = x_addr_reg_next;
			//no_ntt = no_ntt_next;
			//addr_bias_mult = addr_bias_mult_next;
			//addr_bias_genmat = addr_bias_genmat_next;	
			//x_addr = x_addr_next;
			//y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start; 
			//addr_bias = addr_bias;

//=====================================================
			 x_addr = 8'h0;
			y_addr = error_y_addr_next;
			no_ntt = 0;
			addr_bias = 11'd576;
			addr_bias_genmat = 11'd64;
			addr_bias_mult = 11'h0;
			accumulate_start = 0;
			server_counter_start = 1; 
			// if(op_done) begin
			// 	next_state = 4'd9;
			// 	x_addr_reg = x_addr_reg_next + 1'b1;
			// end
			// else begin
			// 	next_state = state;
			// 	x_addr_reg = x_addr_reg_next;
			// end
			next_state = op_done ? 7'd9 : state;
			x_addr_reg = op_done ? x_addr_reg_next + 1'b1 : x_addr_reg_next;

	end //}
	7'd9: begin //{
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			//no_ntt = no_ntt_next;
			//addr_bias_mult = addr_bias_mult_next;
			//addr_bias_genmat = addr_bias_genmat_next;	
			//x_addr = x_addr_next;
			//y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start; 
			//addr_bias = addr_bias;

//=================================
			server_counter_start = 0;	
			next_state = 7'd10;
			addr_bias = 11'h0;
			addr_bias_genmat = 11'd576;	
			addr_bias_mult = 11'h0;
			x_addr = x_addr_reg_next;
			y_addr = 0;
			no_ntt = 0;	
	end //}
	7'd10: begin //{
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			//addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_reg_next;
//			//y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
//			//server_counter_start = server_counter_start_next;
			//=============================================== 
//				external_write = external_write;
//			ext_addr = ext_addr;
//			ntt_start_out = ntt_start_out;
//			decode_start = decode_start;
//			v_start = v_start;
//			intt_start = intt_start;
//			no_error = no_error;
//			extr_mul = extr_mul;
//			debug_reset = debug_reset;
//			hash_h_start = hash_h_start;
//			accumulate_start = accumulate_start;
//			ep_gen = ep_gen;
//			decrypt_start = decrypt_start;
//			addr_bias_acc = addr_bias_acc;
//			start_keygen = start_keygen;
//			start_encr = start_encr;
//			ep_accumulate = ep_accumulate;
//			mem_pk_sk_transfer = mem_pk_sk_transfer; 
//			mem_sk_pk_transfer = mem_sk_pk_transfer;
//			addr_bias1 = addr_bias1;
//			b_out_en = b_out_en; 
//			v_out_en = v_out_en;
//			test_secret_gen = test_secret_gen; 
//			dummy_wait = dummy_wait;
//			x_addr_reg = x_addr_reg;
//			no_ntt = no_ntt;
//			//addr_bias_mult = addr_bias_mult;
//			addr_bias_genmat = addr_bias_genmat;	
//			x_addr = x_addr;
			//y_addr = y_addr;
//			error_y_addr = error_y_addr;
			//server_counter_start = server_counter_start; 
			//addr_bias = addr_bias;
		//addr_bias = addr_bias;

//=====================================
			server_counter_start = 1;
	// 		if(op_done & y_addr_next == 9) begin
	// 			next_state = 4'd12;
	// 			y_addr = y_addr_next; 
	// 			addr_bias = addr_bias_next;
	// 			addr_bias_mult = addr_bias_mult_next;
	// 		end
	// 		else if(op_done) begin 
	// 			next_state = 4'd11;
	// 			y_addr = y_addr_next + 1; 
	// 			addr_bias = addr_bias_next + 32;
	// 			addr_bias_mult = (y_addr == 1) ? addr_bias_mult_next : addr_bias_mult_next + 64;
	// 		end
	// //		else if(op_done) begin 
	// //		next_state = 4'd11;
	// //		y_addr = y_addr_next + 1; 
	// //		addr_bias = addr_bias_next + 32;
	// //		addr_bias_mult = addr_bias_mult_next + 64;
	// //		end
	// 		else begin
	// 			next_state = state;
	// 			y_addr = y_addr_next; 
	// 			addr_bias = addr_bias_next;
	// 			addr_bias_mult = addr_bias_mult_next;
	// 		end

			next_state = op_done ? (y_addr_next == 9 ? 7'd12 : 7'd11) : state;
			y_addr = op_done ? (y_addr_next == 9 ? y_addr_next : y_addr_next + 1) : y_addr_next;
			addr_bias = op_done ? (y_addr_next == 9 ? addr_bias_next : addr_bias_next + 32) : addr_bias_next;
			addr_bias_mult = op_done ? (y_addr_next == 9 ? addr_bias_mult_next : (y_addr == 1 ? addr_bias_mult_next : addr_bias_mult_next + 64)) : addr_bias_mult_next;
	end //}
	7'd11: begin //{
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			//addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			//y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;

//===========================
			server_counter_start = 0;
			addr_bias_genmat = 11'd576;	
			next_state = 7'd10;
			y_addr = y_addr_next;
	end //}
	7'd12: begin //{
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			//accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_reg_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;

//================================
			server_counter_start = 0; 
			accumulate_start = 1;
			next_state = 7'd13;
	end //}
	7'd13: begin //{
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			//addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_reg_next;
			y_addr = y_addr_next;
			//error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;

//===================================
			server_counter_start = 1; 
			// if(op_done & x_addr_reg_next == 8) begin
			// 	next_state = 4'd14;
			// 	error_y_addr = error_y_addr_next;
			// 	addr_bias_acc = addr_bias_acc_next;
			// end
			// else if(op_done) begin
			// 	next_state = 4'd7;
			// 	error_y_addr = error_y_addr_next + 1'b1;
			// 	addr_bias_acc = addr_bias_acc_next + 64;
			// end
			// else begin
			// 	next_state = state;
			// 	error_y_addr = error_y_addr_next;
			// 	addr_bias_acc = addr_bias_acc_next;
			// end	

			next_state = op_done ? (x_addr_reg_next == 8 ? 7'd14 : 7'd7) : state;
			error_y_addr = op_done ? (x_addr_reg_next == 8 ? error_y_addr_next : error_y_addr_next + 1'b1) : error_y_addr_next;
			addr_bias_acc = op_done ? (x_addr_reg_next == 8 ? addr_bias_acc_next : addr_bias_acc_next + 64) : addr_bias_acc_next;
	end //}
	7'd14: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			//hash_h_start = hash_h_start_next;
			//accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			//start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;

//=================================
			hash_h_start = 0;
			server_counter_start = 0;
			accumulate_start = 0; 
			start_keygen = 0;
			next_state = 7'd15;
	end
	7'd15: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			//hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;
//=================================
			server_counter_start = 1;
			next_state = 7'd16;
			hash_h_start = 0;
	end
	7'd16: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			//hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			server_counter_start = 1; 
			addr_bias = addr_bias_next;
//=================================

			hash_h_start = 1;
			// if(op_done)
			// 	next_state = 5'd17;
			// else 
			// 	next_state = state;

			next_state = op_done ? 7'd17 : state;
	end
	7'd17: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			//hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;
//=================================
			hash_h_start = 0;
			server_counter_start = 0;
			next_state = 7'd18;
	end
	7'd18: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			//no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			//addr_bias_acc = addr_bias_acc_next;
			//start_keygen = start_keygen_next;
			//start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			//x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			//x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;


//============================================================
		// if(start_encr_next) begin
		// 	next_state = 5'd19;
		// 	start_encr = start_encr_next;
		// 	x_addr = x_addr_reg_next;
		// 	x_addr_reg = x_addr_reg_next;
		// 	start_keygen = start_keygen_next;
		// 	no_error = no_error_next;
		// 	addr_bias_acc = addr_bias_acc_next;
		// end
		// else begin
		// 	start_encr = 1;
		// 	x_addr = 0;
		// 	x_addr_reg = 0;
		// 	start_keygen = 1;
		// 	next_state = 3'd2;
		// 	no_error = 1;
		// 	addr_bias_acc = 640;
		// end

			next_state = start_encr_next ? 7'd19 : 7'd2;
			start_encr = start_encr_next ? start_encr_next : 1;
			x_addr = start_encr_next ? x_addr_reg_next : 0;
			x_addr_reg = start_encr_next ? x_addr_reg_next : 0;
			start_keygen = start_encr_next ? start_keygen_next : 1;
			no_error = start_encr_next ? no_error_next : 1;
			addr_bias_acc = start_encr_next ? addr_bias_acc_next : 640;
	end
	//5'd19: begin
	//server_counter_start = 1;
	//intt_start = 1;
	//addr_bias = 0;
	//wait(op_done);
	//server_counter_start = 0;
	//accumulate_start = 0;
	//intt_start = 0;
	//end 
//state to be updated from here
	7'd19: begin

			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			//extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			//accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			//mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			//addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;

//================================================
			server_counter_start = 0;
			accumulate_start = 0;
			extr_mul = 0;
			next_state = 7'd20;
			mem_pk_sk_transfer = 1;
			addr_bias_genmat = 640;
			addr_bias = 288;
	end
	7'd20: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;


//================================================================
			server_counter_start = 1;
			// if(op_done)
			// 	next_state = 5'd21;
			// else
			// 	next_state = state;
			next_state = op_done ? 7'd21 : state;
	end
	7'd21: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			//extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			//accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			//mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			//addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;


//========================================================================
			server_counter_start = 0;
			accumulate_start = 0;
			mem_pk_sk_transfer = 0;
			addr_bias_genmat = 576;
			extr_mul = 0;
			next_state = 7'd22;
	end
	7'd22: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;


//===========================================================================
			next_state = 7'd23;
	end
	7'd23: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//==============================================================
			next_state = 7'd24;
	end
	7'd24: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;

//=================================================================

			next_state = 7'd25;
	end
	7'd25: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;

//==============================================================

			next_state = 7'd26;
	end
	7'd26: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//==================================================
			next_state = 7'd27;
	end

	7'd27: begin
     		external_write = external_write_next;
     		ext_addr = ext_addr_next;
     		ntt_start_out = ntt_start_out_next;
     		decode_start = decode_start_next;
     		v_start = v_start_next;
     		//intt_start = intt_start_next;
     		no_error = no_error_next;
     		extr_mul = extr_mul_next;
     		debug_reset = debug_reset_next;
     		hash_h_start = hash_h_start_next;
     		accumulate_start = accumulate_start_next;
     		ep_gen = ep_gen_next;
     		decrypt_start = decrypt_start_next;
     		addr_bias_acc = addr_bias_acc_next;
     		start_keygen = start_keygen_next;
     		start_encr = start_encr_next;
     		ep_accumulate = ep_accumulate_next;
     		mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
     		mem_sk_pk_transfer = mem_sk_pk_transfer_next;
     		addr_bias1 = addr_bias1_next;
     		b_out_en = b_out_en_next; 
     		v_out_en = v_out_en_next;
     		test_secret_gen = test_secret_gen_next; 
     		dummy_wait = dummy_wait_next;
     		x_addr_reg = x_addr_reg_next;
     		no_ntt = no_ntt_next;
     		addr_bias_mult = addr_bias_mult_next;
     		addr_bias_genmat = addr_bias_genmat_next;	
     		x_addr = x_addr_next;
     		y_addr = y_addr_next;
     		error_y_addr = error_y_addr_next;
     		//server_counter_start = server_counter_start_next; 
     		//addr_bias = addr_bias_next;



//=================================================
			server_counter_start = 1;
			intt_start = 1;
			// if(op_done & addr_bias_next == 576) begin
			// 	next_state = 5'd29;
			// 	addr_bias = addr_bias_next;
			// end
			// else if(op_done) begin 
			// 	next_state = 5'd28; 
			// 	addr_bias = addr_bias_next + 32;
			// end
			// else begin
			// 	next_state = state;
			// 	addr_bias = addr_bias_next;
			// end	
			next_state = op_done & (addr_bias_next == 576) ? 7'd29 :
					op_done ? 7'd28 : state;
			addr_bias = op_done & (addr_bias_next == 576) ? addr_bias_next :
					op_done ? addr_bias_next + 32 : addr_bias_next;
	end
	7'd28: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			//intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			//x_addr = x_addr_next;
			//y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//==============================================================
			server_counter_start = 0;
			intt_start = 0;
			next_state = 7'd22;
			y_addr = 8'd9;
			x_addr = 8'd0;
	end
	7'd29: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			//intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;


//===============================================================
			server_counter_start = 0;
			intt_start = 0;
			next_state = 7'd30;	
			addr_bias = 11'd576;
		end //need to fix error
	7'd30: begin
 		external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			//intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//================================================================
			server_counter_start = 0;
			intt_start = 0;
			next_state = 7'd31;
	end 
	7'd31: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			//ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			//start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			//addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			//no_ntt = no_ntt_next;
			//addr_bias_mult = addr_bias_mult_next;
			//addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			//y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;



//=================================================================
			no_ntt = 0;
			addr_bias_genmat = 11'd64;
			addr_bias_mult = 11'h0;
				server_counter_start = 1;
			start_keygen = 1; 
			ep_gen = 1;
			// if(op_done & y_addr_next == 17 & b_path_decrypt) begin
			// 	next_state = 6'd32;// either 32 or 34 
			// 	addr_bias = 288;
			// 	y_addr = y_addr_next;
			// 	addr_bias1 = 576;
			// end
			// else if(op_done & y_addr_next == 17 & v_path_decrypt) begin //testing through this path
			// 	next_state = 6'd34;// either 32 or 34 
			// 	addr_bias = 288;
			// 	addr_bias1 = 576;
			// 	y_addr = y_addr_next;
			// end
			// else if(op_done)
			// begin
			// 	next_state = 5'd30;
			// 	addr_bias1 = addr_bias1_next;
			// 	y_addr = y_addr_next + 1'b1;
			// 	addr_bias = addr_bias_next + 32;
			// end
			// else begin
			// 	next_state = state;// either 32 or 34 
			// 	addr_bias = addr_bias_next;
			// 	y_addr = y_addr_next;
			// 	addr_bias1 = addr_bias1_next;
			// end
			next_state = op_done ? 
				(y_addr_next == 17 ? (b_path_decrypt ? 7'd32 : (v_path_decrypt ? 7'd34 : 7'd30)) : 5'd30) 
				: state;

			addr_bias = op_done ? 
						(y_addr_next == 17 ? 288 : addr_bias_next + 32) 
						: addr_bias_next;

			y_addr = op_done ? 
						(y_addr_next == 17 ? y_addr_next : y_addr_next + 1'b1) 
						: y_addr_next;

			addr_bias1 = op_done ? 
						(y_addr_next == 17 ? 576 : addr_bias1_next) 
						: addr_bias1_next;
	end
	7'd32: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			//b_out_en = b_out_en_next; 
			//v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//======================================================================
			server_counter_start = 0;
			next_state = 7'd33;
			b_out_en = 1;
			v_out_en = 0;
	end
	7'd33: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			//ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			//addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			//addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;



//===============================================================================
			ep_accumulate = 1;
			server_counter_start = 1;
			// if(addr_bias_next == 576 && op_done) begin
			// 	next_state = 6'd44;
			// 	addr_bias = addr_bias_next;
			// 	addr_bias1 = addr_bias1_next;
			// 	addr_bias_mult = addr_bias_mult_next;
			// end
			// else if(op_done) begin
			// 	next_state = 6'd32;
			// 	addr_bias = addr_bias_next+32;
			// 	addr_bias1 = addr_bias1_next+32;
			// 	addr_bias_mult = addr_bias_mult_next + 64;
			// end
			// else begin
			// 	next_state = state;
			// 	addr_bias = addr_bias_next;
			// 	addr_bias1 = addr_bias1_next;
			// 	addr_bias_mult = addr_bias_mult_next;
			// end
			next_state = (addr_bias_next == 576 && op_done) ? 7'd44 : 
				(op_done ? 7'd32 : state);

			addr_bias = op_done ? 
						(addr_bias_next == 576 ? addr_bias_next : addr_bias_next + 32) 
						: addr_bias_next;

			addr_bias1 = op_done ? 
						(addr_bias_next == 576 ? addr_bias1_next : addr_bias1_next + 32) 
						: addr_bias1_next;

			addr_bias_mult = op_done ? 
						(addr_bias_next == 576 ? addr_bias_mult_next : addr_bias_mult_next + 64) 
						: addr_bias_mult_next;
	end
	7'd34: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			//ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			//ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			//b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//=================================================================================
			server_counter_start = 0;
			ep_gen = 0; 
			ep_accumulate = 0;
			next_state = 7'd35;
			b_out_en = 0;
	end
// Working need to be updated later:: commented for time being :: following
// states will be in order
	7'd35: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			//extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;



//==================================================================
			server_counter_start = 1;
			extr_mul = 1;
			addr_bias = 0;
			// if(op_done)
			// 	next_state = 6'd36;
			// else 
			// 	next_state = state;	
			next_state = op_done ? 7'd36 : state;	
	end
	7'd36: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			//accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//====================================================================
			server_counter_start = 0;
			accumulate_start = 1;
			//extr_mul = 0;
			next_state = 7'd37;
	end
	7'd37: begin
	external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//==========================================================
			server_counter_start = 1;
			// if(op_done)
			// 	next_state = 6'd38;
			// else 
			// 	next_state = state;	
			next_state = op_done ? 7'd38 : state;
	end
	7'd38: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			//intt_start = intt_start_next;
			no_error = no_error_next;
			//extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			//accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//============================================================
			server_counter_start = 0;
			accumulate_start = 0;
			extr_mul = 0;
			next_state = 7'd39;
			intt_start = 1;
	end

	7'd39: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;



//========================================================================
			server_counter_start = 1;
			//intt_start = 1;
			addr_bias = 0;
			// if(op_done) 
			// 	next_state = 6'd40; 
			// else 
			// 	next_state = state;	
			next_state = op_done ? 7'd40 : state;
	end
	7'd40: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			//intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//===========================================================================
			next_state = 7'd41;
			server_counter_start = 0;
			intt_start = 0; 
	end
	7'd41: begin

			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			//ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			//start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			//no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			//addr_bias_genmat = addr_bias_genmat_next;	
			//x_addr = x_addr_next;
			//y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;



//==============================================================================
			y_addr = 8'd18;
			x_addr = 8'd0;
			no_ntt = 0;
		//	#CLK_PERIOD;
			addr_bias = 11'd576;
			addr_bias_genmat = 11'd64;
			//addr_bias_mult = 11'h0;
				server_counter_start = 1;
			start_keygen = 1; 
			ep_gen = 1;
			// if(op_done)
			// 	next_state = 6'd42;
			// else 
			// 	next_state = state;
			next_state = op_done ? 7'd42 : state;
	end
	7'd42: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;



//==================================================================================
			server_counter_start = 0;
			/*if(b_path_decrypt) next_state  = 7'd64;
			else*/ next_state = 7'd43;
			addr_bias = 0;
	end
	7'd43: begin //need to check this later
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			//ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			//addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			//v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;



//===========================================================================
			addr_bias1 = 576;
			//addr_bias = 0;
			ep_accumulate = 1;
			v_out_en = 1; 
			server_counter_start = 1;
			// if(op_done)
			// begin
			// 	next_state = 6'd62;//as of now separate v_decrypt path
			// 	//next_state = 6'd32;// if integrated
			// 	addr_bias = 288;
			// end
			// else begin
			// 	next_state = state;//as of now separate v_decrypt path
			// 	//next_state = 6'd32;// if integrated
			// 	addr_bias = addr_bias_next;
			// end

			next_state = op_done ? 7'd62 : state; //as of now separate v_decrypt path
			addr_bias = op_done ? 288 : addr_bias_next; //as of now separate v_decrypt path
	end
	
	7'd44: begin // to check :: decrypt FSM starts here
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			//ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			//ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			//start_encr = start_encr_next;
			//ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			//v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			//no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			//addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;



//=============================================================
			ep_accumulate = 0;
			ep_gen = 0;
			start_encr = 0;
			server_counter_start = 0;
			next_state = 7'd45;
			v_out_en = 0; 
			//next_state = 6'd34;
			ntt_start_out = 0;
			no_ntt = 0;
			addr_bias = 320;
			addr_bias_genmat = 0;
	end
	7'd45: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			//decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			//no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//==========================================================
			decrypt_start = 1;
			no_ntt = 1;
			server_counter_start = 0;
			//ext_addr = 0; // should be replaced by server_counter internally -- should count only 64 bit
			next_state = 7'd46;
	end
	7'd46: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			//addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;

//=================================================================
			server_counter_start = 1;
			// if(op_done & addr_bias_next == 576) begin
			// 	next_state = 6'd47;
			// 	addr_bias = addr_bias_next;
			// 	addr_bias_genmat = addr_bias_genmat_next;	
			// end
			// else if(op_done)
			// begin
			// 	next_state = 6'd45;
			// 	addr_bias = addr_bias_next + 32;
			// 	addr_bias_genmat = addr_bias_genmat_next + 64;
			// end
			// else begin
			// 	next_state = state;
			// 	addr_bias = addr_bias_next;
			// 	addr_bias_genmat = addr_bias_genmat_next;	
			// end
			next_state = (op_done & addr_bias_next == 576) ? 7'd47 : 
						op_done ? 7'd45 : 
						state;

			addr_bias = op_done & addr_bias_next == 576 ? addr_bias_next : 
						op_done ? addr_bias_next + 32 : 
						addr_bias_next;

			addr_bias_genmat = op_done & addr_bias_next == 576 ? addr_bias_genmat_next : 
							op_done ? addr_bias_genmat_next + 64 : 
							addr_bias_genmat_next;
	end
	7'd47: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			//ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			//decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			//dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			//no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;



//====================================================================
			decrypt_start = 0;
			no_ntt = 0;
			ntt_start_out = 0;
			addr_bias = 320;
			server_counter_start = 0; 
			next_state = 7'd48;
			dummy_wait = 0;
	end
	7'd48: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			//ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//=========================================================================
			server_counter_start = 0;
			ntt_start_out = 0;
			// if(dummy_wait_next == 7 && addr_bias == 608)
			// begin
			// 	next_state = 6'd51;
			// end
			// else if(dummy_wait_next == 7)
			// begin
			// 	next_state = 6'd50;
			// end
			// else begin
			// 	//dummy_wait = dummy_wait + 1;
			// 	next_state = 6'd49;
			// end

			next_state = (dummy_wait_next == 7 && addr_bias == 608) ? 7'd51 : 
              (dummy_wait_next == 7) ? 7'd50 : 
              7'd49;
		
	end
	7'd49: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			//dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//========================================================
			dummy_wait = dummy_wait_next + 1;
			next_state = 7'd48;
	end
	7'd50: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			//ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			//dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;



//===========================================================
			server_counter_start = 1;
			ntt_start_out = 1;
			/*if(addr_bias == 576 & op_done) begin
				next_state = 6'd51;
			dummy_wait = 0;
			end
			else */
			// if(op_done) begin
			// 	next_state = 6'd48;
			// 	addr_bias = addr_bias_next + 32;	
			// 	dummy_wait = 0;
			// end
			// else begin
			// 	next_state = state;
			// 	addr_bias = addr_bias_next;
			// 	dummy_wait = dummy_wait_next;
			// end
			next_state = op_done ? 7'd48 : state;
			addr_bias = op_done ? addr_bias_next + 32 : addr_bias_next;
			dummy_wait = op_done ? 0 : dummy_wait_next;
	end
	7'd51: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			//ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//==========================================================
			ntt_start_out = 0;
			server_counter_start = 0;
			next_state = 7'd52;
	end
	
	7'd52: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			//decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			//test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			//no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			//addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;



//==================================================
			decrypt_start = 0;
			no_ntt = 0;
			server_counter_start = 0;
			addr_bias_genmat = 0;
			addr_bias = 0;
			next_state = 7'd2;
			//next_state = 6'd48;
			//mem_sk_pk_transfer = 1;
			test_secret_gen = 1;
	end
	7'd53: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			//start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			//mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			//addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			//test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			//no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			//addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//=======================================================
			test_secret_gen = 0;
			addr_bias_genmat = 0;
			addr_bias1 = 0;
			start_keygen = 0;  
			server_counter_start = 0;
			mem_sk_pk_transfer = 1;
			next_state = 7'd54;
			no_ntt = 1;
	end
	7'd54: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//============================================================
			server_counter_start = 1;
			// if(op_done)
			// 	next_state = 6'd55;
			// else 
			// 	next_state = state;
			next_state = op_done ? 7'd55 : state;
	end
	7'd55: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;

//=========================================================

			server_counter_start = 0;
			next_state = 7'd56;
	end
	7'd56: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			//extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			//decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			//mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			//no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;



//=========================================================
			mem_sk_pk_transfer = 0;
			no_ntt = 0;
			server_counter_start = 1;
			extr_mul = 1;
			decrypt_start = 0;
			addr_bias = 320;
			// if(op_done)
			// 	next_state = 6'd57;	
			// else 
			// 	next_state = state;	
			next_state = op_done ? 7'd57 : state;
	end
	7'd57: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			//accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			//decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//=====================================================
			server_counter_start = 0; //accumulate should come in this state
			accumulate_start = 1;
			next_state = 7'd58;
			decrypt_start = 0;
			//no_ntt = 1;
	end
	7'd58: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//====================================================================
			server_counter_start = 1;
			// if(op_done)
			// 	next_state = 6'd59;
			// else 
			// 	next_state = state;
			next_state = op_done ? 7'd59 : state;
	end
	7'd59: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			//intt_start = intt_start_next;
			no_error = no_error_next;
			//extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			//accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			//decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;



//===================================================================
			server_counter_start = 0;
			decrypt_start = 0;
			extr_mul = 0;
			accumulate_start = 0;
			next_state = 7'd60;
			intt_start = 1;
			addr_bias = 0;
	end
		//6'd58: begin
	//	server_counter_start = 0;
	//	accumulate_start = 0;
	//	extr_mul = 0;
	//	decrypt_start = 0;
	//	next_state = 6'd59;
	//	intt_start = 1;
	//end

	7'd60: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;


//========================================================================
			server_counter_start = 1;
			//intt_start = 1;
			//addr_bias = 288;
			// if(op_done) 
			// 	next_state = 6'd61; 
			// else 
			// 	next_state = state;	
			next_state = op_done ? 7'd61 : state;
	end
	7'd61: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			//intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//===============================================================
			next_state = 7'd64; // b_decrypt_path
			server_counter_start = 0;
			intt_start = 0; 
	end
	7'd62: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			//ntt_start_out = ntt_start_out_next;
			//decode_start = decode_start_next;
			//v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			//ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			//start_encr = start_encr_next;
			//ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			//v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			//no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			//addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			//addr_bias = addr_bias_next;



//==================================================================
			ep_accumulate = 0;
			ep_gen = 0;
			start_encr = 0;
			server_counter_start = 0;
			//next_state = 6'd45; // This also p[asses the TC
			v_out_en = 0; 
			//next_state = 6'd34;
			ntt_start_out = 0;
			no_ntt = 0;
			addr_bias = 320;
			addr_bias_genmat = 0;
			next_state = 7'd63;
			decode_start = 1;
			v_start = 1;
	end
	7'd63: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



	//====================================================
			server_counter_start = 1;
			// if(op_done)
			// 	next_state = 7'd64;
			// else 
			// 	next_state = state;
			next_state = op_done ? 7'd64 : state;
		
	end
	7'd64: begin
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			//decode_start = decode_start_next;
			//v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			//server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



//=============================================================================
			server_counter_start = 0;
			v_start = 0;
			decode_start = 0;
	end

       default : begin 
			next_state = state;
			external_write = external_write_next;
			ext_addr = ext_addr_next;
			ntt_start_out = ntt_start_out_next;
			decode_start = decode_start_next;
			v_start = v_start_next;
			intt_start = intt_start_next;
			no_error = no_error_next;
			extr_mul = extr_mul_next;
			debug_reset = debug_reset_next;
			hash_h_start = hash_h_start_next;
			accumulate_start = accumulate_start_next;
			ep_gen = ep_gen_next;
			decrypt_start = decrypt_start_next;
			addr_bias_acc = addr_bias_acc_next;
			start_keygen = start_keygen_next;
			start_encr = start_encr_next;
			ep_accumulate = ep_accumulate_next;
			mem_pk_sk_transfer = mem_pk_sk_transfer_next; 
			mem_sk_pk_transfer = mem_sk_pk_transfer_next;
			addr_bias1 = addr_bias1_next;
			b_out_en = b_out_en_next; 
			v_out_en = v_out_en_next;
			test_secret_gen = test_secret_gen_next; 
			dummy_wait = dummy_wait_next;
			x_addr_reg = x_addr_reg_next;
			no_ntt = no_ntt_next;
			addr_bias_mult = addr_bias_mult_next;
			addr_bias_genmat = addr_bias_genmat_next;	
			x_addr = x_addr_next;
			y_addr = y_addr_next;
			error_y_addr = error_y_addr_next;
			server_counter_start = server_counter_start_next; 
			addr_bias = addr_bias_next;



		end
    endcase
end

endmodule
