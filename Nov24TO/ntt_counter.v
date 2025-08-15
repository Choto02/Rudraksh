module ntt_counter(

    input [10:0] addr_bias,

    input server_counter_start,
    input ntt_start,
    input intt_start,

    output reg [7:0] ntt_counter,


    output [2:0] level,


    output [10:0] wr_addr0, wr_addr1, rd_addr0, rd_addr1, rd_addr1_intt,
    output swap_write, swap_read, swap_write_intt, swap_read_intt,



    output reg swap_write_delay, swap_write_delay1, swap_write_delay2, swap_write_delay3, swap_write_delay4, swap_write_delay5, swap_write_delay6, swap_write_delay7,
    output reg ntt_start_delay, ntt_start_delay1, ntt_start_delay2, ntt_start_delay3, ntt_start_delay4, ntt_start_delay5,


    output reg [9:0] rd_addr0_delay, rd_addr1_delay,
    output reg [9:0] rd_addr0_delay1, rd_addr1_delay1,
    output reg [9:0] rd_addr0_delay2, rd_addr1_delay2,
    output reg [9:0] rd_addr0_delay3, rd_addr1_delay3,
    output reg [9:0] rd_addr0_delay4, rd_addr1_delay4,
    output reg [9:0] rd_addr0_delay5, rd_addr1_delay5,
    output reg [9:0] rd_addr0_delay6, rd_addr1_delay6,
    output reg [9:0] rd_addr0_delay7, rd_addr1_delay7,

    output reg swap_read_delay,

    input [10:0] addr_mult_wr,
    output reg [10:0] addr_mult_wr1,
    output reg [10:0] addr_mult_wr2,
    output reg [10:0] addr_mult_wr3,
    output reg [10:0] addr_mult_wr4,
    output reg [10:0] addr_mult_wr5,
    output reg [10:0] addr_mult_wr6,


    output [5:0] start,
    output [5:0] start_intt,
    output [8:0] startlevel,
    input clk,
    input rst_n

);

always@(posedge clk, negedge rst_n) begin //{
        if (rst_n == 0 ) begin //{
            ntt_counter <= 0;
        end //}
        else if (server_counter_start == 0) 
            ntt_counter <= 0;
        else if (ntt_start | intt_start) begin //{
            ntt_counter <= ntt_counter + 1'b1;
        end //}
        else 
            ntt_counter <= 0; 
end //}
assign level = ntt_counter[7:5];

assign rd_addr0 = (ntt_counter[4:0] + addr_bias);

assign rd_addr1 = addr_bias + ((level == 0) ? ntt_counter[4:0] : (level == 1) ? {~ntt_counter[4], ntt_counter[3:0]} : 
                  (level == 2) ? {~ntt_counter[4],~ntt_counter[3], ntt_counter[2:0]} :
                  (level == 3) ? {~ntt_counter[4], ~ntt_counter[3],~ntt_counter[2], ntt_counter[1:0]} :
                  (level == 4) ? {~ntt_counter[4:2],~ntt_counter[1], ntt_counter[0]} :
                  (level == 5) ? {~ntt_counter[4:1],~ntt_counter[0]} : ntt_counter[4:0]);
assign rd_addr1_intt = addr_bias + ((level == 0) ? ntt_counter[4:0] : (level == 1) ? {ntt_counter[4:1], ~ntt_counter[0]} : 
                  (level == 2) ? {ntt_counter[4:2],~ntt_counter[1], ~ntt_counter[0]} :
                  (level == 3) ? {ntt_counter[4:3], ~ntt_counter[2],~ntt_counter[1], ~ntt_counter[0]} :
                  (level == 4) ? {ntt_counter[4],~ntt_counter[3], ~ntt_counter[2], ~ntt_counter[1], ~ntt_counter[0]} :
                  (level == 5) ? {~ntt_counter[4:1],~ntt_counter[0]} : ntt_counter[4:0]);


assign swap_write = ((level == 0)& (ntt_counter[4])) | ((level == 1)& (ntt_counter[3])) | 
                    ((level == 2)& (ntt_counter[2])) | ((level == 3)& (ntt_counter[1])) | 
                    ((level == 4)& (ntt_counter[0])) /* | ((level == 5)& (ntt_counter[3])) */ ; //need to check -- may cause some 
                    //some issue at last level
assign swap_write_intt = ((level == 0)& (ntt_counter[0])) | ((level == 1)& (ntt_counter[1])) | 
                    ((level == 2)& (ntt_counter[2])) | ((level == 3)& (ntt_counter[3])) | 
                    ((level == 4)& (ntt_counter[4]));

