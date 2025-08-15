module read_data (
    input [15:0] mem_rdA,
    input [15:0] mem_rd0,
    input [15:0] mem_rd1,
    input read_external,
    output [15:0] read_data1, read_data2, read_data3
);

assign read_data1 = read_external ? mem_rdA : 0; 
assign read_data2 = read_external ? mem_rd0 : 16'h3f;  
assign read_data3 = read_external ? mem_rd1 : 16'h3f;  

endmodule