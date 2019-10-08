`include "Ebox.v"
`include "Ibox.v"
`include "Icache.v"
`include "Mbox.v"
`include "Basics.v"

module Alpha (input clk);
  
  /*reg clk;
  initial clk = 0;
  always #5 clk = ~clk;*/

  wire [63:0] ibox_in1, ibox_in2, ibox_result,
              reg_w_data, reg_read_a, reg_read_b, reg_read_b5, mem_w_data, pc, pc2;
  wire [31:0] inst;
  wire [30:0] ibox_ctrl;
  wire [15:0] displacement;
  wire [7:0] literal;
  wire [4:0] reg_w_addr, ra_addr, ra_addr_wb, rb_addr, rc_addr_wb;  
  wire [1:0] irf_m1_sel, mbox_m1_sel;
  wire ibox_flag, reg_w ,reg_w_en, mem_w, irf_m2_sel, mbox_m2_sel, mbox_m3_sel;
  wire ldl, stc;
  
  Icache icache (
      .data (inst),
      .addr (pc)
      );
      
  Ebox ebox (
      // outputs:
      .ibox_ctrl (ibox_ctrl),
      .pc (pc),
      .pc2 (pc2),
      .reg_w (reg_w),
      .mem_w (mem_w),
      .irf_m2_sel (irf_m2_sel),
      .irf_m1_sel (irf_m1_sel),
      .mbox_m1_sel (mbox_m1_sel),
      .mbox_m2_sel (mbox_m2_sel),
      .mbox_m3_sel (mbox_m3_sel),
      .ldl (ldl),
      .stc (stc),
      //.mbox_ext_ctrl (),
      //.mbox_mem_ctrl (),
      .literal (literal),
      .displacement (displacement),
      .ra_addr (ra_addr),
      .ra_addr_wb (ra_addr_wb),
      .rb_addr (rb_addr),
      .rc_addr_wb (rc_addr_wb),
      // inputs:
      .inst (inst),
      .reg_read_a (reg_read_a),
      .reg_read_b (reg_read_b),
      .ibox_flag (ibox_flag),
      .clk (clk)
      );
      
  IRF irf (
      // outputs:
      .out1 (ibox_in1),
      .out2 (ibox_in2),
      .reg_read_a (reg_read_a),
      .reg_read_a4 (mem_w_data),
      .reg_read_b (reg_read_b),
      .reg_read_b5 (reg_read_b5),
      // inputs:
      .read_addr_a (ra_addr),
      .read_addr_b (rb_addr),
      .write_addr (reg_w_addr),
      .write_data (reg_w_data),
      .pc2 (pc2),
      .displacement (displacement),
      .literal (literal),
      .mux1_sel (irf_m1_sel),
      .mux2_sel (irf_m2_sel),
      .write_en (reg_w_en),
      .clk (clk)
      );
      
  Ibox ibox (
      .a (ibox_in1),
      .b (ibox_in2),
      .result (ibox_result),
      .control (ibox_ctrl),
      .ibox_flag (ibox_flag),
      .clk (clk)
      );
      
  Mbox mbox (
      // outputs:
      .reg_w_data (reg_w_data),
      .reg_w_addr (reg_w_addr),
      .reg_w_en (reg_w_en),
      // inputs:
      .ibox_result (ibox_result),
      .mem_w_data (mem_w_data),
      .ra_addr (ra_addr_wb),
      .rc_addr (rc_addr_wb),
      .mem_w (mem_w),
      .reg_w (reg_w),
      .reg_read_b5 (reg_read_b5),
      //.mem_w_ctrl (), 
      //.ext_ctrl (),
      .mux1_sel (mbox_m1_sel),
      .mux2_sel (mbox_m2_sel),
      .mux3_sel (mbox_m3_sel),
      .ldl (ldl),
      .stc (stc),
      .clk (clk)
      );
      
endmodule
