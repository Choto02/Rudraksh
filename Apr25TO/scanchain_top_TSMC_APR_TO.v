module scanchain_top(
	input CLK1, CLK2,
	input SCAN_IN, 
	input UPDT, 
	input CAPTURE,
	output SCAN_OUT,

	input RD_clk, 
	input RD_rst_n, 
	input RD_kyber_rst_n,
	input RD_start,
	input RD_v_path_decrypt,
	input RD_b_path_decrypt,
	input RD_read_external, 
	output RD_trigger,
	output RD_serial_out

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
	.clk1(CLK1),    // Clock
	.clk2(CLK2), // Clock Enable
	.rst_n(RD_rst_n),  // Asynchronous reset active low
	.scan_in(SCAN_IN), 
	.update(UPDT), 
	.capture(CAPTURE),
	.par_in({read_data1, read_data2, read_data3, 475'd0}),
	.scan_out(SCAN_OUT),
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
	.CLK					(RD_clk),
	.RST_N					(RD_kyber_rst_n),
	.start					(RD_start),
	.message				(message), // sc
	.encr_message			(encr_message), // sc
	.genmat_message			(genmat_message), // sc
	.v_path_decrypt			(RD_v_path_decrypt), 
	.b_path_decrypt			(RD_b_path_decrypt),
	.read_addr				(read_addr), // sc
	.read_data1				(read_data1), // sc
	.read_data2				(read_data2), // sc
	.read_data3				(read_data3), // sc
	.read_external			(RD_read_external), 
	.trigger				(RD_trigger),
	.serial_out				(RD_serial_out),	
	.msg_in					(msg_in)
);

endmodule
