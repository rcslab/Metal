/* verilator lint_off DECLFILENAME */

`include "Basics.v"
      
module Ebox (output [30:0] ibox_ctrl,
            output reg [63:0] pc, pc2,
            output reg_w, mem_w, irf_m2_sel, mbox_m2_sel, mbox_m3_sel, ldl, stc,
            output [1:0] irf_m1_sel, mbox_m1_sel,
            output [7:0] literal,
            output [15:0] displacement,
            output [4:0] ra_addr, ra_addr_wb, rb_addr, rc_addr_wb,
            input [31:0] inst,
            input [63:0] reg_read_a, reg_read_b,
            input ibox_flag,
            input clk);
  /* verilator lint_off UNUSED */          
  reg [31:0] inst2, inst3, inst4, inst5;
  /* verilator lint_on UNUSED */
  reg [63:0] pcp42;
  wire [63:0] pc_in, pcp4, pc_adder_in, br_addr, jmp_addr, mux1_in[0:1], mux2_in[0:3];
  wire [31:0] inst2_in, inst3_in, mux3_in[0:1], mux4_in[0:1];
  wire exc, bubble, jump, jump5, branch, cmov, stc, stc5, ldl, cmp_out;
  
  assign reg_w = (inst5[31:26] == 6'h11 || inst5[31:26] == 6'h12 || inst5[31:26] == 6'h13
               || inst5[31:26] == 6'h08 || inst5[31:26] == 6'h09 || inst5[31:26] == 6'h0A || inst5[31:26] == 6'h0B
               || inst5[31:26] == 6'h0C || inst5[31:26] == 6'h28 || inst5[31:26] == 6'h29 || inst5[31:26] == 6'h2A
               || inst5[31:26] == 6'h2B);
                   
  assign mem_w = (inst4[31:26] == 6'h0D || inst4[31:26] == 6'h0E || inst4[31:26] == 6'h0F || inst4[31:26] == 6'h2C
                || inst4[31:26] == 6'h2D);
  assign jump = (inst2[31:26] == 6'h1A);
  assign jump5 = (inst5[31:26] == 6'h1A);
  assign branch = (inst2[31:30] == 2'h3);
  assign exc = ibox_flag;
  assign bubble = jump | branch | exc;
  assign cmov = inst5[31:26] == 6'h11 && (inst5[8:5] == 4'h4 || inst5[8:5] == 4'h6);
  assign stc = inst4[31:26] == 6'h2E || inst4[31:26] == 6'h2F;
  assign stc5 = inst5[31:26] == 6'h2E || inst5[31:26] == 6'h2F;
  assign ldl = inst4[31:26] == 6'h2A || inst4[31:26] == 6'h2B;
  
  assign irf_m1_sel = {jump, ~inst2[30]};
  assign irf_m2_sel = inst2[12];
  assign mbox_m1_sel = {cmov | stc5, ~inst5[30] | stc5};
  assign mbox_m2_sel = ~inst5[30] | jump5;
  assign mbox_m3_sel = cmov;
  assign literal = inst2[20:13];
  assign displacement = inst2[15:0];
  assign ra_addr = inst2[25:21];
  assign rb_addr = inst2[20:16];
  assign ra_addr_wb = inst5[25:21];
  assign rc_addr_wb = inst5[4:0];
  
  always @(posedge clk) begin
    pc <= pc_in;
    pc2 <= pc;
    pcp42 <= pcp4;
    inst2 <= inst2_in;
    inst3 <= inst3_in;
    inst4 <= inst3;
    inst5 <= inst4;
  end
    
  assign mux1_in[0] = pc;
  assign mux1_in[1] = pc2;
  Mux #(.BITS(64), .WORDS(2)) mux1(
      .out (pc_adder_in),
      .sel (bubble),
      .in (mux1_in)
      );
      
  assign pcp4 = pc_adder_in + 4;
  assign br_addr = pcp42 + ({{43{inst2[20]}}, inst2[20:0]} << 2);
  assign jmp_addr = reg_read_b & (~64'b011);
  
  assign mux2_in[0] = pcp4;
  assign mux2_in[1] = br_addr;
  assign mux2_in[2] = jmp_addr;
  assign mux2_in[3] = 0; //////////////////// exc_addr
  Mux #(.BITS(64), .WORDS(4)) mux2(
      .out (pc_in),
      .sel ({jump | exc, (cmp_out & branch) | exc}),
      .in (mux2_in)
      );
  
  assign mux3_in[0] = inst;
  assign mux3_in[1] = 0; ////////////////// NOP
  Mux #(.BITS(32), .WORDS(2)) mux3(
      .out (inst2_in),
      .sel (bubble),
      .in (mux3_in)
      );
      
  assign mux4_in[0] = inst2;
  assign mux4_in[1] = 0; ////////////////// NOP
  Mux #(.BITS(32), .WORDS(2)) mux4(
      .out (inst3_in),
      .sel (exc),
      .in (mux4_in)
      );
      
  Br_comparator br_cmp(
      .out (cmp_out),
      .a (reg_read_a),
      .op (inst2[29:26])
      );
    
  IboxController ibox(
      .out(ibox_ctrl),
      .in({inst3[31:26], inst3[11:5]})
      );

endmodule

module Br_comparator (output reg out, input [63:0] a, input[3:0] op);
  reg l, e;
  always @* begin
    l = a[63];
    e = ~(|a);
    case (op)
      0, 4: out = 1;
      8: out = ~a[0]; // BLBC
      9: out = e; // ==
      10: out = l; // <
      11: out = e | l; // <=
      12: out = a[0]; // BLBS
      13: out = ~e; // !=
      14: out = e | ~l; // >=
      15: out = ~l & ~e; // >
    endcase
  end
endmodule

module IboxController #(parameter LITTLE_ENDIAN = 1) (output [30:0] out, input [12:0] in);
    
  /*wire [5:0] n_shift_ctrl;
  wire [1:0] shifter_ctrl;
  wire [3:0] alu_ctrl;
  wire [2:0] cmp_ctrl;
  wire [4:0] mei_ctrl;
  wire [2:0] xor_ctrl;
  wire mux0_ctrl, mux1_ctrl;
  wire [2:0] mux2_ctrl;
  wire [1:0] mux3_ctrl;
  
  assign out = {n_shift_ctrl, shifter_ctrl, alu_ctrl, cmp_ctrl, mei_ctrl, xor_ctrl, mux0_ctrl, mux1_ctrl, mux2_ctrl, mux3_ctrl};
  assign n_shift_ctrl = 
  assign shifter_ctrl =
  assign alu_ctrl =
  assign cmp_ctrl =
  assign mei_ctrl =
  assign xor_ctrl = 
  assign mux0_ctrl =
  assign mux1_ctrl =
  assign mux2_ctrl =
  assign mux3_ctrl =*/
  
  always @* begin
    casez (in)
    /* {opcode, func} <-> {n_shift_ctrl, shifter_ctrl, alu_ctrl, cmp_ctrl, mei_ctrl, xor_ctrl, mux0_ctrl,
                          mux1_ctrl, mux2_ctrl, mux3_ctrl, v} */
      {6'h08, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // LDA
      {6'h09, 7'h?}: out = {6'h10, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // LDAH
      {6'h0A, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h7, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0, 1'b0}; // LDBU
      {6'h0B, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h3, 2'h0, 1'b0}; // LDQ_U
      {6'h0C, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h6, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0, 1'b0}; // LDWU
      {6'h0D, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h6, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0, 1'b0}; // STW
      {6'h0E, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h7, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0, 1'b0}; // STB
      {6'h0F, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h3, 2'h0, 1'b0}; // STQ_U
      {6'h28, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h4, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0, 1'b0}; // LDL
      {6'h29, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0, 1'b0}; // LDQ
      {6'h2A, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h4, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0, 1'b0}; // LDL_L
      {6'h2B, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0, 1'b0}; // LDQ_L
      {6'h2C, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h4, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0, 1'b0}; // STL
      {6'h2D, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0, 1'b0}; // STQ
      {6'h2E, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h4, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0, 1'b0}; // STL_C
      {6'h2F, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0, 1'b0}; // STQ_C
      
      {6'h10 , 7'h00}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0, 1'b0}; // ADDL
      {6'h10 , 7'h02}: out = {6'h2, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0, 1'b0}; // S4ADDL
      {6'h10 , 7'h09}: out = {6'h0, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0, 1'b0}; // SUBL
      {6'h10 , 7'h0B}: out = {6'h2, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0, 1'b0}; // S4SUBL
      {6'h10 , 7'h0F}: out = {6'h0, 2'h0, 4'h6, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // CMPBGE
      {6'h10 , 7'h12}: out = {6'h3, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0, 1'b0}; // S8ADDL
      {6'h10 , 7'h1B}: out = {6'h3, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0, 1'b0}; // S8SUBL
      {6'h10 , 7'h1D}: out = {6'h0, 2'h0, 4'h2, 3'h5, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0, 1'b0}; // CMPULT
      {6'h10 , 7'h20}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // ADDQ
      {6'h10 , 7'h22}: out = {6'h2, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // S4ADDQ
      {6'h10 , 7'h29}: out = {6'h0, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // SUBQ
      {6'h10 , 7'h2B}: out = {6'h2, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // S4SUBQ
      {6'h10 , 7'h2D}: out = {6'h0, 2'h0, 4'h2, 3'h2, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0, 1'b0}; // CMPEQ
      {6'h10 , 7'h32}: out = {6'h3, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // S8ADDQ
      {6'h10 , 7'h3B}: out = {6'h3, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // S8SUBQ
      {6'h10 , 7'h3D}: out = {6'h0, 2'h0, 4'h2, 3'h6, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0, 1'b0}; // CMPULE
      {6'h10 , 7'h40}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0, 1'b1}; // ADDL/V
      {6'h10 , 7'h49}: out = {6'h0, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0, 1'b1}; // SUBL/V
      {6'h10 , 7'h4D}: out = {6'h0, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0, 1'b0}; // CMPLT
      {6'h10 , 7'h60}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b1}; // ADDQ/V
      {6'h10 , 7'h69}: out = {6'h0, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b1}; // SUBQ/V
      {6'h10 , 7'h6D}: out = {6'h0, 2'h0, 4'h2, 3'h3, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0, 1'b0}; // CMPLE
      
      {6'h11 , 7'h00} : out = {6'h0, 2'h0, 4'h3, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // AND
      {6'h11 , 7'h08} : out = {6'h0, 2'h0, 4'h3, 3'h0, 5'h0, 3'h0, 1'b0, 1'b1, 3'h0, 2'h0, 1'b0}; // BIC
      {6'h11 , 7'h14} : out = {6'h3f, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0, 1'b0}; // CMOVLBS
      {6'h11 , 7'h16} : out = {6'h3f, 2'h0, 4'h0, 3'h2, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0, 1'b0}; // CMOVLBC
      {6'h11 , 7'h20} : out = {6'h0, 2'h0, 4'h4, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // BIS
      {6'h11 , 7'h24} : out = {6'h0, 2'h0, 4'h0, 3'h3, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0, 1'b0}; // CMOVEQ
      {6'h11 , 7'h26} : out = {6'h0, 2'h0, 4'h0, 3'h7, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0, 1'b0}; // CMOVNE
      {6'h11 , 7'h28} : out = {6'h0, 2'h0, 4'h4, 3'h0, 5'h0, 3'h0, 1'b0, 1'b1, 3'h0, 2'h0, 1'b0}; // ORNOT
      {6'h11 , 7'h40} : out = {6'h0, 2'h0, 4'h5, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // XOR
      {6'h11 , 7'h44} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0, 1'b0}; // CMOVLT
      {6'h11 , 7'h46} : out = {6'h0, 2'h0, 4'h0, 3'h4, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0, 1'b0}; // CMOVGE
      {6'h11 , 7'h48} : out = {6'h0, 2'h0, 4'h5, 3'h0, 5'h0, 3'h0, 1'b0, 1'b1, 3'h0, 2'h0, 1'b0}; // EQV
      //{6'h11 , 7'h61} : // AMASK
      {6'h11 , 7'h64} : out = {6'h0, 2'h0, 4'h0, 3'h3, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0, 1'b0}; // CMOVLE
      {6'h11 , 7'h66} : out = {6'h0, 2'h0, 4'h0, 3'h1, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0, 1'b0}; // CMOVGT
      //{6'h11 , 7'h6C} : // IMPLVER
      
      {6'h12 , 7'h02} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // MSKBL
      {6'h12 , 7'h06} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h8, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // EXTBL
      {6'h12 , 7'h0B} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h10, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // INSBL
      {6'h12 , 7'h12} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h2, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // MSKWL
      {6'h12 , 7'h16} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'ha, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // EXTWL
      {6'h12 , 7'h1B} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h12, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // INSWL
      {6'h12 , 7'h22} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h4, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // MSKLL
      {6'h12 , 7'h26} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'hc, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // EXTLL
      {6'h12 , 7'h2B} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h14, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // INSLL
      {6'h12 , 7'h30} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h4, 2'h1, 1'b0}; // ZAP
      {6'h12 , 7'h31} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h4, 2'h2, 1'b0}; // ZAPNOT
      {6'h12 , 7'h32} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h6, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // MSKQL
      {6'h12 , 7'h34} : out = {6'h0, 2'h2, 4'h0, 3'h0, 5'h0, 3'h0, 1'b1, 1'b0, 3'h0, 2'h0, 1'b0}; // SRL
      {6'h12 , 7'h36} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'he, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // EXTQL
      {6'h12 , 7'h39} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b1, 1'b0, 3'h0, 2'h0, 1'b0}; // SLL
      {6'h12 , 7'h3B} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h16, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // INSQL
      {6'h12 , 7'h3C} : out = {6'h0, 2'h3, 4'h0, 3'h0, 5'h0, 3'h0, 1'b1, 1'b0, 3'h0, 2'h0, 1'b0}; // SRA
      {6'h12 , 7'h52} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h3, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // MSKWH
      {6'h12 , 7'h57} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h13, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // INSWH
      {6'h12 , 7'h5A} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'hb, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // EXTWH
      {6'h12 , 7'h62} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h5, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // MSKLH
      {6'h12 , 7'h67} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h15, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // INSLH
      {6'h12 , 7'h6A} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'hd, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // EXTLH
      {6'h12 , 7'h72} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h7, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // MSKQH
      {6'h12 , 7'h77} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h17, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // INSQH
      {6'h12 , 7'h7A} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'hf, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0, 1'b0}; // EXTQH
      
      {6'h13 , 7'h00} : out = {6'h0, 2'h0, 4'h8, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0, 1'b0}; // MULL
      {6'h13 , 7'h20} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // MULQ
      {6'h13 , 7'h30} : out = {6'h0, 2'h0, 4'h9, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // UMULH
      {6'h13 , 7'h40} : out = {6'h0, 2'h0, 4'h8, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0, 1'b1}; // MULL/V
      {6'h13 , 7'h60} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b1}; // MULQ/V
      
      {6'h1C , 7'h00} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h6, 2'h0, 1'b0}; // SEXTB
      {6'h1C , 7'h01} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h7, 2'h0, 1'b0}; // SEXTW
      
      {6'h1C , 7'h30} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // CTPOP
      {6'h1C , 7'h31} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // PERR
      {6'h1C , 7'h32} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // CTLZ
      {6'h1C , 7'h33} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // CTTZ
      {6'h1C , 7'h34} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // UNPKBW
      {6'h1C , 7'h35} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // UNPKBL
      {6'h1C , 7'h36} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // PKWB
      {6'h1C , 7'h37} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // PKLB
      {6'h1C , 7'h38} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // MINSB8
      {6'h1C , 7'h39} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // MINSW4
      {6'h1C , 7'h3A} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // MINSUB8
      {6'h1C , 7'h3B} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // MINSUW4
      {6'h1C , 7'h3C} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // MAXUB8
      {6'h1C , 7'h3D} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // MAXUW4
      {6'h1C , 7'h3E} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // MAXSB8
      {6'h1C , 7'h3F} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // MAXSW4
      
      default : out = 0;
      /*
      {6'h1A , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // JMP
      {6'h1A , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // JSR
      {6'h1A , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // RET
      {6'h1A , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // JSR_COROUTINE
      
      {6'h30 , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // BR
      {6'h34 , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // BSR
      {6'h38 , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // BLBC
      {6'h39 , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // BEQ
      {6'h3A , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // BLT
      {6'h3B , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // BLE
      {6'h3C , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // BLBS
      {6'h3D , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // BNE
      {6'h3E , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // BGE
      {6'h3F , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // BGT
      
      //{6'h19 , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // PAL19
      //{6'h1B , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // PAL1B
      //{6'h1D , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // PAL1D
      //{6'h1E , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // PAL1E
      //{6'h1F , 7'b?} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0, 1'b0}; // PAL1F*/
      
    endcase
  end
endmodule
