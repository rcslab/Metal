/* verilator lint_off DECLFILENAME */

`include "Basics.v"

module Mbox (output [63:0] reg_w_data,
            output [4:0] reg_w_addr,
            output reg_w_en,
            input [63:0] ibox_result, mem_w_data, reg_read_b5,
            input[4:0] ra_addr, rc_addr,
            input [1:0] mux1_sel,
            input ldl, stc, reg_w, mem_w, /*mem_w_ctrl, ext_ctrl,*/ mux2_sel, mux3_sel, clk);

  reg [63:0] ibox_result5;
  wire [63:0] mem_data_out, mux1_in[0:3];
  wire [4:0] mux2_in[0:1];
  wire mux3_in[0:1];
  reg locked_flag, locked_flag5;
  
  always @(ldl or stc) begin
    if (ldl) locked_flag = 1;
    if (stc) locked_flag = 0;
  end
  
  always @(posedge clk) begin
    ibox_result5 <= ibox_result;
    locked_flag5 <= locked_flag;
  end
  
  DCache dcache (
        .dataOut (mem_data_out),
        .dataIn (mem_w_data),
        .addr (ibox_result),
        .writeEn (mem_w | (stc & locked_flag)),
        .clk (clk)
        );
  
  assign mux1_in[0] = ibox_result5;
  assign mux1_in[1] = mem_data_out;
  assign mux1_in[2] = reg_read_b5;
  assign mux1_in[3] = {63'b0, locked_flag5};
  Mux #(.BITS(64), .WORDS(4)) mux1(
      .out (reg_w_data),
      .sel (mux1_sel),
      .in (mux1_in)
      );

  assign mux2_in[0] = rc_addr;
  assign mux2_in[1] = ra_addr;
  Mux #(.BITS(5), .WORDS(2)) mux2(
      .out (reg_w_addr),
      .sel (mux2_sel),
      .in (mux2_in)
      );
      
  assign mux3_in[0] = reg_w;
  assign mux3_in[1] = ibox_result5[0];
  Mux #(.BITS(1), .WORDS(2)) mux3(
      .out (reg_w_en),
      .sel (mux3_sel),
      .in (mux3_in)
      );
      
endmodule

/* verilator lint_off WIDTH */
module DCache (output[63:0] dataOut, input[63:0] dataIn, addr, input clk, writeEn);
  reg[7:0] dMem[0:1023];
  wire [9:0] a;
  assign a = addr[9:0];
  always@(posedge clk) begin
    if(writeEn) begin
      {dMem[a], dMem[a+1], dMem[a+2], dMem[a+3], dMem[a+4], dMem[a+5], dMem[a+6], dMem[a+7]} <= dataIn;
      dataOut <= dataIn;
    end
    else dataOut <= {dMem[a], dMem[a+1], dMem[a+2], dMem[a+3], dMem[a+4], dMem[a+5], dMem[a+6], dMem[addr+7]};
  end
endmodule
/* verilator lint_on WIDTH */
