`timescale 1ns/1ps


//need to bug fix: what suparna said :: Idea is to discard if reqired so that
//just in time is easier
`timescale 1ns/1ps
module server_client_cca #(
    parameter r = 64, // Hash rate in bit
    parameter a = 12, //no of rounds 12 for P12
    parameter b = 12, // no of rounds 12 for P12
    parameter h = 256, // capacity size
    parameter l = 64*2000, // output xof size -- bits out genmatrix > 9*9*64*13, idea is to try to fill unless mem_fill 1
    //parameter y = 40
    parameter y = 64*2 //input message size -- bits
) (
    input           clk,
    input           rst_n,
    input [y-1:0]   message,
    input [y-1:0]   encr_message,
    input [y-1:0] genmat_message,
    input           start_keygen,
    input server_counter_start, 
    output          ready,
    input decrypt_start,
    //input [10:0] b_inp, 
    //input [4:0]v_inp,
    input [10:0] ext_addr,
    input no_error, 
    //input memfill,
    //output [l-1:0] xof 
    //output [63:0] xof,
    //output [12:0] coeff1,
    //output [12:0] coeff2,
    //output reg [12:0] mem_write,
    output reg [63:0] temp_coeff_array, 
    output reg mem_write_en,
    input [7:0] x_addr,
    input [7:0] y_addr,
    input [10:0] addr_bias,
    input [10:0] addr_bias1,
    input [10:0] addr_bias_genmat,
    input [10:0] addr_bias_mult,
    output op_done,
    input no_ntt,
    input debug_reset,
    input read_external,
    input [10:0] read_addr,
    output [15:0] read_data1,
    output [15:0] read_data2,
    output [15:0] read_data3,
    input hash_h_start,
    input hash_g_start,
    input accumulate_start, 
    input ntt_start_out,
    input external_write,
    input [15:0] external_data,
    input extr_mul, 
    input intt_start, 
    input v_start,
    input decode_start,
    //input secret_read,
    output [15:0] read_secret_data,
    input ep_gen,
    input ep_accumulate,
    input [127:0] msg_in, 
    input [10:0] addr_bias_acc,
    input start_encr,
    input mem_pk_sk_transfer,
    input mem_sk_pk_transfer,
    input b_out_en,
    input v_out_en 
    //input sub_start
    //output reg [3:0] array_counter
	 
);
    // Constants
    localparam c = 320-r; //capacity
    localparam nz_m = ((y+1)%r == 0)? 0 : r-((y+1)%r);
    localparam Y = y+1+nz_m;
    localparam s = Y/r; //determines no of time absorbtion required for full messgae
    localparam t = l/r;
    localparam t_genmat = 13;
    localparam t_secret_error = 4;

    //localparam initial_value = ; 

    // FSM States
    localparam IDLE = 'd0;
    localparam INITIALIZE = 'd1;
    localparam ABSORB = 'd2;
    localparam SQUEEZE = 'd3;
    localparam DONE = 'd4;
	localparam ASCON_XOF_IV  = 64'h00400c0000000000;
	localparam ASCON_XOF_IV0 = 64'hb57e273b814cd416;
	localparam ASCON_XOF_IV1 = 64'h2b51042562ae2420;
	localparam ASCON_XOF_IV2 = 64'h66a3a7768ddf2218;
	localparam ASCON_XOF_IV3 = 64'h5aad0a7a8153650c;
	localparam ASCON_XOF_IV4 = 64'h4f3e0e32539493b6;
	localparam NTT_CYCLE = 192;
	localparam POLY_SIZE = 64;
	localparam KEM_Q = 7681;

    // Buffer Variables
    //wire    [63:0]  IV;
    wire [9:0] b_inp;
    wire [4:0] v_inp;
    wire [12:0] b_out;
    wire [12:0] v_out;
    reg [15:0] v_out_reg0;
    reg [15:0] v_out_reg2;
    reg [31:0] v_out_reg1;
    reg v_start_delay0, v_start_delay1, v_start_delay2;
    reg [10:0] ext_addr_delay0, ext_addr_delay1, ext_addr_delay2;
    
    wire    [4:0]   ctr;
    wire            permutation_ready;

    wire    [319:0] P_out; // output from permutation block
	//reg [64-1:0] temp_coeff_array;
	reg [3:0] coeff_counter;
	//reg [12:0] A_write;	
	//reg [3:0] array_counter;	
wire [12:0] secret_error0, secret_error1;		

//======== ascon signal end
//======NTT signal start

reg ntt_write; 
wire [15:0] ntt_in0, ntt_in1;
//wire [10:0] addr_bias;
//wire [10:0] addr_bias_genmat;



wire [15:0] ntt_out0, ntt_out1;
//input [15:0] in0, in1; 
wire [12:0] in0, in1, out0, out1;
wire [15:0] mem_rd0, mem_rd1, mem_rdA, mem_rdB;
wire [15:0] mem_rd_PK; 
reg [12:0] mem_rdB_delay;

reg [5:0] ntt_fill_addr;
wire [15:0] zeta_mem[0:63];
reg [15:0] zeta;
reg ntt_write_delay;

wire sample_s;
wire sample_a;
reg secret_error_write;
reg [10:0] secret_error_addr; 
reg [10:0] addr_a;
reg [10:0] addr_a_delay;

reg genmat_write;

reg [3:0] bit_bias;
reg [75:0] temp_coeff_arrayA;

wire addr_incr;
reg addr_incr_delay;
reg temp_coeff_arrayA_valid;



wire [9:0] server_counter;



reg [9:0]reset_counter; //debug logic
//required for pipeline
reg [15:0] data_in;


reg [9:0] server_counter_delay;
reg [9:0] server_counter_delay_delay;
reg [9:0] server_counter_delay_delay_delay;
reg [9:0] server_counter_delay_delay_delay_delay;
wire [15:0] mem_rdA0, mem_rdA1;
wire [31:0] mul_out;
wire [15:0] compressed_out;
wire [15:0] poly_compressed_out;

wire [12:0] out_en;

// Instantiate the sccca module
wire [75:0] hash_buffer;
wire [3:0] hash_counter, hash_bit_bias;
wire [63:0] hash_buffer_sel_buf;
wire [10:0] hash_read_addr;

