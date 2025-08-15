module sccca_ascon_fsm #(
    parameter r = 64, // Hash rate in bit
    parameter a = 12, //no of rounds 12 for P12
    parameter b = 12, // no of rounds 12 for P12
    parameter h = 256, // capacity size
    parameter l = 64*2000, // output xof size -- bits out genmatrix > 9*9*64*13, idea is to try to fill unless mem_fill 1
    //parameter y = 40
    parameter y = 64*2 //input message size -- bits
) (

    input server_counter_start,
    output reg [2:0] state,
    output reg [319:0] S,
    output reg ready_1,
    output reg [14+1:0] block_ctr,

    // ABSORB
    input [319:0] P_out, // output from permutation block
    input hash_h_start, 
    input [3:0] hash_counter,
    input start_keygen,
    input permutation_ready,

    // SQUEEZE
    input secret_gen,
    input [10:0] addr_a_delay,
    input temp_coeff_arrayA_valid,


    //always comb
    // input hash_g_start,
    // output reg [319:0] P_in, // input to permutation block 
    // output reg [4:0] rounds,
    // output reg permutation_start,

    // input [63:0] hash_buffer_sel_buf,
    // input [r-1:0] Sr,
    // input [(320-r)-1:0] Sc,
    // input [y + ((y+1)%r == 0)? 0 : r-((y+1)%r):0] M,
    
    input clk,
    input rst_n
);
    // Constants
    localparam c = 320-r; //capacity
    localparam nz_m = ((y+1)%r == 0)? 0 : r-((y+1)%r);
    localparam Y = y+1+nz_m;
    localparam s = Y/r; //determines no of time absorbtion required for full messgae
    localparam t = l/r;
    localparam t_genmat = 13;
    localparam t_secret_error = 4;

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

    // always seq
    always @(posedge clk) begin
        if(rst_n == 1'b0 || server_counter_start == 1'b0) begin
            state <= IDLE;
            S <= 0;
            ready_1 <= 0;
            block_ctr <= 0; 
        end
        else begin
            case (state)
                // Idle Stage
                IDLE: begin
                    S <= {ASCON_XOF_IV0, ASCON_XOF_IV1, ASCON_XOF_IV2, ASCON_XOF_IV3, ASCON_XOF_IV4};
                    ready_1 <= 0;
                    // new 
                    state <= (hash_h_start & hash_counter == 6) ? ABSORB : 
                                (~hash_h_start & start_keygen) ? ABSORB : state;
                    block_ctr <= block_ctr;
                    // old
                    // if(hash_h_start & hash_counter == 6)
			        //     state <= ABSORB;
			        // else if(~hash_h_start & start_keygen)
                    //     state <= ABSORB;
                end 

                // Absorb Message
                ABSORB: begin
                    // new code, Mingche added
                    state <= (hash_h_start & block_ctr == 119) ? SQUEEZE : 
                                (~hash_h_start & block_ctr == s) ? SQUEEZE : state;
                                    
                    S <= (hash_h_start & block_ctr == 119) ? {S[319:312]^8'h80, S[311:0]} :
                            (~hash_h_start & block_ctr == s) ? S :
                                ((permutation_ready && block_ctr != s && ~hash_h_start) | (hash_h_start & block_ctr!= 119 & permutation_ready)) ? P_out : S;
 
                    block_ctr <= ((hash_h_start & block_ctr == 119) | (~hash_h_start & block_ctr == s)) ? 0 :
                                    ((permutation_ready && block_ctr != s && ~hash_h_start) | (hash_h_start & block_ctr!= 119 & permutation_ready)) ? block_ctr + 1 : block_ctr;

                    ready_1 <= ready_1;

                    // old code, Mingche commented out
                    // if((hash_h_start & block_ctr == 119)) begin
                    //     state <= SQUEEZE;
                    //     S <= {S[319:312]^8'h80, S[311:0]}; // bug fix
                    // end
                    // else if(/*(hash_h_start & block_ctr == 119) | */(~hash_h_start & block_ctr == s)) begin // Archisman change
                    //     state <= SQUEEZE;
                    //     S <= S; // bug fix
                    // end
                    // else if((permutation_ready && block_ctr != s && ~hash_h_start) | (hash_h_start & block_ctr!= 119 & permutation_ready))
                    //     S <= P_out;

                    // if ((hash_h_start & block_ctr == 119) | (~hash_h_start & block_ctr == s)/*block_ctr == s*/)// 
                    //     block_ctr <= 0;
                    // else if((permutation_ready && block_ctr != s && ~hash_h_start) | (hash_h_start & block_ctr!= 119 & permutation_ready)/*permutation_ready && block_ctr != s*/)
                    //     block_ctr <= block_ctr + 1; 
                end

                // Squeeze Hash
                SQUEEZE: begin
                    state <= (  (permutation_ready && block_ctr == t-2) || 
                                (t == 1) || 
                                (secret_gen & ((permutation_ready && block_ctr == t_secret_error-1))) || 
                                (addr_a_delay == 63 & temp_coeff_arrayA_valid) ) ? DONE : state;
                    
                    S <= (  (permutation_ready && block_ctr == t-2) || 
                                (t == 1) || 
                                (secret_gen & ((permutation_ready && block_ctr == t_secret_error-1))) || 
                                (addr_a_delay == 63 & temp_coeff_arrayA_valid) ) ? P_out : 
                                ((permutation_ready || (t==1)) && block_ctr != t) ? P_out : S;

                    block_ctr <= (  (permutation_ready && block_ctr == t-2) || 
                                (t == 1) || 
                                (secret_gen & ((permutation_ready && block_ctr == t_secret_error-1))) || 
                                (addr_a_delay == 63 & temp_coeff_arrayA_valid) ) ? 0 : 
                                ((permutation_ready || (t==1)) && block_ctr != t) ? block_ctr + 1 : block_ctr;

                    ready_1 <= ready_1;

                    // old code, Mingche commented out
                    // if((permutation_ready && block_ctr == t-2) || (t == 1) || (secret_gen & ((permutation_ready && block_ctr == t_secret_error-1))) || (addr_a_delay == 63 & temp_coeff_arrayA_valid)) begin //need to check addr_a part
                    // //if((permutation_ready && block_ctr == t-1) || (t == 1)) begin
                    //     state <= DONE;
                    //     block_ctr <= 0;
                    //     //H[r-1 : 0] <= P_out[319 -: r];
                    //     S <= P_out;
                    // end
                    // else if((permutation_ready || (t==1)) && block_ctr != t) begin
                    //     S <= P_out;
                    //     //H[(t-block_ctr)*r-1 -: r] <= P_out[319 -: r];
                    //     block_ctr <= block_ctr + 1;
                    // end
                    // else S <= S;
                end

                // Done Stage
                DONE: begin
                    state <= start_keygen ? IDLE : state;
                    ready_1 <= 1;
                    S <= S;
                    block_ctr <= block_ctr;

                    // ready_1 <= 1;
                    // if(start_keygen)
                    //     state <= IDLE;
                end
//
                default: begin
                    state <= IDLE;
                    ready_1 <= ready_1;
                    S <= S;
                    block_ctr <= block_ctr;
                end
            endcase
        end
    end


endmodule