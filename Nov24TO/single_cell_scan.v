`timescale 1ns/10ps


module scan_cell (CLK1, CLK2,SCAN_IN, SCAN_CAPTURE_IN,UPDATE,CAPTURE,RESET,SCAN_OUT_UPDT_2, SCAN_OUT);

input CLK1, CLK2;
input SCAN_IN, SCAN_CAPTURE_IN,UPDATE,CAPTURE,RESET;
output reg SCAN_OUT_UPDT_2;
output wire SCAN_OUT;

reg pos_latch1_out, pos_latch2_out;
wire pos_latch2_in;

always @(CLK1)
begin
if (CLK1 == 1)
  pos_latch1_out <= SCAN_IN;
end


always @(CLK2)
begin
if (CLK2 == 1)
  pos_latch2_out <= pos_latch2_in;
end

always @(posedge UPDATE or negedge RESET)
begin
  if (RESET == 0)
    SCAN_OUT_UPDT_2 <= 0;
  else
    SCAN_OUT_UPDT_2 <= pos_latch2_out;  
end

assign pos_latch2_in = CAPTURE ? SCAN_CAPTURE_IN : pos_latch1_out;
assign SCAN_OUT = CAPTURE ? SCAN_CAPTURE_IN : pos_latch2_out;
endmodule


