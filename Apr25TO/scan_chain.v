`timescale 1 ns / 1 ps   // module timescale_check2;


module scan_chain #(parameter NUM_SCAN_BITS = 36) (
    input wire clk1,    // Clock
    input wire clk2, // Clock Enable
    input wire rst_n,  // Asynchronous reset active low
    input wire scan_in, update, capture,
    input wire [NUM_SCAN_BITS - 1:0] par_in,
    output wire scan_out,
    output wire [NUM_SCAN_BITS - 1:0] scan_reg
);

wire [NUM_SCAN_BITS - 1:0] scan_array;
assign scan_out = scan_array[NUM_SCAN_BITS - 1];
scan_cell sc0 (.CLK1(clk1),
               .CLK2(clk2),
               .SCAN_IN(scan_in),
               //.SCAN_CAPTURE_IN_1(1'b0),
               .SCAN_CAPTURE_IN(par_in[0]),
               .UPDATE(update),
               .CAPTURE(capture),
               .RESET(rst_n),
               .SCAN_OUT_UPDT_2(scan_reg[0]),
               .SCAN_OUT(scan_array[0]));

genvar i;
generate
    for (i = 0; i < NUM_SCAN_BITS - 2; i = i + 1) begin: sc_cell
    scan_cell sci(.CLK1(clk1),
               .CLK2(clk2),
               .SCAN_IN(scan_array[i]),
               //.SCAN_CAPTURE_IN_1(1'b0),
               .SCAN_CAPTURE_IN(par_in[i + 1]),
               .UPDATE(update),
               .CAPTURE(capture),
               .RESET(rst_n),
               .SCAN_OUT_UPDT_2(scan_reg[i + 1]),
               .SCAN_OUT(scan_array[i + 1]));
    end
endgenerate

scan_cell scN (.CLK1(clk1),
               .CLK2(clk2),
               .SCAN_IN(scan_array[NUM_SCAN_BITS - 2]),
               //.SCAN_CAPTURE_IN_1(1'b0),
               .SCAN_CAPTURE_IN(par_in[NUM_SCAN_BITS - 1]),
               .UPDATE(update),
               .CAPTURE(capture),
               .RESET(rst_n),
               .SCAN_OUT_UPDT_2(scan_reg[NUM_SCAN_BITS - 1]),
               .SCAN_OUT(scan_array[NUM_SCAN_BITS - 1]));
endmodule
