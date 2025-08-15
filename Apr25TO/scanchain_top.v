module scanchain_top(
	input clk1, clk2,
	input scan_in, 
	input update, 
	input capture,
	output scan_out,

	input clk, 
	input rst_n, 
	input kyber_rst_n,
	input start,
	input v_path_decrypt,
	input b_path_decrypt,
	input read_external, 
	output trigger,
	output serial_out

);

wire[127:0] message, encr_message, genmat_message, msg_in;
wire[10:0] read_addr;
wire [15:0] read_data1, read_data2, read_data3;
wire [523-1:0] scan_regs;

scan_chain 
//#(parameter NUM_SCAN_BITS = 395)
	#(
	.NUM_SCAN_BITS(523)
) u_sc (
	.clk1(clk1),    // Clock
	.clk2(clk2), // Clock Enable
	.rst_n(rst_n),  // Asynchronous reset active low
	.scan_in(scan_in), 
	.update(update), 
	.capture(capture),
	.par_in({read_data1, read_data2, read_data3, 475'd0}),
	.scan_out(scan_out),
	.scan_reg(scan_regs)
);

assign {msg_in, message, encr_message, genmat_message, read_addr} = scan_regs;

small_kyber_top #(
	.r(64), 
	.a(12),
	.b(12),
	.h(256),
    .l(64*2000), 
	.y(64*2)
) u_kyber(
	.CLK					(clk),
	.RST_N					(kyber_rst_n),
	.start					(start),
	.message				(message), // sc
	.encr_message			(encr_message), // sc
	.genmat_message			(genmat_message), // sc
	.v_path_decrypt			(v_path_decrypt), 
	.b_path_decrypt			(b_path_decrypt),
	.read_addr				(read_addr), // sc
	.read_data1				(read_data1), // sc
	.read_data2				(read_data2), // sc
	.read_data3				(read_data3), // sc
	.read_external			(read_external), 
	.trigger				(trigger),
	.serial_out				(serial_out),	
	.msg_in					(msg_in)
);

endmodule