assign swap_read = ((level == 1)& (ntt_counter[4])) | ((level == 2)& (ntt_counter[3])) | 
                    ((level == 3)& (ntt_counter[2])) | ((level == 4)& (ntt_counter[1])) | 
                    ((level == 5)& (ntt_counter[0])) /* | ((level == 5)& (ntt_counter[3])) */ ; 
assign swap_read_intt = ((level == 1)& (ntt_counter[0])) | ((level == 2)& (ntt_counter[1])) | 
                    ((level == 3)& (ntt_counter[2])) | ((level == 4)& (ntt_counter[3])) | 
                    ((level == 5)& (ntt_counter[4]));


always@(posedge clk) ntt_start_delay <= (ntt_start|intt_start);
always@(posedge clk) ntt_start_delay1 <= ntt_start_delay;
always@(posedge clk) ntt_start_delay2 <= ntt_start_delay1;
always@(posedge clk) ntt_start_delay3 <= ntt_start_delay2;
always@(posedge clk) ntt_start_delay4 <= ntt_start_delay3;
always@(posedge clk) ntt_start_delay5 <= ntt_start_delay4;
always@(posedge clk) swap_write_delay <= intt_start ? swap_write_intt : swap_write;
always@(posedge clk) swap_write_delay1 <= swap_write_delay;
always@(posedge clk) swap_write_delay2 <= swap_write_delay1;
always@(posedge clk) swap_write_delay3 <= swap_write_delay2;
always@(posedge clk) swap_write_delay4 <= swap_write_delay3;
always@(posedge clk) swap_write_delay5 <= swap_write_delay4;
always@(posedge clk) swap_write_delay6 <= swap_write_delay5;
always@(posedge clk) swap_write_delay7 <= swap_write_delay6;
always@(posedge clk) rd_addr0_delay <= rd_addr0;
always@(posedge clk) rd_addr0_delay1 <= rd_addr0_delay;
always@(posedge clk) rd_addr0_delay2 <= rd_addr0_delay1;
always@(posedge clk) rd_addr0_delay3 <= rd_addr0_delay2;
always@(posedge clk) rd_addr0_delay4 <= rd_addr0_delay3;
always@(posedge clk) rd_addr0_delay5 <= rd_addr0_delay4;
always@(posedge clk) rd_addr0_delay6 <= rd_addr0_delay5;
always@(posedge clk) rd_addr0_delay7 <= rd_addr0_delay6;
always@(posedge clk) rd_addr1_delay <= intt_start ? rd_addr1_intt: rd_addr1;
always@(posedge clk) rd_addr1_delay1 <= rd_addr1_delay;
always@(posedge clk) rd_addr1_delay2 <= rd_addr1_delay1;
always@(posedge clk) rd_addr1_delay3 <= rd_addr1_delay2;
always@(posedge clk) rd_addr1_delay4 <= rd_addr1_delay3;
always@(posedge clk) rd_addr1_delay5 <= rd_addr1_delay4;
always@(posedge clk) rd_addr1_delay6 <= rd_addr1_delay5;
always@(posedge clk) rd_addr1_delay7 <= rd_addr1_delay6;
always@(posedge clk) swap_read_delay <= intt_start ? swap_read_intt : swap_read;
always@(posedge clk) addr_mult_wr1 <= addr_mult_wr;
always@(posedge clk) addr_mult_wr2 <= addr_mult_wr1;
always@(posedge clk) addr_mult_wr3 <= addr_mult_wr2;
always@(posedge clk) addr_mult_wr4 <= addr_mult_wr3;
always@(posedge clk) addr_mult_wr5 <= addr_mult_wr4;
always@(posedge clk) addr_mult_wr6 <= addr_mult_wr5;

assign wr_addr0 = intt_start ? rd_addr0_delay7 : rd_addr0_delay6; //ntt_write ? ntt_fill_addr : rd_addr0_delay;// bug fix
assign wr_addr1 = intt_start ? rd_addr1_delay7 : rd_addr1_delay6; //ntt_write ? ntt_fill_addr : rd_addr1_delay;


assign start = (level == 0) ? 6'b0 :(level ==1)?{ntt_counter[4],5'b0}: (level == 2)?{ntt_counter[4:3],4'b0}: (level == 3) ? {ntt_counter[4:2],3'b0} : 
        (level == 4) ? {ntt_counter[4:1],2'b0}:(level == 5) ? {ntt_counter[4:0],1'b0}: 6'b0;

assign start_intt = (level == 5) ? 6'b0 :(level ==4)?{ntt_counter[4],5'b0}: (level == 3)?{ntt_counter[4:3],4'b0}: (level == 2) ? {ntt_counter[4:2],3'b0} : 
        (level == 1) ? {ntt_counter[4:1],2'b0}:(level == 0) ? {ntt_counter[4:0],1'b0}: 6'b0;



assign startlevel = intt_start ? {start_intt, level}: {start, level}; // bug
endmodule