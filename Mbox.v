/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSED */

`include "Basics.v"

module Mbox (output [63:0] reg_w_data, mem_data_out, m_reg_out, saved_pc,
            output [4:0] reg_w_addr,
            output reg_w_en, stall, exc,
            input [63:0] ibox_result, reg_a4, reg_b5, pc3,
            input[4:0] ra_addr, rb_addr, rc_addr,
            input [1:0] mux1_sel,
            input m_enter, exc3, reg_w, m_reg_w_en, mem_w_en, /*mem_w_ctrl, ext_ctrl,*/ mux2_sel, mux3_sel, clk);

  reg [63:0] ibox_result5, mem_out5, m_reg_out5;
  wire [63:0] mux1_in[0:3];
  wire [4:0] mux2_in[0:1];
  wire mux3_in[0:1];
  reg exc34;

  assign exc = 0;  
  always @(posedge clk) begin
    ibox_result5 <= ibox_result;
    mem_out5 <= mem_data_out;
    m_reg_out5 <= m_reg_out;
    exc34 <= exc3;
  end
  
  DCache dcache (
        .data_out (mem_data_out),
        .stall (stall),
        .data_in (reg_a4),
        .addr (ibox_result),
        .write_en (mem_w_en),
        .clk (clk)
        );

  Metal_reg_file metal_regs (
      .reg_out (m_reg_out),
      .saved_pc (saved_pc),
      .addr (m_enter ? 4'h7 : ((exc | exc34) ? 4'h6 : rb_addr[3:0])),
      .write_data ((exc | exc34 | m_enter) ? pc3 : reg_a4),
      .write_en (m_reg_w_en | m_enter | exc | exc34),
      .clk(clk)
      );
  
  assign mux1_in[0] = ibox_result5;
  assign mux1_in[1] = mem_out5;
  assign mux1_in[2] = reg_b5;
  assign mux1_in[3] = m_reg_out5;
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

module Metal_reg_file (output [63:0] reg_out, saved_pc,
            input [3:0] addr,
            input [63:0] write_data,
            input write_en, clk);
  reg [63:0] register[0:15];
  always @(negedge clk) begin
    if (write_en)  register[addr] <= write_data;
  end
  assign reg_out = register[addr];
  assign saved_pc = register[7];
endmodule

/* verilator lint_off WIDTH */
module DCache (output reg [63:0] data_out, output stall, input[63:0] data_in, addr, input clk, write_en);
 // reg[31:0] temp[0:127];
  reg[7:0] dmem[0:1023];
  wire [9:0] a;
  assign stall = 0;
  assign a = addr[9:0];
  integer i;
  initial begin 
    dmem[7] = 8'h80;
    dmem[15] = 8'h8c;
    dmem[23] = 8'h9c;
//    $readmemh("data.mem", temp);
//    for (i = 0; i < 128; i = i + 4)
//      {dmem[i], dmem[i+1], dmem[i+2], dmem[i+3]} = temp[i/4];
  end
  always@(negedge clk) begin
    if(write_en) begin
      {dmem[a], dmem[a+1], dmem[a+2], dmem[a+3], dmem[a+4], dmem[a+5], dmem[a+6], dmem[a+7]} <= data_in;
      data_out <= data_in;
    end
    else begin data_out <= {dmem[a], dmem[a+1], dmem[a+2], dmem[a+3], dmem[a+4], dmem[a+5], dmem[a+6], dmem[addr+7]}; end
  end
endmodule
/* verilator lint_on UNUSED */
/* verilator lint_on WIDTH */
