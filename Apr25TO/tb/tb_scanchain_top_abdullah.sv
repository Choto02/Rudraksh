`timescale 1 ns / 1 ps   // module timescale_check2;

module tb_scan_chain();
parameter PRINT_INTERVAL = 1000;
parameter CLK_PERIOD = 10; //was 10 originally
// --------------------------------------------------------------------------------
// Waveform Generation
// --------------------------------------------------------------------------------
// initial  begin
// //    $dumpfile("scan_chain_in_presim.vcd");
//     //   $dumpfile("scan_chain_in_postsyn_apr.vcd"); 
//    $dumpfile("scan_chain_in_postlayout.vcd");   
//    $dumpvars(0, u_sc);
// end
//  initial  begin
//      $dumpfile("scan_chain_in.vcd");
// // //    $dumpvars(1, u_sc.u_kyber);
//      $dumpvars(0, u_sc.u_kyber.u_server_client);
// //    //$dumpvars(1, u_sc.u_kyber.u_server_client.s);
//  //   $dumpvars(1, u_sc.u_kyber.u_small_kyber_top_fsm.state);
//    $dumpvars(1, u_sc.u_kyber.msg_in);
//    $dumpvars(1, u_sc.u_kyber.message);
//    $dumpvars(1, u_sc.u_kyber.encr_message);
//    $dumpvars(1, u_sc.u_kyber.genmat_message);
//    $dumpvars(1, u_sc.u_kyber.read_addr);
//    $dumpvars(1, u_sc.u_sc.scan_reg);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.permutation_ready);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.addr_a_delay);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.addr_a);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.temp_coeff_arrayA);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.temp_coeff_array);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.S);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.bit_bias);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.coeff_counter);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.hash_buffer);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.hash_buffer_sel_buf);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.P_out);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.mem_rd_PK);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.mem_rd0);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.mem_rd1);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.mem_rdA0);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.mem_rdA1);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.mem_rdA);
// //    $dumpvars(1, u_sc.u_kyber.u_server_client.mem_rdB);
// //    //$dumpvars(1, u_sc.u_kyber.u_server_client.rounds);
//  end


// --------------------------------------------------------------------------------
// Signals
// --------------------------------------------------------------------------------
parameter SC_SIZE = 523;
reg clk;
reg clk1, clk2, clk1_en, clk2_en;
reg scan_in, update, capture, rst_n, kyber_rst_n;
wire scan_out;
reg start;
reg [127:0] message, genmat_message, encr_message, msg_in;
reg v_path_decrypt;
reg b_path_decrypt;
reg read_external; 
wire trigger;
reg [15:0] read_data1, read_data2, read_data3;
reg [10:0] read_addr;
reg [523-1:0] scan_reg_data;

reg [SC_SIZE -1:0] test_in;
reg [47:0] serial_out_reg;
integer i,j,k,l;
integer outfile;


// --------------------------------------------------------------------------------
// Design Under Test
// --------------------------------------------------------------------------------
scanchain_top  u_sc (	
	.CLK1(clk1),
    .CLK2(clk2),

    .SCAN_IN(scan_in),
    .UPDT(update),
    .CAPTURE(capture),
    .SCAN_OUT(scan_out),

	//.clk(clk&start),
	.RD_clk(clk),
    .RD_rst_n(rst_n),
	.RD_kyber_rst_n(kyber_rst_n),

	.RD_start(start),
	.RD_v_path_decrypt(v_path_decrypt),
	.RD_b_path_decrypt(b_path_decrypt),
	.RD_read_external(read_external),
	.RD_trigger(trigger),
	.RD_serial_out(serial_out)
);

// scanchain_top  u_sc (	
// 	.clk1(clk1),
//     .clk2(clk2),

//     .scan_in(scan_in),
//     .update(update),
//     .capture(capture),
//     .scan_out(scan_out),

// 	//.clk(clk&start),
// 	.clk(clk),
//     .rst_n(rst_n),
// 	.kyber_rst_n(kyber_rst_n),

// 	.start(start),
// 	.v_path_decrypt(v_path_decrypt),
// 	.b_path_decrypt(b_path_decrypt),
// 	.read_external(read_external),
// 	.trigger(trigger),
// 	.serial_out(serial_out)
// );

// --------------------------------------------------------------------------------
// Primary clock 
// --------------------------------------------------------------------------------
always begin

	clk = 1; #(0.5*CLK_PERIOD);
	clk = 0; #(0.5*CLK_PERIOD);
end

// --------------------------------------------------------------------------------
// Clk1 for scanchain
// --------------------------------------------------------------------------------
always @ (posedge clk) begin
    if (clk1_en) begin
		// clk1 <= 1; 
        // // #2; clk1 <= 0;
        // #(0.2*CLK_PERIOD); clk1 <= 0;

		clk1 = 1; 
        #(0.2*CLK_PERIOD); clk1 = 0;
	end
end

// --------------------------------------------------------------------------------
// Clk2 for scanchain
// --------------------------------------------------------------------------------
always @ (posedge clk) begin
	if (clk2_en) begin
        // #7; clk2 <= 1; 
        // #2; clk2 <= 0;
        // #(0.7*CLK_PERIOD); clk2 <= 1; 
        // #(0.2*CLK_PERIOD); clk2 <= 0;	

		#(0.7*CLK_PERIOD); clk2 = 1; 
        #(0.2*CLK_PERIOD); clk2 = 0;	
	end
end


initial begin

	$sdf_annotate("/home/sparclab/a/sayeeda/03_Rudraksh_TSMC_0425/Synthesis/Rudraksh_dual_sram_tsmc_with_sdf/APR6/mysdf", u_sc);
	
// --------------------------------------------------------------------------------
// Initialize Signals
// --------------------------------------------------------------------------------
    scan_in = 0;
	update = 0;
	capture = 0;
	kyber_rst_n = 0;
	rst_n = 0;

	start = 0;  
	read_external = 0;
	read_addr = 5;
	v_path_decrypt = 1;
	b_path_decrypt = 0;
	message = 128'h58256fdfef6a5f8fa09c171607a93bdd;
	encr_message = 128'hf1331ed7b60e3046af42d91d554bfa45;
	genmat_message = 128'hea97e8a6e6dd65e2873f1cc1d44098d8;
//message = 128'hcf38cee9258c5c995db8d9a58e4f1910;
//encr_message = 128'h12701b2b9930f79f24bab3c408e8410b;
//genmat_message = 128'he84c3788427f1c371d76f4efcdc1044e;
	msg_in = 128'h0f0e0d0c0b0a09080706050403020100;   
	scan_reg_data = {msg_in, message, encr_message, genmat_message, read_addr};

	#(CLK_PERIOD);
	rst_n = 1;

// --------------------------------------------------------------------------------
// Scan In to Kyber 
// --------------------------------------------------------------------------------
 
	clk1_en = 1;
	clk2_en = 1;

	
	for (i = 0; i < SC_SIZE ; i = i +1) begin
		scan_in = scan_reg_data[SC_SIZE -1 -i];
		update = 0; 	#(0.5*CLK_PERIOD);
		update = 1; 	#(0.5*CLK_PERIOD);	
	end	
	
	update = 0;	
	#(0.5*CLK_PERIOD);
	update = 1; 
	#(0.5*CLK_PERIOD);
	clk2_en = 0;
	update = 0;
	$display("SCAN COMPLETE");

	#(100*CLK_PERIOD);
	kyber_rst_n = 1;
	

// --------------------------------------------------------------------------------
// Run Kyber 
// --------------------------------------------------------------------------------
	start = 1;
	v_path_decrypt = 1;
	b_path_decrypt = 0;
	wait(trigger);
	$display("Trigger reached");
	#CLK_PERIOD; 
	#(100*CLK_PERIOD);  //Added by abdullah

	@(negedge clk);
	read_external = 1;
	read_addr = 5;
	#(2*CLK_PERIOD);

	for (i = 47; i >= 0 ; i = i -1) begin
			serial_out_reg[i] = serial_out;
        	#(CLK_PERIOD);  
	   	end	


// --------------------------------------------------------------------------------
// Scan Out of Kyber 
// --------------------------------------------------------------------------------
 
	// clk2_en = 1;
	// capture = 1; 
	// #(CLK_PERIOD);
	// capture = 0;


	// for (i = 0; i < 16 ; i = i +1) begin
	// 		read_data1[16 -1 -i] = scan_out;
    //     	/*update = 1;*/	#(0.5*CLK_PERIOD); //works w/update
    //     	/*update = 0;*/	#(0.5*CLK_PERIOD); //works w/update	
    // 	end	

	
	// // for (i = 0; i < 16 ; i = i +1) begin
    // //     	read_data2[16 -1 -i] = scan_out;
    // //     	clk2 = 1; clk1 = 0; update = 0; 	#(0.5*CLK_PERIOD);
    // //     	clk2 = 0; clk1 = 1;update = 1; 	#(0.5*CLK_PERIOD);
    // // 	end

	// // for (i = 0; i < 16 ; i = i +1) begin
    // //     	read_data3[16 -1 -i] = scan_out;
    // //     	clk2 = 1; clk1 = 0; update = 0; 	#(0.5*CLK_PERIOD);
    // //     	clk2 = 0; clk1 = 1; update = 1; 	#(0.5*CLK_PERIOD);
    // // 	end

	// //update = 0; //works w/update
	// #(0.5*CLK_PERIOD);

	// //update = 1; #(0.5*CLK_PERIOD); //works w/update
	// //update = 0;                    //works w/update
	// clk2_en = 0;

	// if(read_data1 == 16'h1771) $display("V PASSED");
	// else  $display("V FAIL");

	if(serial_out_reg[47:32] == 16'h1771) $display("Serial Out: Read Data 1 PASSED");
	else  $display("Serial Out: Read Data 1 FAIL");
	if(serial_out_reg[31:16] == 16'h17A4) $display("Serial Out: Read Data 2 PASSED");
	else  $display("Serial Out: Read Data 2 FAIL");
	if(serial_out_reg[15:0] == 16'h0019) $display("Serial Out: Read Data 3 PASSED");
	else  $display("Serial Out: Read Data 3 FAIL");

	// outfile=$fopen("SCAN_OUT_TEST.txt","w");
	// for (i=0; i<16; i=i+1) begin
	// 	$fwrite(outfile, "%d\n", read_data1[16-1-i]);
	// end
	// $fclose(outfile);  

	outfile=$fopen("SERIAL_OUT_TEST.txt","w");
	for (i=0; i<48; i=i+1) begin
		$fwrite(outfile, "%d", serial_out_reg[48-1-i]);
	end
	$fclose(outfile);  

// --------------------------------------------------------------------------------
// Initialize Signals
// --------------------------------------------------------------------------------
    scan_in = 0;
	update = 0;
	capture = 0;
	kyber_rst_n = 0;
	rst_n = 0;

	

	start = 0;  
	read_external = 0;
	read_addr = 5;
	v_path_decrypt = 0;
	b_path_decrypt = 1;

	scan_reg_data = {msg_in, message, encr_message, genmat_message, read_addr};

	#(CLK_PERIOD);
	rst_n = 1;


// --------------------------------------------------------------------------------
// Scan In to Kyber 
// --------------------------------------------------------------------------------
	read_addr = 5;
	clk1_en = 1;
	clk2_en = 1;

	
	for (i = 0; i < SC_SIZE ; i = i +1) begin
		scan_in = scan_reg_data[SC_SIZE -1 -i];
		update = 0; 	#(0.5*CLK_PERIOD);
		update = 1; 	#(0.5*CLK_PERIOD);	
	end	
	
	update = 0;	
	#(0.5*CLK_PERIOD);
	update = 1; 
	#(0.5*CLK_PERIOD);
	clk2_en = 0;
	update = 0;
	$display("SCAN COMPLETE");

	#(100*CLK_PERIOD);
	kyber_rst_n = 1;

// --------------------------------------------------------------------------------
// Run Kyber 
// --------------------------------------------------------------------------------
	start = 1;
	v_path_decrypt = 0;
	b_path_decrypt = 1;
	wait(trigger);
	$display("Trigger reached");
	#CLK_PERIOD; 
	#(100*CLK_PERIOD);  //Added by abdullah

	@(negedge clk);
	read_external = 1;
	read_addr = 5;
	#(2*CLK_PERIOD);

	for (i = 47; i >= 0 ; i = i -1) begin
			serial_out_reg[i] = serial_out;
        	#(CLK_PERIOD);  
	   	end	



// --------------------------------------------------------------------------------
// Scan Out of Kyber 
// --------------------------------------------------------------------------------
 
	// clk2_en = 1;
	// capture = 1; 
	// #(CLK_PERIOD);
	// capture = 0;


	// for (i = 0; i < 16 ; i = i +1) begin
	// 		read_data1[16 -1 -i] = scan_out;
    //     	/*update = 1;*/	#(0.5*CLK_PERIOD); //works w/update
    //     	/*update = 0;*/	#(0.5*CLK_PERIOD); //works w/update	
    // 	end	

	// for (i = 0; i < 16 ; i = i +1) begin
	// 		read_data2[16 -1 -i] = scan_out;
    //     	/*update = 1;*/	#(0.5*CLK_PERIOD); //works w/update
    //     	/*update = 0;*/	#(0.5*CLK_PERIOD); //works w/update	
    // 	end	

	// for (i = 0; i < 16 ; i = i +1) begin
	// 		read_data3[16 -1 -i] = scan_out;
    //     	/*update = 1;*/	#(0.5*CLK_PERIOD); //works w/update
    //     	/*update = 0;*/	#(0.5*CLK_PERIOD); //works w/update	
    // 	end	


	// //update = 0; //works w/update
	// #(0.5*CLK_PERIOD);

	// //update = 1; #(0.5*CLK_PERIOD); //works w/update
	// //update = 0;                    //works w/update
	// clk2_en = 0;

	// if(read_data3 == 16'h1dd5) $display("MP Mem1 PASSED");
	// else  $display("MP Mem1 FAIL: %x", read_data3);
	// if(read_data2 == 16'h178b) $display("MP Mem0 PASSED");
	// else  $display("MP Mem0 FAIL: %x", read_data2);

	if(serial_out_reg[47:32] == 16'h0BBB) $display("Serial Out: Read Data 1 PASSED");
	else  $display("Serial Out: Read Data 1 FAIL");
	if(serial_out_reg[31:16] == 16'h178B) $display("Serial Out: Read Data 2 PASSED");
	else  $display("Serial Out: Read Data 2 FAIL");
	if(serial_out_reg[15:0] == 16'h1DD5) $display("Serial Out: Read Data 3 PASSED");
	else  $display("Serial Out: Read Data 3 FAIL");

	// outfile=$fopen("SCAN_OUT_TEST2.txt","w");
	// for (i=0; i<16; i=i+1) begin
	// 	$fwrite(outfile, "%d\n", read_data2[16-1-i]);
	// end
	// for (i=0; i<16; i=i+1) begin
	// 	$fwrite(outfile, "%d\n", read_data3[16-1-i]);
	// end
	// $fclose(outfile);  

	outfile=$fopen("SERIAL_OUT_TEST2.txt","w");
	for (i=0; i<48; i=i+1) begin
		$fwrite(outfile, "%d", serial_out_reg[48-1-i]);
	end
	$fclose(outfile);  


/*	#(100*CLK_PERIOD);
	/
	#(100*CLK_PERIOD);

	//#(100000*CLK_PERIOD);
*/
    $finish;
end
// Periodic time printing 
initial begin 
$timeformat(-9, 2, " ns", 20); // Format time output 
forever begin  
#PRINT_INTERVAL; 
$display("Current simulation time: %t", $time);
//if($isunknown(u_sc.u_kyber.u_server_client.state)) begin
//$fatal("x propagate to server_client_state");
//end
 
end 
end

endmodule
