`timescale 1ns / 1ps

module serial_out(
    input wire clk,
    input wire rst_n, 
    input wire capture,
    input wire [15:0] read_data1,
    input wire [15:0] read_data2,
    input wire [15:0] read_data3,
    output reg serial_out
);

    
    localparam IDLE     = 2'b00;
    localparam LOAD     = 2'b01;
    localparam SERIALIZE = 2'b10;
    localparam DONE      = 2'b11;

    reg [1:0] state, next_state;
    reg [46:0] shift_reg; // 47-bit because first bit of read_data_0 outputted in LOAD state
    reg [5:0] bit_counter; 

    // Sequential
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_counter <= 6'd0;
            serial_out <= 1'b0;
            shift_reg <= 48'b0;
        end 
        else begin
            state <= next_state;
            //serial_out <= (state == SERIALIZE) ? shift_reg[47] : serial_out;
            serial_out <= (state == LOAD) ? read_data1[15] : (state == SERIALIZE) ? shift_reg[46] : (state == DONE) ? 1'b0 : serial_out; 
            shift_reg <= (state == LOAD) ? {read_data1[14:0], read_data2, read_data3} : 
                         (state == SERIALIZE) ? {shift_reg << 1} : 
                         shift_reg; 
            bit_counter <= (state == LOAD) ? 6'd0 : 
                           (state == SERIALIZE) ? {bit_counter + 1} : 
                           bit_counter; 
        end
    end

    // Combinational
    always @(*) begin
        next_state = (state == IDLE) ? (capture ? LOAD : IDLE) :
                     (state == LOAD) ? SERIALIZE :
                     (state == SERIALIZE) ? ((bit_counter == 6'd46) ? DONE : SERIALIZE) :
                     state; 
    end

endmodule