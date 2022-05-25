/*-------------------------------------------------------------------------
File name   : apb_subsystem_top.v 
Title       : Top level file for the testbench 
Project     : APB Subsystem
Created     : March 2008
Description : This is top level file which instantiate the dut apb_subsyste,.v.
              It also has the assertion module which checks for the power down 
              and power up.To activate the assertion ifdef LP_ABV_ON is used.       
Notes       :
-------------------------------------------------------------------------*/ 
//   Copyright 1999-2010 Cadence Design Systems, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------

 `timescale 1ns/10ps


// Environment Constants
`ifndef AHB_DATA_WIDTH
  `define AHB_DATA_WIDTH          32              // AHB bus data width [32/64]
`endif
`ifndef AHB_ADDR_WIDTH
  `define AHB_ADDR_WIDTH          32              // AHB bus address width [32/64]
`endif
`ifndef AHB_DATA_MAX_BIT
  `define AHB_DATA_MAX_BIT        31              // MUST BE: AHB_DATA_WIDTH - 1
`endif
`ifndef AHB_ADDRESS_MAX_BIT
  `define AHB_ADDRESS_MAX_BIT     31              // MUST BE: AHB_ADDR_WIDTH - 1
`endif
`ifndef DEFAULT_HREADY_VALUE
  `define DEFAULT_HREADY_VALUE    1'b1            // Ready Asserted
`endif

`include "ahb_if.sv"
`include "apb_if.sv"
`include "apb_master_if.sv"
`include "apb_slave_if.sv"
`include "uart_if.sv"
`include "spi_if.sv"
`include "gpio_if.sv"
`include "coverage/uart_ctrl_internal_if.sv"

