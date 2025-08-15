module mem_top(

    input clk,

    input start_encr, v_start, v_start_delay1, debug_reset, external_write,
    input ep_accumulate, accumulate_start, extr_mul, decrypt_start,
    input intt_start, swap_write_delay7, swap_write_delay6, ntt_start_delay5,
    input read_external, no_ntt, secret_gen, b_out_en, v_out_en,
    
    input [10:0] addr_bias, addr_bias1, addr_bias_genmat, addr_bias_mult, 
    input [10:0] ext_addr, addr_a, addr_a_delay, addr_mult, addr_mult_wr6,
    input [10:0] wr_addr0, wr_addr1, secret_error_addr, rd_addr0, rd_addr1, rd_addr1_intt, read_addr,
    
    input [9:0] server_counter, server_counter_delay, server_counter_delay_delay_delay,
    input [3:0] acc_counter,
    input [5:0] addr_acc, addr_acc_minus_one,
    
    output [15:0] mem_rd_PK, 
	input [15:0] accumulate_out, external_data, data_in,
    input [15:0] ntt_out0, ntt_out1, poly_compressed_out,
    input [12:0] b_out, v_out, secret_error0, secret_error1,
    
    input secret_error_write, temp_coeff_arrayA_valid, addr_mult_we_reg,
    
    output [9:0] addr0_poly_bram_0_dport, addr0_poly_bram_1_dport,
    output [9:0] addr1_poly_bram_0_dport, addr1_poly_bram_1_dport,
    output [10:0] addr0_memory_pk, addr1_memory_pk,
    output [10:0] addr0_poly_bram_true_dport_2, addr1_poly_bram_true_dport_2,
    output [15:0] din0_poly_bram_0_dport, din0_poly_bram_1_dport, din0_memory_pk,
    output [15:0] din0_poly_bram_true_dport_2,
    output [15:0] mem_rd0, mem_rd1, mem_rdA, mem_rdB, mem_rdA0, mem_rdA1,
    output we0_poly_bram_0_dport, we0_poly_bram_1_dport, we0_memory_pk,
    output we0_poly_bram_true_dport_2,
    input mem_pk_sk_transfer,
    input mem_sk_pk_transfer,
    input server_counter_start,
    input ep_gen,
    input [9:0] server_counter_delay_delay_delay_delay,
    input decode_start,
    input [10:0] addr_bias_acc,
    input [15:0] compressed_out,
    input hash_h_start,
    input [10:0] hash_read_addr

);
    //POLY BRAM 0 DPORT-------------------------------------------------------------------------------------------------------------------
    assign addr0_poly_bram_0_dport = mem_pk_sk_transfer ? (server_counter_delay[9:1] + addr_bias) : 
                                            (ep_accumulate & ~server_counter[0]) ? server_counter[9:1]+addr_bias : 
                                            	(ep_accumulate & server_counter[0])? server_counter[9:1]+addr_bias1 ://Archisman 29 oct 
                                                (accumulate_start & extr_mul) ? addr_acc_minus_one[5:1] : 
                                                    decrypt_start & (~server_counter_delay[5]) ? (addr_bias + server_counter_delay) :
                                                        ntt_start_delay5 ? wr_addr0 : secret_error_addr+addr_bias;

    assign din0_poly_bram_0_dport = mem_pk_sk_transfer ? mem_rd_PK : 
                                        (accumulate_start & extr_mul) ? accumulate_out : 
                                            decrypt_start ? b_out : 
                                                secret_error_write ? secret_error0 : 
                                                    (intt_start ? swap_write_delay7 : swap_write_delay6) ? ntt_out1 : ntt_out0;

    assign we0_poly_bram_0_dport = mem_pk_sk_transfer ? ~server_counter_delay[0] :
			//	ep_accumulate ? server_counter_delay[0] : //Archisman 29 oct
                                    (((accumulate_start & extr_mul & addr_acc > 0 & (acc_counter == 0)) ? ~addr_acc_minus_one[0]: 1'b0 )|((server_counter_start & ntt_start_delay5 & (~ep_gen)))|(secret_error_write & ~accumulate_start & ~extr_mul)|(decrypt_start & (~server_counter_delay[5])));

    assign addr1_poly_bram_0_dport = read_external ? read_addr : 
                                        mem_sk_pk_transfer ? {2'b0, server_counter[9:1]} :
					     (ep_accumulate & ~server_counter[0]) ? server_counter[9:1]+addr_bias : 
                                            	(ep_accumulate & server_counter[0])? server_counter[9:1]+addr_bias1 ://Archisman 29 oct 
                                                (v_start & (~ext_addr[5])) ? ext_addr :
                                                    accumulate_start ? (576 + {6'b0,addr_acc[5:1]}) : 
                                                        no_ntt ? ({1'b0,addr_a[10:1]} + addr_bias_genmat) : 
                                                            extr_mul ? (server_counter[9:1]+addr_bias) :
                                                                secret_gen ? ({1'b0,addr_mult[10:1]} + addr_bias - 32/*{1'b0, addr_bias_mult[10:1]}*/) : rd_addr0;
    wire [15:0 ]dout0_poly_bram_0_dport;
    //assign mem_rdA0 = dout0_poly_bram_0_dport;
    //Archisman comments 29oct
    //assign mem_rdA0 = dout0_poly_bram_0_dport;

    wire [15:0] dout1_poly_bram_0_dport;
    assign mem_rd0 = dout1_poly_bram_0_dport;

  //  rfmem_cm2_880x16_000 u1_rf(
  //      .ickwp0(clk), 
  //      .iwenp0(we0_poly_bram_0_dport), 
  //      .iawp0(addr0_poly_bram_0_dport), 
  //      .idinp0(din0_poly_bram_0_dport), 
  //      .ickrp0(clk), 
  //      .irenp0(1'b1), 
  //      .iarp0(addr0_poly_bram_0_dport), 
  //      .iclkbyp(1'b0), 
  //      .imce(1'b0), 
  //      .irmce(2'b0), 
  //      .ifuse(1'b0), 
  //      .iwmce(4'b0),
  //  `ifndef INTC_NO_PWR_PINS
  //      .vcc_nom(),                                                         
  //      .vss(),
  //  `endif 
  //  .odoutp0(dout0_poly_bram_0_dport));

    // rfmem_cm2_880x16_000 u2_rf(
    //     .ickwp0(clk), 
    //     .iwenp0(we0_poly_bram_0_dport), 
    //     .iawp0(addr0_poly_bram_0_dport), 
    //     .idinp0(din0_poly_bram_0_dport), 
    //     .ickrp0(clk), 
    //     .irenp0(1'b1), 
    //     .iarp0(addr1_poly_bram_0_dport), 
    //     .iclkbyp(1'b0), 
    //     .imce(1'b0), 
    //     .irmce(2'b0), 
    //     .ifuse(1'b0), 
    //     .iwmce(4'b0),
    // `ifndef INTC_NO_PWR_PINS
    //     .vcc_nom(),                                                         
    //     .vss(),
    // `endif 
    // .odoutp0(dout1_poly_bram_0_dport));

    //Port A for write, Port B for read
    // tsmc_dualport_880 u2_rf(
    //     .AA(addr0_poly_bram_0_dport),
    //     .DA(din0_poly_bram_0_dport),
    //     .BWEBA(16'b0),
    //     .WEBA(~we0_poly_bram_0_dport),
    //     .CEBA(1'b0),
    //     .CLKA(clk),

    //     .AB(addr1_poly_bram_0_dport),
    //     .DB(16'b0),
    //     .BWEBB(16'b0),
    //     .WEBB(1'b1),
    //     .CEBB(1'b0),
    //     .CLKB(clk),

    //     .AMA(10'b0),
    //     .DMA(16'b0),
    //     .BWEBMA(16'b0),
    //     .WEBMA(1'b1),
    //     .CEBMA(1'b1),

    //     .AMB(10'b0),
    //     .DMB(16'b0),
    //     .BWEBMB(16'b0),
    //     .WEBMB(1'b1),
    //     .CEBMB(1'b1),

    //     .AWT(1'b0),
    //     .BIST(1'b0),
    //     .CLKM(clk),

    //     .QA(),
    //     .QB(dout1_poly_bram_0_dport)
    // );

    TSDN65LPA896X16M4M u2_rf(
        .AA(addr0_poly_bram_0_dport),
        .DA(din0_poly_bram_0_dport),
        .BWEBA(16'b0),
        .WEBA(~we0_poly_bram_0_dport),
        .CEBA(1'b0),
        .CLKA(clk),
        .AB(addr1_poly_bram_0_dport),
        .DB(16'b0),
        .BWEBB(16'b0),
        .WEBB(1'b1),
        .CEBB(1'b0),
        .CLKB(clk),
        .QA(),
        .QB(dout1_poly_bram_0_dport)
    );

    //POLY BRAM 1 DPORT-------------------------------------------------------------------------------------------------------------------
    assign addr0_poly_bram_1_dport = mem_pk_sk_transfer ? (server_counter_delay[9:1] + addr_bias) : 
                                        ep_accumulate ? ({~server_counter[4], ~server_counter[3], ~server_counter[2], ~server_counter[1], ~server_counter[0]} + addr_bias) : 
                                            (accumulate_start & extr_mul) ? addr_acc_minus_one[5:1] : 
                                                decrypt_start & (server_counter_delay[5]) ? (addr_bias + {server_counter_delay[9:6],~server_counter_delay[5],server_counter_delay[4:0]}) :
                                                    ntt_start_delay5 ? wr_addr1 : secret_error_addr+addr_bias;


    assign din0_poly_bram_1_dport = mem_pk_sk_transfer ? mem_rd_PK : 
                                        (accumulate_start & extr_mul) ? accumulate_out : 
                                            decrypt_start ? b_out : 
                                                secret_error_write ? secret_error1 : 
                                                    (intt_start ? swap_write_delay7 : swap_write_delay6) ? ntt_out0 : ntt_out1;


    assign we0_poly_bram_1_dport = mem_pk_sk_transfer ? server_counter_delay[0] :
                                    (((accumulate_start & extr_mul /*& addr_acc > 0*/ & (acc_counter == 0))? addr_acc_minus_one[0]: 1'b0 )|((server_counter_start & ntt_start_delay5 & (~ep_gen)))|(secret_error_write & ~accumulate_start & ~extr_mul) |(decrypt_start & server_counter_delay[5]));

//Archisman changes this file and below 29 oct
    assign addr1_poly_bram_1_dport = read_external ? read_addr : 
                                    mem_sk_pk_transfer ? {server_counter[9:6], ~server_counter[5], ~server_counter[4], ~server_counter[3], ~server_counter[2], ~server_counter[1]}: 
                                        (ep_accumulate & ~server_counter[0]) ? ({~server_counter[5], ~server_counter[4], ~server_counter[3], ~server_counter[2], ~server_counter[1]} + addr_bias) : 
                                        (ep_accumulate & server_counter[0]) ? server_counter[5:1] + addr_bias1 : 
                                            (v_start & (ext_addr[5])) ? ext_addr :
                                                accumulate_start ? (576+ 31 - {5'b0,addr_acc[5:1]}) : 
                                                    no_ntt ? ({1'b0,addr_a[10:1]} + addr_bias_genmat) : 
                                                        extr_mul ? ({server_counter[9:6], ~server_counter[5], ~server_counter[4], ~server_counter[3], ~server_counter[2], ~server_counter[1]} + addr_bias) :
                                                            secret_gen ? {10'd31 + addr_bias - 32/*{1'b0, addr_bias_mult[10:1]}*/ - {1'b0,addr_mult[10:1]}} : intt_start? rd_addr1_intt:rd_addr1;

//    rfmem_cm2_880x16_000 u3_rf(
//    .ickwp0(clk), 
//    .iwenp0(we0_poly_bram_1_dport), 
//    .iawp0(addr0_poly_bram_1_dport), 
//    .idinp0(din0_poly_bram_1_dport), 
//    .ickrp0(clk), 
//    .irenp0(1'b1), 
//    .iarp0(addr0_poly_bram_1_dport), 
//    .iclkbyp(1'b0), 
//    .imce(1'b0), 
//    .irmce(2'b0), 
//    .ifuse(1'b0), 
//    .iwmce(4'b0),
//    `ifndef INTC_NO_PWR_PINS
//        .vcc_nom(),                                                         
//        .vss(),
//    `endif 
//    .odoutp0(mem_rdA1));

// rfmem_cm2_880x16_000 u4_rf(
//     .ickwp0(clk), 
//     .iwenp0(we0_poly_bram_1_dport), 
//     .iawp0(addr0_poly_bram_1_dport), 
//     .idinp0(din0_poly_bram_1_dport), 
//     .ickrp0(clk), 
//     .irenp0(1'b1), 
//     .iarp0(addr1_poly_bram_1_dport), 
//     .iclkbyp(1'b0), 
//     .imce(1'b0), 
//     .irmce(2'b0), 
//     .ifuse(1'b0), 
//     .iwmce(4'b0),
//     `ifndef INTC_NO_PWR_PINS
//         .vcc_nom(),                                                         
//         .vss(),
//     `endif 
//     .odoutp0(mem_rd1));


//Port A for write, Port B for read
    // tsmc_dualport_880 u4_rf(
    //     .AA(addr0_poly_bram_1_dport),
    //     .DA(din0_poly_bram_1_dport),
    //     .BWEBA(16'b0),
    //     .WEBA(~we0_poly_bram_1_dport),
    //     .CEBA(1'b0),
    //     .CLKA(clk),

    //     .AB(addr1_poly_bram_1_dport),
    //     .DB(16'b0),
    //     .BWEBB(16'b0),
    //     .WEBB(1'b1),
    //     .CEBB(1'b0),
    //     .CLKB(clk),

    //     .AMA(10'b0),
    //     .DMA(16'b0),
    //     .BWEBMA(16'b0),
    //     .WEBMA(1'b1),
    //     .CEBMA(1'b1),

    //     .AMB(10'b0),
    //     .DMB(16'b0),
    //     .BWEBMB(16'b0),
    //     .WEBMB(1'b1),
    //     .CEBMB(1'b1),

    //     .AWT(1'b0),
    //     .BIST(1'b0),
    //     .CLKM(clk),

    //     .QA(),
    //     .QB(mem_rd1)
    // );

    TSDN65LPA896X16M4M u4_rf(
        .AA(addr0_poly_bram_1_dport),
        .DA(din0_poly_bram_1_dport),
        .BWEBA(16'b0),
        .WEBA(~we0_poly_bram_1_dport),
        .CEBA(1'b0),
        .CLKA(clk),
        .AB(addr1_poly_bram_1_dport),
        .DB(16'b0),
        .BWEBB(16'b0),
        .WEBB(1'b1),
        .CEBB(1'b0),
        .CLKB(clk),
        .QA(),
        .QB(mem_rd1)
    );


    //POLY BRAM TRUE DPORT 2-------------------------------------------------------------------------------------------------------------------
    assign addr0_poly_bram_true_dport_2 = v_start_delay1 ? server_counter_delay :
                                            (ep_accumulate & v_out_en) ? (server_counter_delay_delay_delay_delay[9:1] +addr_bias_mult) : //Archisman 29oct 
                                                accumulate_start ? {acc_counter,addr_acc} :
                                                    (debug_reset | external_write) ? ext_addr : 
                                                        no_ntt ? (addr_a_delay+addr_bias_genmat) : 
                                                            extr_mul ? (addr_mult_wr6):
                                                                secret_gen ? (addr_mult_wr6+addr_bias_mult) : (addr_a_delay+addr_bias_genmat);

    assign din0_poly_bram_true_dport_2 = (ep_accumulate & v_out_en) ? poly_compressed_out : 
                                            v_start_delay1 ? v_out : 
                                                external_write ? external_data : data_in;


    assign we0_poly_bram_true_dport_2 = ep_accumulate & (~b_out_en) ? 1'b1 : 
                                            (read_external|accumulate_start) ? 1'b0 : 
                                                external_write ? 1'b1 : 
                                                    v_start_delay1 ? 1'b1 : (temp_coeff_arrayA_valid) | addr_mult_we_reg | debug_reset;

    assign addr1_poly_bram_true_dport_2 = decode_start ? server_counter : 
                                            read_external ? read_addr : 
                                                no_ntt ? (addr_a+addr_bias_genmat) : 
                                                    extr_mul ? addr_mult : (addr_mult+addr_bias_genmat);

    wire [15:0] dout0_poly_bram_true_dport_2;
    assign mem_rdB = dout0_poly_bram_true_dport_2;

    wire [15:0] dout1_poly_bram_true_dport_2;
    assign mem_rdA = dout1_poly_bram_true_dport_2;

    // rfmem_cm2_1280x16_000 u5_rf(
    //     .ickwp0(clk), 
    //     .iwenp0(we0_poly_bram_true_dport_2), 
    //     .iawp0(addr0_poly_bram_true_dport_2), 
    //     .idinp0(din0_poly_bram_true_dport_2), 
    //     .ickrp0(clk), 
    //     .irenp0(1'b1), 
    //     .iarp0(addr0_poly_bram_true_dport_2), 
    //     .iclkbyp(1'b0), 
    //     .imce(1'b0), 
    //     .irmce(2'b0), 
    //     .ifuse(1'b0), 
    //     .iwmce(4'b0),
    //     `ifndef INTC_NO_PWR_PINS
    //         .vcc_nom(),                                                         
    //         .vss(),
    //     `endif 
    //     .odoutp0(dout0_poly_bram_true_dport_2));

    //Port A for write, Port B for read
    // tsmc_dualport_1280 u5_rf(
    //     .AA(addr0_poly_bram_true_dport_2),
    //     .DA(din0_poly_bram_true_dport_2),
    //     .BWEBA(16'b0),
    //     .WEBA(~we0_poly_bram_true_dport_2),
    //     .CEBA(1'b0),
    //     .CLKA(clk),

    //     .AB(addr0_poly_bram_true_dport_2),
    //     .DB(16'b0),
    //     .BWEBB(16'b0),
    //     .WEBB(1'b1),
    //     .CEBB(1'b0),
    //     .CLKB(clk),

    //     .AMA(11'b0),
    //     .DMA(16'b0),
    //     .BWEBMA(16'b0),
    //     .WEBMA(1'b1),
    //     .CEBMA(1'b1),

    //     .AMB(11'b0),
    //     .DMB(16'b0),
    //     .BWEBMB(16'b0),
    //     .WEBMB(1'b1),
    //     .CEBMB(1'b1),

    //     .AWT(1'b0),
    //     .BIST(1'b0),
    //     .CLKM(clk),

    //     .QA(),
    //     .QB(dout0_poly_bram_true_dport_2)
    // );

        TSDN65LPA1280X16M4M u5_rf(
        .AA(addr0_poly_bram_true_dport_2),
        .DA(din0_poly_bram_true_dport_2),
        .BWEBA(16'b0),
        .WEBA(~we0_poly_bram_true_dport_2),
        .CEBA(1'b0),
        .CLKA(clk),
        .AB(addr0_poly_bram_true_dport_2),
        .DB(16'b0),
        .BWEBB(16'b0),
        .WEBB(1'b1),
        .CEBB(1'b0),
        .CLKB(clk),
        .QA(),
        .QB(dout0_poly_bram_true_dport_2)
    );

    

    // rfmem_cm2_1280x16_000 u6_rf(
    //     .ickwp0(clk), 
    //     .iwenp0(we0_poly_bram_true_dport_2), 
    //     .iawp0(addr0_poly_bram_true_dport_2), 
    //     .idinp0(din0_poly_bram_true_dport_2), 
    //     .ickrp0(clk), 
    //     .irenp0(1'b1), 
    //     .iarp0(addr1_poly_bram_true_dport_2), 
    //     .iclkbyp(1'b0), 
    //     .imce(1'b0), 
    //     .irmce(2'b0), 
    //     .ifuse(1'b0), 
    //     .iwmce(4'b0),
    //     `ifndef INTC_NO_PWR_PINS
    //         .vcc_nom(),                                                         
    //         .vss(),
    //     `endif 
    //     .odoutp0(dout1_poly_bram_true_dport_2));



    //Port A for write, Port B for read
    // tsmc_dualport_1280 u6_rf(
    //     .AA(addr0_poly_bram_true_dport_2),
    //     .DA(din0_poly_bram_true_dport_2),
    //     .BWEBA(16'b0),
    //     .WEBA(~we0_poly_bram_true_dport_2),
    //     .CEBA(1'b0),
    //     .CLKA(clk),

    //     .AB(addr1_poly_bram_true_dport_2),
    //     .DB(16'b0),
    //     .BWEBB(16'b0),
    //     .WEBB(1'b1),
    //     .CEBB(1'b0),
    //     .CLKB(clk),

    //     .AMA(11'b0),
    //     .DMA(16'b0),
    //     .BWEBMA(16'b0),
    //     .WEBMA(1'b1),
    //     .CEBMA(1'b1),

    //     .AMB(11'b0),
    //     .DMB(16'b0),
    //     .BWEBMB(16'b0),
    //     .WEBMB(1'b1),
    //     .CEBMB(1'b1),

    //     .AWT(1'b0),
    //     .BIST(1'b0),
    //     .CLKM(clk),

    //     .QA(),
    //     .QB(dout1_poly_bram_true_dport_2)
    // );

    TSDN65LPA1280X16M4M u6_rf(
        .AA(addr0_poly_bram_true_dport_2),
        .DA(din0_poly_bram_true_dport_2),
        .BWEBA(16'b0),
        .WEBA(~we0_poly_bram_true_dport_2),
        .CEBA(1'b0),
        .CLKA(clk),
        .AB(addr1_poly_bram_true_dport_2),
        .DB(16'b0),
        .BWEBB(16'b0),
        .WEBB(1'b1),
        .CEBB(1'b0),
        .CLKB(clk),
        .QA(),
        .QB(dout1_poly_bram_true_dport_2)
    );

    //MEMORY PK-------------------------------------------------------------------------------------------------------------------   
    assign addr0_memory_pk = v_start_delay1 ? server_counter_delay :
                    mem_sk_pk_transfer ? server_counter_delay : 
                        (ep_accumulate & b_out_en) ? (server_counter_delay_delay_delay[9:1] + addr_bias_mult) : addr_acc_minus_one + addr_bias_acc;

    assign din0_memory_pk = v_start_delay1 ? v_out : 
                                (mem_sk_pk_transfer &server_counter_delay[0]) ? mem_rd1 : 
                                    mem_sk_pk_transfer ? mem_rd0 : 
                                        (ep_accumulate & b_out_en) ? compressed_out : data_in;

    assign we0_memory_pk = v_start_delay1 ? 1'b1 : 
                            ((ep_accumulate & ~v_out_en)|mem_sk_pk_transfer) ? 1'b1 :(acc_counter == 1 & accumulate_start);

    assign addr1_memory_pk = decrypt_start ? (server_counter + addr_bias_genmat) : 
                                mem_pk_sk_transfer ? (server_counter + addr_bias_genmat) : 
                                    extr_mul ? addr_mult : 
                                        hash_h_start ? hash_read_addr : 10'd639;

    wire [15:0] dout1_memory_pk;
    assign mem_rd_PK = dout1_memory_pk;


    // rfmem_cm2_1280x16_000 u7_rf(
    //     .ickwp0(clk), 
    //     .iwenp0(we0_memory_pk), 
    //     .iawp0(addr0_memory_pk), 
    //     .idinp0(din0_memory_pk), 
    //     .ickrp0(clk), 
    //     .irenp0(1'b1), 
    //     .iarp0(addr1_memory_pk), 
    //     .iclkbyp(1'b0), 
    //     .imce(1'b0), 
    //     .irmce(2'b0), 
    //     .ifuse(1'b0), 
    //     .iwmce(4'b0),
    //     `ifndef INTC_NO_PWR_PINS
    //         .vcc_nom(),                                                         
    //         .vss(),
    //     `endif 
    //     .odoutp0(dout1_memory_pk));


    //Port A for write, Port B for read
    // tsmc_dualport_1280 u7_rf(
    //         .AA(addr0_memory_pk),
    //         .DA(din0_memory_pk),
    //         .BWEBA(16'b0),
    //         .WEBA(~we0_memory_pk),
    //         .CEBA(1'b0),
    //         .CLKA(clk),

    //         .AB(addr1_memory_pk),
    //         .DB(16'b0),
    //         .BWEBB(16'b0),
    //         .WEBB(1'b1),
    //         .CEBB(1'b0),
    //         .CLKB(clk),

    //         .AMA(11'b0),
    //         .DMA(16'b0),
    //         .BWEBMA(16'b0),
    //         .WEBMA(1'b1),
    //         .CEBMA(1'b1),

    //         .AMB(11'b0),
    //         .DMB(16'b0),
    //         .BWEBMB(16'b0),
    //         .WEBMB(1'b1),
    //         .CEBMB(1'b1),

    //         .AWT(1'b0),
    //         .BIST(1'b0),
    //         .CLKM(clk),

    //         .QA(),
    //         .QB(dout1_memory_pk)
    //     );

    TSDN65LPA1280X16M4M u7_rf(
        .AA(addr0_memory_pk),
        .DA(din0_memory_pk),
        .BWEBA(16'b0),
        .WEBA(~we0_memory_pk),
        .CEBA(1'b0),
        .CLKA(clk),
        .AB(addr1_memory_pk),
        .DB(16'b0),
        .BWEBB(16'b0),
        .WEBB(1'b1),
        .CEBB(1'b0),
        .CLKB(clk),
        .QA(),
        .QB(dout1_memory_pk)
    );

endmodule