hash_counter u_hash_counter (
    // General
    .genmat_message                (genmat_message),

    // Block 1
    .hash_h_start                  (hash_h_start),
    .mem_rd_PK                     (mem_rd_PK),
    .hash_counter                  (hash_counter),
    .hash_bit_bias                 (hash_bit_bias),
    .hash_buffer                   (hash_buffer),

    // Block 2
    .hash_buffer_sel_buf           (hash_buffer_sel_buf),
    .hash_read_addr                (hash_read_addr),

    // Block 3
    .server_counter_start          (server_counter_start),

    // Block 4

    // Clock & Reset
    .clk                           (clk),
    .rst_n                         (rst_n)
);

wire accumulate_start_delay;
wire [3:0] acc_counter;
wire [5:0] addr_acc;
wire [5:0] addr_acc_minus_one;
wire [15:0] accumulate_out3;
wire [15:0] accumulate_out4;
wire [15:0] accumulate_out5;
wire [15:0] accumulate_out; 
wire [15:0] accumulate_out1;
wire [15:0] accumulate_out2;
// Instantiate the acc_counter module
acc_counter u_acc_counter (
    .accumulate_start              (accumulate_start),
    .accumulate_start_delay        (accumulate_start_delay),
    .acc_counter                   (acc_counter),
    .addr_acc                      (addr_acc),
    .addr_acc_minus_one            (addr_acc_minus_one),
    .ep_accumulate                 (ep_accumulate),
    .server_counter                (server_counter),
    .accumulate_out3               (accumulate_out3),
    .mem_rdA0                      (mem_rdA0),
    .mem_rdA1                      (mem_rdA1),
    .mem_rd0                       (mem_rd0),
    .mem_rd1                       (mem_rd1),
    .accumulate_out4               (accumulate_out4),
    .accumulate_out5               (accumulate_out5),
    .out_en                        (out_en),
    .accumulate_out1               (accumulate_out1),
    .accumulate_out2               (accumulate_out2),
    .no_error                      (no_error),
    .mem_rdB                       (mem_rdB),
    .accumulate_out                (accumulate_out),
    .clk                           (clk),
    .rst_n                         (rst_n)
);

polyvec_compress u_pc(accumulate_out4, compressed_out);
poly_compress u_polyc(accumulate_out5, poly_compressed_out);

wire secret_gen; 
wire ntt_start; 
wire [1:0] mode; 
wire [10:0] addr_mult;
wire addr_mult_we;
wire addr_mult_we_reg;
wire [10:0] addr_mult_wr;
wire read_en_mult;

 /*syn_keep*/ server_counter u_server_counter (
    .decode_start           (decode_start),
    .accumulate_start       (accumulate_start),
    .decrypt_start          (decrypt_start),
    .no_ntt                 (no_ntt),
    .mem_pk_sk_transfer     (mem_pk_sk_transfer),
    .mem_sk_pk_transfer     (mem_sk_pk_transfer),
    .ep_accumulate          (ep_accumulate),
    .ep_gen                 (ep_gen),
    .extr_mul               (extr_mul),
    .intt_start             (intt_start),
    .ntt_start_out          (ntt_start_out),
    .addr_a_delay           (addr_a_delay),
    .temp_coeff_arrayA_valid(temp_coeff_arrayA_valid),


    .server_counter         (server_counter),
    .op_done                (op_done),
    .secret_gen             (secret_gen),
    .ntt_start              (ntt_start),
    .mode                   (mode),
    .addr_mult              (addr_mult),
    .addr_mult_we           (addr_mult_we),

    .addr_mult_we_reg       (addr_mult_we_reg),
    .server_counter_start   (server_counter_start),
    .addr_mult_wr           (addr_mult_wr),
    .read_en_mult           (read_en_mult),

    // Clock and reset
    .clk                    (clk),
    .rst_n                  (rst_n)
);


//ASCON state machine  start
// Instantiate the sccca_ascon_fsm module
    wire [319:0] S;
    wire [2:0] state;
    wire ready_1;
    wire [14+1:0] block_ctr; // bug fix-- earlier it was t
    wire [r-1:0] Sr;
    wire [c-1:0] Sc;
    wire [Y-1:0] M;

    // wire [319:0] P_in; // input to permutation block 
    // wire [4:0] rounds;
    // wire permutation_start;
    assign {Sr, Sc} = S;
    assign ready = (state == DONE) ? 1 : 0;
    assign M = start_encr ? (secret_gen) ? {encr_message, y_addr, 1'b1, {55{1'b0}}} : {genmat_message, y_addr, x_addr, 1'b1, {47{1'b0}}} : (secret_gen) ? {message, y_addr, 1'b1, {55{1'b0}}} : {genmat_message, x_addr, y_addr, 1'b1, {47{1'b0}}}; //Archisman 

// Instantiate the sccca_ascon_fsm module
// sccca_ascon_fsm #(
//     .r(64),            // Hash rate in bits
//     .a(12),            // Number of rounds for P12
//     .b(12),            // Number of rounds for P12
//     .h(256),           // Capacity size
//     .l(64*2000),       // Output XOF size
//     .y(64*2)           // Input message size in bits
// ) u_sccca_ascon_fsm (
//     .server_counter_start          (server_counter_start),
//     .state                         (state),
//     .S                             (S),
//     .ready_1                       (ready_1),
//     .block_ctr                     (block_ctr),

//     // ABSORB
//     .P_out                         (P_out),
//     .hash_h_start                  (hash_h_start),
//     .hash_g_start                  (hash_g_start),
//     .hash_counter                  (hash_counter),
//     .start_keygen                  (start_keygen),
//     .permutation_ready             (permutation_ready),

//     // SQUEEZE
//     .secret_gen                    (secret_gen),
//     .addr_a_delay                  (addr_a_delay),
//     .temp_coeff_arrayA_valid       (temp_coeff_arrayA_valid),

//     // Always comb
//     .P_in                          (P_in),
//     .rounds                        (rounds),
//     .permutation_start             (permutation_start),

//     .hash_buffer_sel_buf           (hash_buffer_sel_buf),
//     .Sr                            (Sr),
//     .Sc                            (Sc),
//     .M                             (M),

//     // Clock & Reset
//     .clk                           (clk),
//     .rst_n                         (rst_n)
// );

