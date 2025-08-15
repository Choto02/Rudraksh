module acc_counter(
    input accumulate_start,
    output reg accumulate_start_delay,

    output reg [3:0] acc_counter,
    output reg [5:0] addr_acc,
    output [5:0] addr_acc_minus_one,

    input ep_accumulate,
    input [9:0] server_counter,
    output reg [15:0] accumulate_out3,
    input [15:0] mem_rdA0, mem_rdA1,
    input [15:0] mem_rd0, mem_rd1,

    output reg [15:0] accumulate_out4,
    output reg [15:0] accumulate_out5,

    input [12:0] out_en,

    output reg [15:0] accumulate_out1,
    output reg [15:0] accumulate_out2,

    input no_error,
    input [15:0] mem_rdB,
    output [15:0] accumulate_out,

    input clk,
    input rst_n
);

localparam KEM_Q = 7681;

always@(posedge clk or negedge rst_n) begin
    if (~rst_n)
        accumulate_start_delay <= 0;
    else 
        accumulate_start_delay <= accumulate_start;
end

always@(posedge clk or negedge rst_n) begin //{
    if (~rst_n) begin
        acc_counter <= 0;
        addr_acc <= 0;
    end
    else begin
        if(acc_counter == 8) begin
            acc_counter <= acc_counter + 1'b1;
            addr_acc <= addr_acc + 1'b1;
            
        end
        else if(acc_counter == 9) begin
            acc_counter <= 0;
            //addr_acc <= addr_acc + 1'b1;
            
        end
    //    else if(accumulate_start  & acc_counter == 9) begin 
    //        acc_counter <= 0;
    //    end
        else if(accumulate_start_delay) begin
            acc_counter <= acc_counter + 1'b1;
        end
        else begin 
            acc_counter <= 0;
            addr_acc <= 0;
        end
    end
end //}

assign addr_acc_minus_one = addr_acc - 1;

//Archisman change below 29oct
always@(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        accumulate_out3 <= 0;
    end
    else begin
	if(ep_accumulate & server_counter <=64 & server_counter[0])
		accumulate_out3 <= (mem_rd0); // bug fix in accumulate
	else if(ep_accumulate & server_counter <=64 & ~server_counter[0])
		accumulate_out3 <= (accumulate_out3+mem_rd0); 
	else if(ep_accumulate & server_counter >64 & server_counter[0])
		accumulate_out3 <= mem_rd1;
	else if(ep_accumulate & server_counter >64 & ~server_counter[0])
		accumulate_out3 <= accumulate_out3 + mem_rd1;
	else accumulate_out3 <= 0;

       // if(ep_accumulate & server_counter <=32)
       //     accumulate_out3 <= (mem_rdA0 + mem_rd0); // bug fix in accumulate
       // else if(ep_accumulate & server_counter >32)
       //     accumulate_out3 <= mem_rdA1 + mem_rd1;
       // else accumulate_out3 <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if (~rst_n)
        accumulate_out4 <= 0;
    else
	    accumulate_out4 <= (accumulate_out3 > KEM_Q) ? accumulate_out3 - KEM_Q : accumulate_out3;
end
always@(posedge clk or negedge rst_n) begin
    if (~rst_n)
        accumulate_out5 <= 0;
    else
	    accumulate_out5 <= ((accumulate_out4 + out_en) > KEM_Q ) ? (accumulate_out4 + out_en - KEM_Q) : accumulate_out4 + out_en ;
end

always@(posedge clk or negedge rst_n) begin //{
    /*if(acc_counter == 0 & accumulate_start)
        accumulate_out <= 0;
    else if(acc_counter == 0 & accumulate_start)
        accumulate_out <= addr_acc[0]? (((accumulate_out + mem_rd1) > KEM_Q) ? accumulate_out + mem_rd1 - KEM_Q : accumulate_out + mem_rd1) : 
        (((accumulate_out + mem_rd0) > KEM_Q) ? accumulate_out + mem_rd0 - KEM_Q : accumulate_out + mem_rd0);*/
    if (~rst_n) begin
        accumulate_out1 <= 0;
        accumulate_out2 <= 0;
    end
    else begin
        if(acc_counter == 0 & accumulate_start & no_error) 
        begin
            accumulate_out1 <= 0;
            accumulate_out2 <= 0;
        end
        else if(acc_counter == 0 & accumulate_start) 
        begin
            accumulate_out1 <= addr_acc[0]? mem_rd1 : mem_rd0;
            accumulate_out2 <= addr_acc[0]? mem_rd1 : mem_rd0;
        end
        //else if()
        else if(accumulate_start) begin
            accumulate_out1 <= accumulate_out + mem_rdB;
            accumulate_out2 <= accumulate_out + mem_rdB - KEM_Q;
        end
    end    
end //}

assign accumulate_out = (accumulate_out1 > KEM_Q) ? accumulate_out2 : accumulate_out1;
endmodule