module apb_subsystem_top;
  import uvm_pkg::*;
  // Import the UVM Utilities Package

  import ahb_pkg::*;
  import apb_pkg::*;
  import uart_pkg::*;
  import gpio_pkg::*;
  import spi_pkg::*;
  import uart_ctrl_pkg::*;
  import apb_subsystem_pkg::*;

  `include "spi_reg_model.sv"
  `include "gpio_reg_model.sv"
  `include "apb_subsystem_reg_rdb.sv"
  `include "uart_ctrl_reg_seq_lib.sv"
  `include "spi_reg_seq_lib.sv"
  `include "gpio_reg_seq_lib.sv"

  //Include module UVC sequences
  `include "ahb_user_monitor.sv"
  `include "apb_subsystem_seq_lib.sv"
  `include "apb_subsystem_vir_sequencer.sv"
  `include "apb_subsystem_vir_seq_lib.sv"

  `include "apb_subsystem_tb.sv"
  `include "test_lib.sv"
   
  
   // ====================================
   // SHARED signals
   // ====================================
   
   // clock
   reg tb_hclk;
   
   // reset
   reg hresetn;
   
   // post-mux from master mux
   wire [`AHB_DATA_MAX_BIT:0] hwdata;
   wire [`AHB_ADDRESS_MAX_BIT:0] haddr;
   wire [1:0]  htrans;
   wire [2:0]  hburst;
   wire [2:0]  hsize;
   wire [3:0]  hprot;
   wire hwrite;

   // post-mux from slave mux
   wire        hready;
   wire [1:0]  hresp;
   wire [`AHB_DATA_MAX_BIT:0] hrdata;
  

  //  Specific signals of apb subsystem
  reg         ua_rxd;
  reg         ua_ncts;


  // uart outputs 
  wire        ua_txd;
  wire        us_nrts;

  wire   [7:0] n_ss_out;    // peripheral select lines from master
  wire   [31:0] hwdata_byte_alligned;

  reg [2:0] div8_clk;
 always @(posedge tb_hclk) begin
   if (!hresetn)
     div8_clk = 3'b000;
   else
     div8_clk = div8_clk + 1;
 end


  // Master virtual interface
  ahb_if ahbi_m0(.ahb_clock(tb_hclk), .ahb_resetn(hresetn));
  
  uart_if uart_s0(.clock(div8_clk[2]), .reset(hresetn));
  uart_if uart_s1(.clock(div8_clk[2]), .reset(hresetn));
  spi_if spi_s0();
  gpio_if gpio_s0();
  uart_ctrl_internal_if uart_int0(.clock(div8_clk[2]));
  uart_ctrl_internal_if uart_int1(.clock(div8_clk[2]));

  apb_if apbi_mo(.pclock(tb_hclk), .preset(hresetn));

  //M0
  assign ahbi_m0.AHB_HCLK = tb_hclk;
  assign ahbi_m0.AHB_HRESET = hresetn;
  assign ahbi_m0.AHB_HRESP = hresp;
  assign ahbi_m0.AHB_HRDATA = hrdata;
  assign ahbi_m0.AHB_HREADY = hready;

  assign apbi_mo.paddr = u_socv.i_apb_subsystem.i_ahb2apb.paddr;
  assign apbi_mo.prwd = u_socv.i_apb_subsystem.i_ahb2apb.pwrite;
  assign apbi_mo.pwdata = u_socv.i_apb_subsystem.i_ahb2apb.pwdata;
  assign apbi_mo.penable = u_socv.i_apb_subsystem.i_ahb2apb.penable;
  assign apbi_mo.psel = {12'b0, u_socv.i_apb_subsystem.i_ahb2apb.psel8, u_socv.i_apb_subsystem.i_ahb2apb.psel2, u_socv.i_apb_subsystem.i_ahb2apb.psel1, u_socv.i_apb_subsystem.i_ahb2apb.psel0};
  assign apbi_mo.prdata = u_socv.i_apb_subsystem.i_ahb2apb.psel0? u_socv.i_apb_subsystem.i_ahb2apb.prdata0 : (u_socv.i_apb_subsystem.i_ahb2apb.psel1? u_socv.i_apb_subsystem.i_ahb2apb.prdata1 : (u_socv.i_apb_subsystem.i_ahb2apb.psel2? u_socv.i_apb_subsystem.i_ahb2apb.prdata2 : u_socv.i_apb_subsystem.i_ahb2apb.prdata8));

  assign spi_s0.sig_n_ss_in = n_ss_out[0];
  assign spi_s0.sig_n_p_reset = hresetn;
  assign spi_s0.sig_pclk = tb_hclk;

  assign gpio_s0.n_p_reset = hresetn;
  assign gpio_s0.pclk = tb_hclk;

  assign hwdata_byte_alligned = (ahbi_m0.AHB_HADDR[1:0] == 2'b00) ? ahbi_m0.AHB_HWDATA : {4{ahbi_m0.AHB_HWDATA[7:0]}};
 
  socv u_socv (
	  
	  .ua_RXDA1_pad     (uart_s1.txd),
	  .SMC_addr_pad     (32'd0),
	  .SMC_data_pad     (32'd0),
	  .SMC_n_wr_pad     (1'b0),
	  .GPIO_pad         (gpio_s0.gpio_pin_in[15:0]),
	 
	  .macb0_rx_clk_pad (tb_hclk),
	  .macb0_tx_clk_pad (tb_hclk),
	  .macb1_rx_clk_pad (tb_hclk),
	  .macb1_tx_clk_pad (tb_hclk),
	  .macb2_rx_clk_pad (tb_hclk),
	  .macb2_tx_clk_pad (tb_hclk),
	  .macb3_rx_clk_pad (tb_hclk),
	  .macb3_tx_clk_pad (tb_hclk),
	  .pin_hclk_pad     (tb_hclk),
	  .pin_reset_pad    (hresetn),
	  
	  .scan_mode        (1'b0), //Remove once the tap is in place
	  .spi_N_ss_in_pad  (1'b1),
	  .spi_SIMO_pad     (spi_s0.sig_si),
	  .spi_SOMI_pad     (spi_s0.sig_so),
	  
	  .macb0_tx_en_pad  (1'b0),
	  .macb1_tx_en_pad  (1'b0),
	  .macb2_tx_en_pad  (1'b0),
	  .macb3_tx_en_pad  (1'b0),
	  
	  .spi_N_ss_out_pad (n_ss_out[7:0]),
	  .macb0_txd_pad    (hrdata),
	 
	  .ua_RXDA_pad      (),
	  .ua_NCTS_pad      (),
	  .ua_NCTS1_pad     (),
	  .ua_NRTS_pad      (),
	  .ua_NRTS1_pad     (),
	  .macb0_crs_pad    (),
	  .macb0_rx_dv_pad  (),
	  .macb0_rx_er_pad  (),
	  .macb0_rxd_pad    (),
	  .macb0_tx_er_pad  (),
	 
	  .macb1_crs_pad    (),
	  .macb1_rx_dv_pad  (),
	  .macb1_rx_er_pad  (),
	  .macb1_rxd_pad    (),
	  .macb1_tx_er_pad  (),
	  .macb1_txd_pad    (),
	 
	  .macb2_crs_pad    (),
	  .macb2_rx_dv_pad  (),
	  .macb2_rx_er_pad  (),
	  .macb2_rxd_pad    (),
	  .macb2_tx_er_pad  (),
	  .macb2_txd_pad    (),
	  
	  .macb3_crs_pad    (),
	  .macb3_rx_dv_pad  (),
	  .macb3_rx_er_pad  (),
	  .macb3_rxd_pad    (),
	  .macb3_tx_er_pad  (),
	  .macb3_txd_pad    (),
	  
	  .macb_mdio_in_pad (),
	  .macb_mdio_out_pad(),
	 
	  .macb_mdc_pad     (),
	  .macb_mdio_en_pad (),
	 
	  .rrefext_pad      (),
	  .pin_sysclk_pad   (),
	  .shift_en_pad     (),
	  .spi_CLK_pad      (),
	  
	  .ua_TXDA1_pad     (),
	  .ua_TXDA_pad      (),
	  .core06v          (),
	  .core08v          (),
	  .core10v          (),
	  .core12v          (),
	
	  .SMC_n_CS_pad     (),
	  .SMC_n_be_pad     (),
	  .SMC_n_rd_pad     (),
	  .SMC_n_we_pad     (),
	  .MBIST_en_pad     (),
	  .dn_pad           (),
	  .dp_pad           (),
	  .jtag_NTRST_pad   (),
	  .jtag_TCK_pad     (),
	  .jtag_TDI_pad     (),
	  .jtag_TDO_pad     (),
	  .jtag_TMS_pad     (),
	  
	  .macb0_col_pad    (),
	  .macb1_col_pad    (),
	  .macb2_col_pad    (),
	  .macb3_col_pad    ()
  );

initial
begin
  tb_hclk = 0;
  hresetn = 1;

  #1 hresetn = 0;
  #1200 hresetn = 1;
end

always #50 tb_hclk = ~tb_hclk;

initial begin
  uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top.ve.uart0*", "vif", uart_s0);
  uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top.ve.uart1*", "vif", uart_s1);
  uvm_config_db#(virtual uart_ctrl_internal_if)::set(null, "uvm_test_top.ve.apb_ss_env.apb_uart0.*", "vif", uart_int0);
  uvm_config_db#(virtual uart_ctrl_internal_if)::set(null, "uvm_test_top.ve.apb_ss_env.apb_uart1.*", "vif", uart_int1);
  uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.ve.apb0*", "vif", apbi_mo);
  uvm_config_db#(virtual ahb_if)::set(null, "uvm_test_top.ve.ahb0*", "vif", ahbi_m0);
  uvm_config_db#(virtual spi_if)::set(null, "uvm_test_top.ve.spi0*", "spi_if", spi_s0);
  uvm_config_db#(virtual gpio_if)::set(null, "uvm_test_top.ve.gpio0*", "gpio_if", gpio_s0);
  run_test();
end

endmodule