// Instantiate the sccca_ascon_fsm module
/* presim
sccca_ascon_fsm #(
    .r(64),            // Hash rate in bits
    .a(12),            // Number of rounds for P12
    .b(12),            // Number of rounds for P12
    .h(256),           // Capacity size
    .l(64*2000),       // Output XOF size
    .y(64*2)           // Input message size in bits
)
*/ 
// postsyn
sccca_ascon_fsm u_sccca_ascon_fsm (
    .server_counter_start          (server_counter_start),
    .state                         (state),
    .S                             (S),
    .ready_1                       (ready_1),
    .block_ctr                     (block_ctr),

    // ABSORB
    .P_out                         (P_out),
    .hash_h_start                  (hash_h_start),
    .hash_counter                  (hash_counter),
    .start_keygen                  (start_keygen),
    .permutation_ready             (permutation_ready),

    // SQUEEZE
    .secret_gen                    (secret_gen),
    .addr_a_delay                  (addr_a_delay),
    .temp_coeff_arrayA_valid       (temp_coeff_arrayA_valid),

    // Clock & Reset
    .clk                           (clk),
    .rst_n                         (rst_n)
);
    reg [319:0] P_in; // input to permutation block 
    reg [4:0] rounds;
    reg permutation_start;

    always @(*) begin

        // old code, Mingche commented out
        // // Default Values
        // P_in = 0;
        // rounds = a;
        // permutation_start = 0;

        case (state)
            INITIALIZE: begin
                P_in = S;
                rounds = a;
                permutation_start = (permutation_ready)? 1'b0: 1'b1;
            end

            ABSORB: begin
                 //P_in = {Sr^M[(s-block_ctr)*r-1 -: r], Sc}; //load & pad

                // old code, Mingche commented out 
                // rounds = b;
                // if((hash_h_start & block_ctr == 119) | (~hash_h_start & block_ctr == s)/*block_ctr == s*/) begin //{ //Archisman bug fix
                //     permutation_start = 0;
                // 	P_in = S;
		        // end //}
                // else begin //{
                //     permutation_start = 1;
                //     P_in = hash_h_start|hash_g_start ? {Sr^hash_buffer_sel_buf, Sc}: {Sr^M[(s-block_ctr)*r-1 -: r], Sc}; //load & pad            
		        // end //}
                
                // new code, Mingche added
                rounds = b;
                permutation_start = ((hash_h_start & block_ctr == 119) | (~hash_h_start & block_ctr == s)/*block_ctr == s*/) ? 0 : 1;
                P_in = ((hash_h_start & block_ctr == 119) | (~hash_h_start & block_ctr == s)/*block_ctr == s*/) ? S : 
                            hash_h_start|hash_g_start ? {Sr^hash_buffer_sel_buf, Sc}: {Sr^M[(s-block_ctr)*r-1 -: r], Sc};
            end

            SQUEEZE: begin
                P_in = S;
                // New code, Mingche added
                rounds = a;
                permutation_start = 1;

                // old code, Mingche commented out
                // if(block_ctr == 0)
                //     rounds = a;
                // else
                //     rounds = b;
                // //bug fix 
                // if (t==1)
                //         permutation_start = 0;
                // else
                //         permutation_start = 1;
            end

            // New code, Mingche added
            default: begin
                // // Default Values
                P_in = 0;
                rounds = a;
                permutation_start = 0;                
            end
        endcase
    end


    // Permutation Block
    Permutation p1(
        .clk(clk),
        .reset(~rst_n),
        .S(P_in),
        .out(P_out),
        .done(permutation_ready),
        .ctr(ctr),
        .rounds(rounds),
        .start(permutation_start)
    );
//
    // Round Counter
    RoundCounter RC(
        clk,
        ~rst_n,
        permutation_start,
        permutation_ready,
        ctr
    );



