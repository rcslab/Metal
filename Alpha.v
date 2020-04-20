`include "Ebox.v"
`include "Ibox.v"
`include "Icache.v"
`include "Mbox.v"
`include "Basics.v"

module Alpha (input clk,
  
  output [63:0] ibox_in1, ibox_in2, ibox_result, ibox_result4, pc, reg_w_data, mem_out, reg_a, m_reg_out, m_reg_data,
  output [4:0] reg_w_addr,
  output [3:0] m_reg_addr,
  output [2:0] irf_m3_sel, irf_m4_sel,
  output [1:0] irf_m1_sel,
  output reg_w_en, reg_w, m_exit, mem_w_en, cmp_out, m_reg_w_en,
  output [31:0] inst, inst2, inst3, inst4, inst5, ibox_ctrl);

  wire [63:0] /*ibox_in1, ibox_in2, ibox_result, ibox_result4,*/
              /*reg_w_data,*/ saved_pc, /*reg_a,*/ reg_b, reg_a4, reg_b5/*, pc, mem_out, m_reg_out, m_reg_data*/;
  /*wire [31:0] inst;*/
  /*wire [31:0] ibox_ctrl;*/
  wire [31:0] icache_out, metal_out, mux1_in[0:1];
  wire [15:0] displacement;
  wire [7:0] literal;
  wire [4:0] /*reg_w_addr,*/ ra_addr, ra_addr_wb, rb_addr, rc_addr_wb;  
 // wire [3:0] m_reg_addr;
  wire [1:0] /*irf_m1_sel,*/ mbox_m1_sel;
//  wire [2:0] irf_m3_sel, irf_m4_sel;
  wire ibox_exc, mbox_exc, icache_stall, metal_stall, i_stall, d_stall, metal_range;
  wire /*reg_w,*/ /*reg_w_en, m_reg_w_en, mem_w_en,*/ irf_m2_sel, mbox_m2_sel, mbox_m3_sel;

  
  assign metal_range = (pc >= 64'hffffffffffff0000);
  Icache icache (
      .data (icache_out),
      .addr (pc),
      .read_en(metal_range ? 0 : 1),
      .stall (icache_stall)
      );

  Icache #(.Metal(1)) metal_mem (
      .data (metal_out),
      .addr (pc),
      .read_en(metal_range ? 1 : 0),
      .stall (metal_stall)
      );

  assign i_stall = icache_stall | metal_stall;

  assign mux1_in[0] = icache_out;
  assign mux1_in[1] = metal_out;
  Mux #(.BITS(32), .WORDS(2)) mux1(
      .out (inst),
      .sel (metal_range),
      .in (mux1_in)
      );


  Ebox ebox (
      // outputs:
      .ibox_ctrl (ibox_ctrl),
      .pc (pc),
      .reg_w (reg_w),
      .m_reg_w_en (m_reg_w_en),
      .mem_w_en (mem_w_en),
      .irf_m2_sel (irf_m2_sel),
      .irf_m1_sel (irf_m1_sel),
      .irf_m3_sel (irf_m3_sel),
      .irf_m4_sel (irf_m4_sel),
      .mbox_m1_sel (mbox_m1_sel),
      .mbox_m2_sel (mbox_m2_sel),
      .mbox_m3_sel (mbox_m3_sel),
      .m_reg_addr (m_reg_addr),
      .m_reg_data (m_reg_data),
      .ibox_result4 (ibox_result4),
      //.mbox_ext_ctrl (),
      //.mbox_mem_ctrl (),

      .literal (literal),
      .displacement (displacement),
      .ra_addr (ra_addr),
      .ra_addr_wb (ra_addr_wb),
      .rb_addr (rb_addr),
      .rc_addr_wb (rc_addr_wb),
      
      // debug:
      .inst2 (inst2),
      .inst3 (inst3),
      .inst4 (inst4),
      .inst5 (inst5),
      .m_exit(m_exit),
      .cmp_out (cmp_out),
      
      // inputs:
      .inst (inst),
      .reg_a (reg_a),
      .reg_b (reg_b),
      .i_stall (i_stall),
      .d_stall (d_stall),
      .ibox_result (ibox_result),
      .saved_pc (saved_pc),
      .ibox_exc (ibox_exc),
      .mbox_exc (mbox_exc),
      .clk (clk)
      );
      
  IRF irf (
      // outputs:
      .out1 (ibox_in1),
      .out2 (ibox_in2),
      .reg_a (reg_a),
      .reg_a4 (reg_a4),
      .reg_b (reg_b),
      .reg_b5 (reg_b5),
      // inputs:
      .read_addr_a (ra_addr),
      .read_addr_b (rb_addr),
      .write_addr (reg_w_addr),
      .write_data (reg_w_data),
      .pc (pc),
      .displacement (displacement),
      .literal (literal),
      .mux1_sel (irf_m1_sel),
      .mux2_sel (irf_m2_sel),
      .mux3_sel (irf_m3_sel),
      .mux4_sel (irf_m4_sel),
      .mem_out (mem_out),
      .m_reg_out (m_reg_out),
      .ibox_result3 (ibox_result),
      .ibox_result4 (ibox_result4),
      .write_en (reg_w_en),
      .clk (clk)
      );
      
  Ibox ibox (
      .a (ibox_in1),
      .b (ibox_in2),
      .result (ibox_result),
      .control (ibox_ctrl),
      .ibox_flag (ibox_exc)
      );
      
  Mbox mbox (
      // outputs:
      .reg_w_data (reg_w_data),
      .reg_w_addr (reg_w_addr),
      .reg_w_en (reg_w_en),
      .stall (d_stall),
      .mem_data_out (mem_out),
      .m_reg_out (m_reg_out),
      .saved_pc (saved_pc),
      .exc_out (mbox_exc),
      // inputs:
      .ibox_result (ibox_result4),
      .reg_a4 (reg_a4),
      .reg_b5 (reg_b5),
      .ra_addr (ra_addr_wb),
      .rc_addr (rc_addr_wb),
      .mem_w_en (mem_w_en),
      .reg_w (reg_w),
      .m_reg_addr (m_reg_addr),
      .m_reg_data (m_reg_data),
      .m_reg_w_en (m_reg_w_en),
      //.mem_w_ctrl (), 
      //.ext_ctrl (),
      .mux1_sel (mbox_m1_sel),
      .mux2_sel (mbox_m2_sel),
      .mux3_sel (mbox_m3_sel),
      .clk (clk)
      );
      
endmodule
