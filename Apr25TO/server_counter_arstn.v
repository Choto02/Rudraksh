module server_counter(


    input decode_start,
    input accumulate_start,
    input decrypt_start,
    input no_ntt,
    input mem_pk_sk_transfer, mem_sk_pk_transfer,
    input ep_accumulate, ep_gen,
    input extr_mul,
    input intt_start, ntt_start_out,
    input [10:0] addr_a_delay,
    input temp_coeff_arrayA_valid,


    output reg [9:0] server_counter,
    output op_done,
    output secret_gen,
    output ntt_start,
    output [1:0] mode,
    output [10:0] addr_mult,
    output addr_mult_we,

    output reg addr_mult_we_reg,
    input server_counter_start,
    output reg [10:0] addr_mult_wr,
    output reg read_en_mult,

    input clk, rst_n
);
	localparam NTT_CYCLE = 192;

assign op_done =  decode_start ? (server_counter == 64) : 
                    accumulate_start ? (server_counter == 643) :
                        (decrypt_start & no_ntt) ? (server_counter == 65) : 
                            (mem_pk_sk_transfer | mem_sk_pk_transfer) ? (server_counter == 576) : 
                                (ep_accumulate & ep_gen) ? (server_counter == 131) : /*Archisman change 67 to 131 29oct*/ 
                                    ep_gen ? (server_counter == 99) :
                                        extr_mul ? (server_counter == 583) :
                                            intt_start ? (server_counter == 199) : 
                                                ntt_start_out ? (server_counter == 198) : (addr_a_delay == 63 & temp_coeff_arrayA_valid);

assign secret_gen = ( no_ntt | ntt_start_out |intt_start | ep_accumulate ) ? 1'b0: (server_counter <= 99);

assign ntt_start = no_ntt ? 1'b0 : 
                    ntt_start_out ? (server_counter <= 'h101) : 
                        (extr_mul == 0) ? (server_counter >= 100 && server_counter <= (100+NTT_CYCLE)) : 1'b0;

assign mode = no_ntt ? 2 : 
                intt_start ? 1 : 
                    ntt_start ? 0 : 
                        extr_mul ? 2 : 
                            secret_gen ? 2 : 0;
 
assign addr_mult = extr_mul & (server_counter<576) ? server_counter :
                    secret_gen & (server_counter <64) ? server_counter : 10'd640; 

assign addr_mult_we = extr_mul & (server_counter <(576 + 6) & server_counter >=6) ? 1'b1 :
                        secret_gen & (server_counter <(64 + 6) & server_counter >=6) ? 1'b1 : 1'b0;


always@(posedge clk or negedge rst_n) begin //{
    if (~rst_n)
        addr_mult_we_reg <= 0;
    else 
        addr_mult_we_reg <= addr_mult_we;
end //}

always@(posedge clk, negedge server_counter_start) begin //{
	if(server_counter_start == 0) server_counter <= 0;
	else server_counter <= server_counter + 1'b1;
end //}

always@(posedge clk, negedge rst_n) begin //{
	if(rst_n == 0) begin //{
		addr_mult_wr <= 0;
	end//}
	else if(server_counter_start == 1'b0) begin //{
		addr_mult_wr <= 0;
	end//}

	else addr_mult_wr <= addr_mult;
end //}

always@(posedge clk, negedge rst_n) begin //{
	if(rst_n == 0 ) begin //{
		read_en_mult <= 0;
	end//}
	else if(server_counter_start == 1'b0) begin //{
		read_en_mult <= 0;
	end //}
	else read_en_mult <= addr_mult[0];
end //}
    // Assignments
endmodule