always@(posedge clk, negedge rst_n) begin //{
	if(rst_n == 0) begin //{
		coeff_counter <= 0;
	end //}
	else if (server_counter_start == 1'b0)begin //{
		coeff_counter <= 0;
	end //}
	else if(coeff_counter < 13 && state == SQUEEZE) begin //{12 because permutation round
		coeff_counter <= coeff_counter + 1'b1;
	end //}
	else begin //{
		coeff_counter <= 0;
	end //}
end //}
always@(posedge clk, negedge rst_n) begin //{
	if(rst_n == 0 ) begin //{
		temp_coeff_array <= 0;
		secret_error_write <= 1'b0;

		mem_write_en <= 1'b0; 
		secret_error_addr <= 0;
		bit_bias <= 0;
		addr_a <= 0;
		temp_coeff_arrayA<=0;
	end //}
	else if(server_counter_start == 1'b0) begin //{
		temp_coeff_array <= 0;
		secret_error_write <= 1'b0;

		mem_write_en <= 1'b0; 
		secret_error_addr <= 0;
		bit_bias <= 0;
		addr_a <= 0;
		temp_coeff_arrayA<=0;
	end //}

	else if(state == SQUEEZE & coeff_counter == 0 & secret_gen) begin //{
		//temp_coeff_array[63+bit_bias-:64] <= {S[7+256:256+0], S[15+256:256+8], S[23+256:256+16], S[31+256:256+24], S[39+256:256+32], S[47+256:256+40], S[55+256:256+48], S[63+256:256+56]};
		temp_coeff_array[63:0] <= {S[7+256:256+0], S[15+256:256+8], S[23+256:256+16], S[31+256:256+24], S[39+256:256+32], S[47+256:256+40], S[55+256:256+48], S[63+256:256+56]};
		secret_error_write <= 1'b1;
		bit_bias <= 0;

	end //}

	else if(state == SQUEEZE & (coeff_counter >= 1 & coeff_counter <= 8) & secret_gen) begin //{
		temp_coeff_array <= {8'b0,temp_coeff_array>>8};
		secret_error_addr <= secret_error_addr + 1'b1;
	end //}
	else if(state == SQUEEZE & (coeff_counter == 1) & (~secret_gen) &(bit_bias == 0)) begin //{ load to temp_coeff_arrayA 
        temp_coeff_arrayA <= {12'b0,S[319:256]};
        bit_bias <= bit_bias+ 1'b1;
        addr_a <= addr_a; //room for LUT optimization
        temp_coeff_arrayA_valid <= 1'b0;
	end
	else if(state == SQUEEZE & (coeff_counter == 1) & (~secret_gen) &(bit_bias != 0)) begin //{ load to temp_coeff_arrayA 
        temp_coeff_arrayA[76-bit_bias-:64] <= {S[319:256]};
        bit_bias <= bit_bias+ 1'b1;
        addr_a <= addr_a; //room for LUT optimization
        temp_coeff_arrayA_valid <= 1'b0;
	end
	else if(state == SQUEEZE & (coeff_counter >= 2 && coeff_counter <=5) & (~secret_gen) &(bit_bias == 1)) begin //{ 4 coeff
        temp_coeff_arrayA <= {temp_coeff_arrayA >> 13};
        addr_a <= (temp_coeff_arrayA[12:0] <7681) ? addr_a+1'b1 : addr_a; //room for LUT optimization
        temp_coeff_arrayA_valid <= (temp_coeff_arrayA[12:0] <7681) ? 1'b1 : 1'b0;
	end
	else if(state == SQUEEZE & (coeff_counter ==6) & (~secret_gen) &(bit_bias == 13)) begin //{ 5 coeff 
        temp_coeff_arrayA <= {temp_coeff_arrayA >> 13};
        addr_a <= (temp_coeff_arrayA[12:0] <7681) ? addr_a+1'b1 : addr_a; //room for LUT optimization
        temp_coeff_arrayA_valid <= (temp_coeff_arrayA[12:0] <7681) ? 1'b1 : 1'b0;
        bit_bias <= 0; 
	end
	else if(state == SQUEEZE & (coeff_counter >= 2 && coeff_counter <=6) & (~secret_gen) &(bit_bias != 1)) begin //{ 5 coeff 
        temp_coeff_arrayA <= {temp_coeff_arrayA >> 13};
        addr_a <= (temp_coeff_arrayA[12:0] <7681) ? addr_a+1'b1 : addr_a; //room for LUT optimization
        temp_coeff_arrayA_valid <= (temp_coeff_arrayA[12:0] <7681) ? 1'b1 : 1'b0;
	end
	else if(state == DONE) begin //{
	    addr_a <= 0;
	    temp_coeff_arrayA_valid <= 1'b0;
	end //}
	else begin //{
		temp_coeff_array <= temp_coeff_array;
		secret_error_write <= 1'b0;
		temp_coeff_arrayA_valid <= 1'b0;
	end //}
end //}
cbd c1(.a(temp_coeff_array[3:0]), .r_coeff(secret_error0));
cbd c2(.a(temp_coeff_array[7:4]), .r_coeff(secret_error1));

poly_decompress u_pd(.in(v_inp), .out(v_out));
polyvec_decompress u_pvd(.in(b_inp), .out(b_out));

wire [15:0] debug_sig = mem_rdA << 2;
assign addr_incr = temp_coeff_arrayA_valid & (temp_coeff_arrayA[12:0] < 13'd7681);
always@(posedge clk) v_out_reg0 <= decode_start ? (debug_sig + 3840) : v_out; 
always@(posedge clk) v_out_reg1 <= decode_start ? (v_out_reg0 *139792):(v_start & ext_addr <= 32) ? (v_out_reg0 - mem_rd0) : (v_start) ? (v_out_reg0 - mem_rd1) : 0;
always@(posedge clk) v_out_reg2 <= decode_start ? {14'b0,v_out_reg1[31:30]}: v_out_reg1[15] ? (v_out_reg1 + KEM_Q) : v_out_reg1;
always@(posedge clk) v_start_delay0 <= decode_start ? 1'b1 : v_start;
always@(posedge clk) v_start_delay1 <= v_start_delay0;
always@(posedge clk) v_start_delay2 <= v_start_delay1;
always@(posedge clk) ext_addr_delay0 <= ext_addr;
always@(posedge clk) ext_addr_delay1 <= ext_addr_delay0;
always@(posedge clk) ext_addr_delay2 <= ext_addr_delay1;
always@(posedge clk) addr_incr_delay <= addr_incr;
always@(posedge clk) addr_a_delay <= addr_a;
always@(posedge clk) server_counter_delay <= server_counter;
always@(posedge clk) server_counter_delay_delay <= server_counter_delay;
always@(posedge clk) server_counter_delay_delay_delay <= server_counter_delay_delay;
always@(posedge clk) server_counter_delay_delay_delay_delay <= server_counter_delay_delay_delay;


    wire [10:0] addr_mult_wr6;
    //      mem_2port  poly_bram_true_dport_2
    //    (.addr0(v_start_delay1 ? server_counter_delay :(ep_accumulate & v_out_en) ? (server_counter_delay_delay_delay_delay +addr_bias_mult):/*(ep_accumulate & b_out_en) ? server_counter_delay_delay_delay + addr_bias_mult : v_start_delay1 ? server_counter_delay :*/ accumulate_start ? {acc_counter,addr_acc}:(debug_reset | external_write)? ext_addr : no_ntt ? (addr_a_delay+addr_bias_genmat) : extr_mul ? (addr_mult_wr6):secret_gen ? (addr_mult_wr6+addr_bias_mult) : (addr_a_delay+addr_bias_genmat)),
    //     .clk(clk),
    //     .din0((ep_accumulate & v_out_en) ? poly_compressed_out/*: (ep_accumulate & b_out_en) ? compressed_out*//*accumulate_out4*/ : v_start_delay1? v_out:external_write ? external_data: data_in/*data_indebug_reset ? 1 : no_ntt ? accumulate_out : secret_gen ? accumulate_out :{13'b0, temp_coeff_arrayA[12:0]}*/),
    //     .dout0(mem_rdB),
    //     .we0(ep_accumulate & (~b_out_en) ? 1'b1 : (read_external|accumulate_start) ? 1'b0 : external_write ? 1'b1 : v_start_delay1? 1'b1 :(temp_coeff_arrayA_valid) | addr_mult_we_reg | debug_reset),
    //     //.BRAM_PORTA_0_we((read_external|accumulate_start) ? 1'b0 : external_write ? 1'b1 : v_start_delay2? 1'b1 :((bit_bias == 1 & coeff_counter<=6) | ((bit_bias != 1 & coeff_counter<=7)) ? addr_incr_delay : addr_incr) | addr_mult_we_reg | debug_reset),
    //     .addr1(/*decrypt_start? server_counter : */decode_start ? server_counter : read_external ? read_addr : no_ntt ? (addr_a+addr_bias_genmat) : extr_mul ? addr_mult:(addr_mult+addr_bias_genmat)),
    //     //.BRAM_PORTB_0_clk(clk),
    //     .din1(),
    //     .dout1(mem_rdA),
    //     .we1(1'b0));





assign b_inp = decrypt_start ? mem_rd_PK : 0;
assign v_inp = decode_start ? mem_rdA : 0;
// pipelining in write operations
always@(posedge clk) begin //{
    data_in <= debug_reset ? 1 : (accumulate_start & (accumulate_out < KEM_Q))? accumulate_out: accumulate_start ? (accumulate_out - KEM_Q)  : (secret_gen| extr_mul) ? ntt_out1 :{13'b0, temp_coeff_arrayA[12:0]};
end //}
 
    
always@(posedge clk) mem_rdB_delay <= mem_rdB;


assign read_data1 = read_external ? mem_rdA : 0; 
assign read_data2 = read_external ? mem_rd0 : 16'h3f;  
assign read_data3 = read_external ? mem_rd1 : 16'h3f;  

/*
read_data u_read_data (
    .mem_rdA        (mem_rdA),
    .mem_rd0        (mem_rd0),
    .mem_rd1        (mem_rd1),
    .read_external  (read_external),
    .read_data1     (read_data1),
    .read_data2     (read_data2),
    .read_data3     (read_data3)
);
*/


// Instantiate the ntt_counter module
    wire [7:0] ntt_counter;
    wire [2:0] level;
    wire [10:0] wr_addr0, wr_addr1, rd_addr0, rd_addr1, rd_addr1_intt;
    wire swap_write, swap_read;
    wire swap_write_intt, swap_read_intt;

    wire  swap_write_delay, swap_write_delay1, swap_write_delay2, swap_write_delay3, swap_write_delay4, swap_write_delay5, swap_write_delay6, swap_write_delay7;
    wire  ntt_start_delay, ntt_start_delay1, ntt_start_delay2, ntt_start_delay3, ntt_start_delay4, ntt_start_delay5;

    wire [9:0] rd_addr0_delay, rd_addr1_delay;
    wire [9:0] rd_addr0_delay1, rd_addr1_delay1;
    wire [9:0] rd_addr0_delay2, rd_addr1_delay2;
    wire [9:0] rd_addr0_delay3, rd_addr1_delay3;
    wire [9:0] rd_addr0_delay4, rd_addr1_delay4;
    wire [9:0] rd_addr0_delay5, rd_addr1_delay5;
    wire [9:0] rd_addr0_delay6, rd_addr1_delay6;


    wire swap_read_delay;
    wire [9:0] rd_addr0_delay7, rd_addr1_delay7;
    wire [10:0] addr_mult_wr1;
    wire [10:0] addr_mult_wr2;
    wire [10:0] addr_mult_wr3;
    wire [10:0] addr_mult_wr4;
    wire [10:0] addr_mult_wr5;

    wire [5:0] start, start_intt;
    wire [8:0] startlevel;

ntt_counter u_ntt_counter (
    .addr_bias                    (addr_bias),

    .server_counter_start         (server_counter_start),
    .ntt_start                    (ntt_start),
    .intt_start                   (intt_start),

    .ntt_counter                  (ntt_counter),

    .level                        (level),

    .wr_addr0                     (wr_addr0),
    .wr_addr1                     (wr_addr1),
    .rd_addr0                     (rd_addr0),
    .rd_addr1                     (rd_addr1),
    .rd_addr1_intt                (rd_addr1_intt),
    .swap_write                   (swap_write),
    .swap_read                    (swap_read),
    .swap_write_intt              (swap_write_intt),
    .swap_read_intt               (swap_read_intt),

    .swap_write_delay             (swap_write_delay),
    .swap_write_delay1            (swap_write_delay1),
    .swap_write_delay2            (swap_write_delay2),
    .swap_write_delay3            (swap_write_delay3),
    .swap_write_delay4            (swap_write_delay4),
    .swap_write_delay5            (swap_write_delay5),
    .swap_write_delay6            (swap_write_delay6),
    .swap_write_delay7            (swap_write_delay7),
    .ntt_start_delay              (ntt_start_delay),
    .ntt_start_delay1             (ntt_start_delay1),
    .ntt_start_delay2             (ntt_start_delay2),
    .ntt_start_delay3             (ntt_start_delay3),
    .ntt_start_delay4             (ntt_start_delay4),
    .ntt_start_delay5             (ntt_start_delay5),

    .rd_addr0_delay               (rd_addr0_delay),
    .rd_addr1_delay               (rd_addr1_delay),
    .rd_addr0_delay1              (rd_addr0_delay1),
    .rd_addr1_delay1              (rd_addr1_delay1),
    .rd_addr0_delay2              (rd_addr0_delay2),
    .rd_addr1_delay2              (rd_addr1_delay2),
    .rd_addr0_delay3              (rd_addr0_delay3),
    .rd_addr1_delay3              (rd_addr1_delay3),
    .rd_addr0_delay4              (rd_addr0_delay4),
    .rd_addr1_delay4              (rd_addr1_delay4),
    .rd_addr0_delay5              (rd_addr0_delay5),
    .rd_addr1_delay5              (rd_addr1_delay5),
    .rd_addr0_delay6              (rd_addr0_delay6),
    .rd_addr1_delay6              (rd_addr1_delay6),
    .rd_addr0_delay7              (rd_addr0_delay7),
    .rd_addr1_delay7              (rd_addr1_delay7),

    .swap_read_delay              (swap_read_delay),

    .addr_mult_wr                 (addr_mult_wr),
    .addr_mult_wr1                (addr_mult_wr1),
    .addr_mult_wr2                (addr_mult_wr2),
    .addr_mult_wr3                (addr_mult_wr3),
    .addr_mult_wr4                (addr_mult_wr4),
    .addr_mult_wr5                (addr_mult_wr5),
    .addr_mult_wr6                (addr_mult_wr6),

    .start                        (start),
    .start_intt                   (start_intt),
    .startlevel                   (startlevel),

    .clk                          (clk),
    .rst_n                        (rst_n)
);

wire [5:0] k; // bug fix
k_generate kgen(
	.clk(clk), 
	.rst_n(rst_n), 
	.server_counter_start(server_counter_start), 
	.k(k), 
	.startlevel(startlevel)
);
//reg [5:0] k; // bug fix
//reg [5:0] k_next; // bug fix
//always@(posedge clk, negedge rst_n) begin //{
//	if(rst_n == 1'b0) begin
//	k_next <= 1'b0;
//	end	
//	else begin
//	k_next <= k;
//	end
//end //}
////wire rst_n_server_counter = rst_n & server_counter_start;
//always@(startlevel) begin //{ may have some error
//	k <= (rst_n == 1'b0) ? 5'd1 : (server_counter_start == 1'b0) ? 5'd1 : (k_next + 1'b1);
//	//if(rst_n== 0 || server_counter_start == 1'b0) begin //{
//	////if(server_counter_start == 1'b0) begin //{
//	//	k <= 1;
//	//end //}
//	//else begin //{
//	//	k <= k_next + 1;
//	//end //}
//end//}


        assign zeta_mem[00] = 16'd1;
		assign zeta_mem[01] = 16'd3383;
		assign zeta_mem[02] = 16'd5756;
		assign zeta_mem[03] = 16'd1213;
		assign zeta_mem[04] = 16'd5953;
		assign zeta_mem[05] = 16'd7098;
		assign zeta_mem[06] = 16'd527;
		assign zeta_mem[07] = 16'd849;
		assign zeta_mem[08] = 16'd2132;
		assign zeta_mem[09] = 16'd97;
		assign zeta_mem[10] = 16'd5235;
		assign zeta_mem[11] = 16'd5300;
		assign zeta_mem[12] = 16'd2784;
		assign zeta_mem[13] = 16'd1366;
		assign zeta_mem[14] = 16'd2138;
		assign zeta_mem[15] = 16'd5033;
		assign zeta_mem[16] = 16'd2399;
		assign zeta_mem[17] = 16'd4681;
		assign zeta_mem[18] = 16'd5887;
		assign zeta_mem[19] = 16'd6569;
		assign zeta_mem[20] = 16'd2268;
		assign zeta_mem[21] = 16'd7006;
		assign zeta_mem[22] = 16'd4589;
		assign zeta_mem[23] = 16'd1286;
		assign zeta_mem[24] = 16'd6803;
		assign zeta_mem[25] = 16'd2273;
		assign zeta_mem[26] = 16'd330;
		assign zeta_mem[27] = 16'd2645;
		assign zeta_mem[28] = 16'd4027;
		assign zeta_mem[29] = 16'd4928;
		assign zeta_mem[30] = 16'd5835;
		assign zeta_mem[31] = 16'd7316;
		assign zeta_mem[32] = 16'd202;
		assign zeta_mem[33] = 16'd7438;
		assign zeta_mem[34] = 16'd2881;
		assign zeta_mem[35] = 16'd6915;
		assign zeta_mem[36] = 16'd4270;
		assign zeta_mem[37] = 16'd5130;
		assign zeta_mem[38] = 16'd6601;
		assign zeta_mem[39] = 16'd2516;
		assign zeta_mem[40] = 16'd528;
		assign zeta_mem[41] = 16'd4232;
		assign zeta_mem[42] = 16'd5173;
		assign zeta_mem[43] = 16'd2941;
		assign zeta_mem[44] = 16'd1655;
		assign zeta_mem[45] = 16'd7097;
		assign zeta_mem[46] = 16'd1740;
		assign zeta_mem[47] = 16'd2774;
		assign zeta_mem[48] = 16'd695;
		assign zeta_mem[49] = 16'd799;
		assign zeta_mem[50] = 16'd6300;
		assign zeta_mem[51] = 16'd5806;
		assign zeta_mem[52] = 16'd4957;
		assign zeta_mem[53] = 16'd1908;
		assign zeta_mem[54] = 16'd5258;
		assign zeta_mem[55] = 16'd6299;
		assign zeta_mem[56] = 16'd6988;
		assign zeta_mem[57] = 16'd5967;
		assign zeta_mem[58] = 16'd5212;
		assign zeta_mem[59] = 16'd4301;
		assign zeta_mem[60] = 16'd6949;
		assign zeta_mem[61] = 16'd4607;
		assign zeta_mem[62] = 16'd3477;
		assign zeta_mem[63] = 16'd3080;	


always@(posedge clk) zeta <= intt_start ? zeta_mem[64-k] : zeta_mem[k];
//assign zeta = zeta_mem[k];
// assign in0 = /*v_start? {11'b0,v_inp} : decode_start ? {5'b0,b_inp} :*/extr_mul ? mem_rd_PK : no_ntt? {3'b0, temp_coeff_arrayA[12:0]}:  (secret_gen) ? mem_rdA: swap_read_delay ? mem_rd1 : mem_rd0;
assign in0 = extr_mul ? mem_rd_PK : 
                no_ntt ? {3'b0, temp_coeff_arrayA[12:0]} : 
                    (secret_gen) ? mem_rdA : 
                        swap_read_delay ? mem_rd1 : mem_rd0;

assign in1 = no_ntt & (addr_a[0]) ? mem_rd0 : 
                (secret_gen  | extr_mul) & (addr_mult[0]) ? mem_rd0 : 
                    swap_read_delay ? mem_rd0 : mem_rd1;

butterfly b1(clk, mode, {3'b0, in0}, {3'b0, in1}, zeta, ntt_out0, ntt_out1, server_counter[0]/*, mul_out*/);
//wire [12:0] out_en;
//Archisman change below 29oct
encode e1(msg_in, (ep_accumulate ? {1'b0, server_counter_delay_delay[9:1]} : 10'd0), out_en);
//encode e1(msg_in, (ep_accumulate ? server_counter_delay_delay : 10'd0), out_en);


        
    //       NTT_mem poly_bram_0_dport //replacement of poly_bram
    //    (.addr0(mem_pk_sk_transfer ? (server_counter_delay[9:1] + addr_bias) : ep_accumulate ? server_counter+addr_bias :(accumulate_start & extr_mul)? addr_acc_minus_one[5:1] : decrypt_start & (~server_counter_delay[5]) ? (addr_bias + server_counter_delay):ntt_start_delay5 ? wr_addr0 : secret_error_addr+addr_bias),
    //     .clk(clk),
    //     .din0(mem_pk_sk_transfer ? mem_rd_PK : (accumulate_start & extr_mul)? accumulate_out : decrypt_start ? b_out: secret_error_write ? secret_error0 : (intt_start ? swap_write_delay7 :swap_write_delay6) ? ntt_out1 : ntt_out0),
    //     .dout0(mem_rdA0),//to be added
    //     .we0(mem_pk_sk_transfer ? ~server_counter_delay[0]:(((accumulate_start & extr_mul & addr_acc > 0 & (acc_counter == 0))? ~addr_acc_minus_one[0]: 1'b0 )|((server_counter_start & ntt_start_delay5 & (~ep_gen)))|(secret_error_write & ~accumulate_start & ~extr_mul)|(decrypt_start & (~server_counter_delay[5])))),
    //     .addr1(read_external? read_addr: mem_sk_pk_transfer ? {2'b0, server_counter[9:1]}:ep_accumulate ? (server_counter + addr_bias1) : (v_start & (~ext_addr[5]))? ext_addr:accumulate_start ? (576 + {6'b0,addr_acc[5:1]}) : no_ntt ? ({1'b0,addr_a[10:1]} + addr_bias_genmat) : extr_mul ? (server_counter[9:1]+addr_bias):secret_gen ? ({1'b0,addr_mult[10:1]} + addr_bias - 32/*{1'b0, addr_bias_mult[10:1]}*/) :rd_addr0),
    //     //.BRAM_PORTB_0_clk(clk),
    //     .din1(), //to be added
    //     .dout1(mem_rd0),
    //     .we1(1'b0)); //to be changed

    // Instantiate the mem_2port_poly_bram_true_dport_2 module
        wire [10:0] addr0_poly_bram_true_dport_2;
        wire [15:0] din0_poly_bram_true_dport_2;
        wire we0_poly_bram_true_dport_2;
        wire [10:0] addr1_poly_bram_true_dport_2;
        // wire [15:0] mem_rdB, mem_rdA;

    // Instantiate the NTT_mem_poly_bram_0_dportm module
        wire [9:0] addr0_poly_bram_0_dport;
        wire [15:0] din0_poly_bram_0_dport;
        wire we0_poly_bram_0_dport;
        wire [9:0] addr1_poly_bram_0_dport;
    
    // Instantiate the NTT_mem_poly_bram_1_dportm module
        wire [9:0] addr0_poly_bram_1_dport;
        wire [15:0] din0_poly_bram_1_dport;
        wire we0_poly_bram_1_dport;
        wire [9:0] addr1_poly_bram_1_dport;

    // Instantiate the mem_2port_pk_memory_pk module
        wire [10:0] addr0_memory_pk;
        wire [15:0] din0_memory_pk;
        wire we0_memory_pk;
        wire [10:0] addr1_memory_pk;
        // wire [15:0] mem_rd_PK

    mem_top u_mem_top (
        .clk(clk),
        .start_encr(start_encr), 
        .v_start(v_start), 
        .v_start_delay1(v_start_delay1), 
        .debug_reset(debug_reset), 
        .external_write(external_write),
        .ep_accumulate(ep_accumulate), 
        .accumulate_start(accumulate_start), 
        .extr_mul(extr_mul), 
        .decrypt_start(decrypt_start),
        .intt_start(intt_start), 
        .swap_write_delay7(swap_write_delay7), 
        .swap_write_delay6(swap_write_delay6), 
        .ntt_start_delay5(ntt_start_delay5),
        .read_external(read_external), 
        .no_ntt(no_ntt), 
        .secret_gen(secret_gen), 
        .b_out_en(b_out_en), 
        .v_out_en(v_out_en),
        .addr_bias(addr_bias), 
        .addr_bias1(addr_bias1), 
        .addr_bias_genmat(addr_bias_genmat), 
        .addr_bias_mult(addr_bias_mult), 
        .ext_addr(ext_addr), 
        .addr_a(addr_a), 
        .addr_a_delay(addr_a_delay), 
        .addr_mult(addr_mult), 
        .addr_mult_wr6(addr_mult_wr6),
        .wr_addr0(wr_addr0), 
        .wr_addr1(wr_addr1), 
        .secret_error_addr(secret_error_addr), 
        .rd_addr0(rd_addr0), 
        .rd_addr1(rd_addr1), 
        .rd_addr1_intt(rd_addr1_intt), 
        .read_addr(read_addr),
        .server_counter(server_counter), 
        .server_counter_delay(server_counter_delay), 
        .server_counter_delay_delay_delay(server_counter_delay_delay_delay),
        .acc_counter(acc_counter),
        .addr_acc(addr_acc), 
        .addr_acc_minus_one(addr_acc_minus_one),
        .mem_rd_PK(mem_rd_PK), 
        .accumulate_out(accumulate_out), 
        .external_data(external_data), 
        .data_in(data_in),
        .ntt_out0(ntt_out0), 
        .ntt_out1(ntt_out1), 
        .poly_compressed_out(poly_compressed_out), 
        .b_out(b_out), 
        .v_out(v_out), 
        .secret_error0(secret_error0), 
        .secret_error1(secret_error1),
        .secret_error_write(secret_error_write), 
        .temp_coeff_arrayA_valid(temp_coeff_arrayA_valid), 
        .addr_mult_we_reg(addr_mult_we_reg),
        .addr0_poly_bram_0_dport(addr0_poly_bram_0_dport), 
        .addr0_poly_bram_1_dport(addr0_poly_bram_1_dport),
        .addr1_poly_bram_0_dport(addr1_poly_bram_0_dport), 
        .addr1_poly_bram_1_dport(addr1_poly_bram_1_dport),
        .addr0_memory_pk(addr0_memory_pk), 
        .addr1_memory_pk(addr1_memory_pk),
        .addr0_poly_bram_true_dport_2(addr0_poly_bram_true_dport_2), 
        .addr1_poly_bram_true_dport_2(addr1_poly_bram_true_dport_2),
        .din0_poly_bram_0_dport(din0_poly_bram_0_dport), 
        .din0_poly_bram_1_dport(din0_poly_bram_1_dport), 
        .din0_memory_pk(din0_memory_pk),
        .din0_poly_bram_true_dport_2(din0_poly_bram_true_dport_2),
        .mem_rd0(mem_rd0), 
        .mem_rd1(mem_rd1), 
        .mem_rdA(mem_rdA), 
        .mem_rdB(mem_rdB), 
        .mem_rdA0(mem_rdA0), 
        .mem_rdA1(mem_rdA1),
        .we0_poly_bram_0_dport(we0_poly_bram_0_dport), 
        .we0_poly_bram_1_dport(we0_poly_bram_1_dport), 
        .we0_memory_pk(we0_memory_pk),
        .we0_poly_bram_true_dport_2(we0_poly_bram_true_dport_2),
        .mem_pk_sk_transfer(mem_pk_sk_transfer),
        .mem_sk_pk_transfer(mem_sk_pk_transfer), 
        .server_counter_start(server_counter_start),
        .ep_gen(ep_gen),
        .server_counter_delay_delay_delay_delay(server_counter_delay_delay_delay_delay),
        .decode_start(decode_start),
        .addr_bias_acc(addr_bias_acc),
        .compressed_out(compressed_out),
        .hash_h_start(hash_h_start),
        .hash_read_addr(hash_read_addr)
    );
    


    //     NTT_mem poly_bram_1_dport //replacement of poly_bram
    //    (.addr0(mem_pk_sk_transfer ? (server_counter_delay[9:1] + addr_bias) :ep_accumulate ? ({~server_counter[4], ~server_counter[3], ~server_counter[2], ~server_counter[1], ~server_counter[0]} + addr_bias) : (accumulate_start & extr_mul)? addr_acc_minus_one[5:1] : decrypt_start & (server_counter_delay[5]) ? (addr_bias + {server_counter_delay[9:6],~server_counter_delay[5],server_counter_delay[4:0]}) :ntt_start_delay5 ? wr_addr1 : secret_error_addr+addr_bias),
    //     .clk(clk),
    //     .din0(mem_pk_sk_transfer ? mem_rd_PK : (accumulate_start & extr_mul)? accumulate_out : decrypt_start ? b_out : secret_error_write ? secret_error1 : (intt_start ? swap_write_delay7 :swap_write_delay6) ? ntt_out0 : ntt_out1),
    //     .dout0(mem_rdA1),//to be added
    //     .we0(mem_pk_sk_transfer ? server_counter_delay[0]:(((accumulate_start & extr_mul /*& addr_acc > 0*/ & (acc_counter == 0))? addr_acc_minus_one[0]: 1'b0 )|((server_counter_start & ntt_start_delay5 & (~ep_gen)))|(secret_error_write & ~accumulate_start & ~extr_mul) |(decrypt_start & server_counter_delay[5]))),
    //     .addr1(read_external ? read_addr : mem_sk_pk_transfer ? {server_counter[9:6], ~server_counter[5], ~server_counter[4], ~server_counter[3], ~server_counter[2], ~server_counter[1]}:ep_accumulate ? server_counter[4:0] + addr_bias1 : (v_start & (ext_addr[5]))? ext_addr:accumulate_start ? (576+ 31 - {5'b0,addr_acc[5:1]}) : no_ntt ? ({1'b0,addr_a[10:1]} + addr_bias_genmat) :extr_mul ? 
    //     ({server_counter[9:6], ~server_counter[5], ~server_counter[4], ~server_counter[3], ~server_counter[2], ~server_counter[1]} + addr_bias):secret_gen ? {10'd31 + addr_bias - 32/*{1'b0, addr_bias_mult[10:1]}*/ - {1'b0,addr_mult[10:1]}} : intt_start? rd_addr1_intt:rd_addr1),
    //     //.BRAM_PORTB_0_clk(clk),
    //     .din1(), //to be added
    //     .dout1(mem_rd1),
    //     .we1(1'b0)); //to be changed

    
        





    


endmodule

module poly_decompress(in, out);

input [4:0] in;
output [12:0] out;

parameter KEM_Q = 7681;
wire [17:0] temp;

assign temp = ((in * KEM_Q) + 16);
assign out = temp >> 5;

endmodule

module polyvec_decompress(in, out);

input [9:0] in;
output [12:0] out;
parameter KEM_Q = 7681;
wire [31:0] temp;

assign temp = ((in * KEM_Q) + 512);
assign out = temp >> 10;



endmodule
module decode(in, out);
input [15:0] in; 
output [1:0] out;
parameter KEM_Q = 7681;

wire [15:0] temp = ((in << 2) + (KEM_Q >> 1));
wire [15:0] temp1 = temp/KEM_Q;
assign out = temp1 [1:0];

endmodule

module encode(in, addr, out);
input [127:0] in; 
output [12:0] out;
input [9:0] addr;
parameter KEM_Q = 7681;

//wire [1:0] temp2 = in[(127 - addr*2)-:2];
wire [1:0] temp2 = in[(addr*2 - 1)-:2];
wire [15:0] temp = temp2*KEM_Q  + 2;
//wire [15:0] temp = ((in << 2) + (KEM_Q >> 1));
wire [15:0] temp1 = temp>>2;
assign out = temp1;

endmodule

module polyvec_compress(in, out);
input [15:0] in; 
output [15:0] out;
wire [15:0] temp;
wire [25:0] temp1, temp2;
wire [47:0] temp3;
localparam KEM_Q = 7681;


assign temp = in[15] ? (in+KEM_Q) : in;
assign temp1 = temp << 10;
assign temp2 = temp1 + 3840;
assign temp3 = temp2 * 559168;
assign out = temp3[41:32];
endmodule

module poly_compress(in, out);
input [15:0] in; 
output [15:0] out;
wire [15:0] temp;
wire [25:0] temp1, temp2;
wire [47:0] temp3;
localparam KEM_Q = 7681;


assign temp = in[15] ? (in+KEM_Q) : in;
assign temp1 = temp << 5;
assign temp2 = temp1 + 3840;
assign temp3 = temp2 * 17474;
assign out = temp3[31:27];
endmodule

