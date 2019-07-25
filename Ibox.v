/* verilator lint_off DECLFILENAME */
module Ibox #(parameter LITTLE_ENDIAN = 1) (output [63:0] result, input[63:0] a, b, input[12:0] opcode, output [5:0] bloc, output [63:0] mei_out1, output [7:0] mei_out2);

  wire [63:0] shifter_out, alu_out, mux1_out, sext_out, cmp_out, zap_out, mux1_in[0:1], mux2_in[0:7];
  wire [7:0] mux3_out, mux3_in[0:3];
  wire [5:0] mux0_out, n_shift_ctrl, mux0_in[0:1];
  wire [3:0] alu_ctrl;
  wire [4:0] mei_ctrl;
  wire [2:0] cmp_ctrl, mux2_ctrl, xor_ctrl;
  wire [1:0] shifter_ctrl, mux3_ctrl;
  wire mux0_ctrl, mux1_ctrl;
  
  Shifter shifter(
      .out (shifter_out),
      .in (a),
      .n (mux0_out),
      .right (shifter_ctrl[1]),
      .arithmetic (shifter_ctrl[0])
      );

  ALU alu(
      .c (alu_out),
      .a (shifter_out),
      .b (mux1_out),
      .op (alu_ctrl)
      );
    
  SignExtender sext(
      .out (sext_out),
      .in (alu_out[31:0])
      );
      
  Comparator comparator(
      .out (cmp_out),
      .diff (alu_out),
      .sa (a[63]),
      .sb (b[63]),
      .op (cmp_ctrl)
      );
      
  MSK_EXT_INS msk_ext_ins(
      .out1 (mei_out1),
      .out2 (mei_out2),
      .ra (a),
      .rb (b[2:0]),
      .inst (mei_ctrl[4:3]),
      .size (mei_ctrl[2:1]),
      .high (mei_ctrl[0]),
      .byteloc (bloc)
      );
      
  ByteZAP bytezap(
      .out (zap_out),
      .in (mei_out1),
      .mask (mux3_out)
      );

  assign mux0_in[0] = n_shift_ctrl;
  assign mux0_in[1] = b[5:0];
  Mux #(.BITS(6), .WORDS(2)) mux0(
      .out (mux0_out),
      .sel (mux0_ctrl),
      .in (mux0_in)
      );
  
  assign mux1_in[0] = b;
  assign mux1_in[1] = ~b;
  Mux #(.BITS(64), .WORDS(2)) mux1(
      .out (mux1_out),
      .sel (mux1_ctrl),
      .in (mux1_in)
      );
  
  assign mux2_in[0] = alu_out;
  assign mux2_in[1] = sext_out;
  assign mux2_in[2] = cmp_out;
  assign mux2_in[3] = (alu_out & (~64'b111));
  assign mux2_in[4] = zap_out;
  assign mux2_in[5] = LITTLE_ENDIAN ? 0 : ({61'b0, xor_ctrl} ^ alu_out);
  assign mux2_in[6] = 0;
  assign mux2_in[7] = 0;
  Mux #(.BITS(64), .WORDS(8)) mux2(
      .out (result),
      .sel (mux2_ctrl),
      .in (mux2_in)
      );

  assign mux3_in[0] = mei_out2;
  assign mux3_in[1] = b[7:0];
  assign mux3_in[2] = ~b[7:0];
  assign mux3_in[3] = 0;
  Mux #(.BITS(8), .WORDS(4)) mux3(
      .out (mux3_out),
      .sel (mux3_ctrl),
      .in (mux3_in)
      );
      
  Controller cu(
      .in (opcode),
      .out ({n_shift_ctrl, shifter_ctrl, alu_ctrl, cmp_ctrl, mei_ctrl, xor_ctrl, mux0_ctrl, mux1_ctrl, mux2_ctrl, mux3_ctrl})
      );
      
endmodule

module ALU (output reg[63:0] c, input[63:0] a, b, input[3:0] op);
  integer i;
  reg[7:0] temp;
  always @* begin
    case (op)
      0 : c = a;
      1 : c = a + b;
      2 : c = a - b;
      3 : c = a & b;
      4 : c = a | b;
      5 : c = a ^ b;
      6 : begin // CMPBGE
        for (i = 0; i < 8; i = i + 1) begin
          temp[i] = a[i * 8 +: 8] >= b[i * 8 +: 8];
        end
        c = {56'b0, temp[7:0]};
      end
      7 : c = $signed(a) * $signed(b);
      8 : c = $signed(a[31:0]) * $signed(b[31:0]);
      9 : c = (a * b) >> 64;
    endcase
  end
endmodule

module Shifter (output [63:0] out, input [63:0] in, input[5:0] n, input right, input arithmetic);
  assign out = right ? (arithmetic ? in >>> n : in >> n) : in << n;
endmodule

module Comparator (output reg[63:0] out, input [63:0] diff, input sa, input sb, input[2:0] op);
  reg l, e, ul;
  always @* begin
    l = diff[63];
    e = ~(|diff);
    ul = (~(sa ^ sb) & l) || (~sa & sb);
    out[63:1] = 0;
    case (op)
      0: out[0] = l; // <
      1: out[0] = ~l & ~e; // >
      2: out[0] = e; // ==
      3: out[0] = e | l; // <=
      4: out[0] = e | ~l; // >=
      5: out[0] = ul; // U <
      6: out[0] = e | ul; // U <=
      7: out[0] = ~e; // !=
    endcase
  end
  
endmodule

module SignExtender (output [63:0] out, input [31:0] in);
    assign out[31:0] = in[31:0];
    assign out[63:32] = {32{in[31]}};
endmodule

module Mux #(parameter BITS=64, WORDS=2) (output [BITS-1:0] out,
                                          input[$clog2(WORDS)-1:0] sel,
                                          input[BITS-1:0] in [0:WORDS-1]);
  assign out = in[sel];
endmodule

module MSK_EXT_INS #(parameter LITTLE_ENDIAN = 1) (output reg[63:0] out1, output reg[7:0] out2,
                    input[63:0] ra, input[2:0] rb, input[1:0] size, input[1:0] inst, input high, output reg[5:0] byteloc);
    
  //reg[5:0] byteloc;
  reg[2:0] rbp;
  reg[15:0] mask;
  always @* begin
    case (size)
      0: mask = 16'b1;
      1: mask = 16'b11;
      2: mask = 16'b1111;
      3: mask = 16'b11111111;
    endcase
    rbp = LITTLE_ENDIAN ? rb : ~rb;
    byteloc = {rbp, 3'b0};
    if (high) begin byteloc = 6'h40 - byteloc; end
    // inst: MSK = 0, EXT = 1, INS = 2
    if (inst == 0 || inst == 2) begin mask = mask << rbp; end
    
    if (inst == 0) begin
      out1 = ra;
      out2 = high ? mask[15:8] : mask[7:0];
    end
    else begin
      if ((inst == 1 && high) || (inst == 2 && !high)) begin out1 = ra << byteloc; end
      else begin out1 = ra >> byteloc; end
      if (inst == 1 || !high) begin out2 = ~mask[7:0]; end
      else begin out2 = ~mask[15:8]; end
    end
    
  end
endmodule

module ByteZAP (output reg[63:0] out, input[63:0] in, input[7:0] mask);
  integer i;
  always @* begin
    for (i = 0; i < 8; i = i + 1) begin
      out[i * 8 +: 8] = mask[i] ? 0 : in[i * 8 +: 8];
    end
  end
endmodule

module Controller #(parameter LITTLE_ENDIAN = 1) (output reg[29:0] out, input [12:0] in);
  always @* begin
    casez (in)
    /* {opcode, func} <-> {n_shift_ctrl, shifter_ctrl, alu_ctrl, cmp_ctrl, mei_ctrl, xor_ctrl, mux0_ctrl,
                          mux1_ctrl, mux2_ctrl, mux3_ctrl} */
      {6'h08, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // LDA
      {6'h09, 7'h?}: out = {6'h10, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // LDAH
      {6'h0A, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h7, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0}; // LDBU
      {6'h0B, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h3, 2'h0}; // LDQ_U
      {6'h0C, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h6, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0}; // LDWU
      {6'h0D, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h6, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0}; // STW
      {6'h0E, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h7, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0}; // STB
      {6'h0F, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h3, 2'h0}; // STQ_U
      {6'h28, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h4, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0}; // LDL
      {6'h29, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0}; // LDQ
      {6'h2A, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h4, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0}; // LDL_L
      {6'h2B, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0}; // LDQ_L
      {6'h2C, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h4, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0}; // STL
      {6'h2D, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0}; // STQ
      {6'h2E, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h4, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0}; // STL_C
      {6'h2F, 7'h?}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, LITTLE_ENDIAN ? 3'h0 : 3'h5, 2'h0}; // STQ_C
      
      {6'h10 , 7'h00}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0}; // ADDL
      {6'h10 , 7'h02}: out = {6'h2, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0}; // S4ADDL
      {6'h10 , 7'h09}: out = {6'h0, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0}; // SUBL
      {6'h10 , 7'h0B}: out = {6'h2, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0}; // S4SUBL
      {6'h10 , 7'h0F}: out = {6'h0, 2'h0, 4'h6, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0};  // CMPBGE
      {6'h10 , 7'h12}: out = {6'h3, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0}; // S8ADDL
      {6'h10 , 7'h1B}: out = {6'h3, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0}; // S8SUBL
      {6'h10 , 7'h1D}: out = {6'h0, 2'h0, 4'h2, 3'h5, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0}; // CMPULT
      {6'h10 , 7'h20}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // ADDQ
      {6'h10 , 7'h22}: out = {6'h2, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // S4ADDQ
      {6'h10 , 7'h29}: out = {6'h0, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // SUBQ
      {6'h10 , 7'h2B}: out = {6'h2, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // S4SUBQ
      {6'h10 , 7'h2D}: out = {6'h0, 2'h0, 4'h2, 3'h2, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0}; // CMPEQ
      {6'h10 , 7'h32}: out = {6'h3, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // S8ADDQ
      {6'h10 , 7'h3B}: out = {6'h3, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // S8SUBQ
      {6'h10 , 7'h3D}: out = {6'h0, 2'h0, 4'h2, 3'h6, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0}; // CMPULE
      {6'h10 , 7'h40}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0}; // ADDL/V
      {6'h10 , 7'h49}: out = {6'h0, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0}; // SUBL/V
      {6'h10 , 7'h4D}: out = {6'h0, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0}; // CMPLT
      {6'h10 , 7'h60}: out = {6'h0, 2'h0, 4'h1, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // ADDQ/V
      {6'h10 , 7'h69}: out = {6'h0, 2'h0, 4'h2, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // SUBQ/V
      {6'h10 , 7'h6D}: out = {6'h0, 2'h0, 4'h2, 3'h3, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0}; // CMPLE
      
      {6'h11 , 7'h00} : out = {6'h0, 2'h0, 4'h3, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // AND
      {6'h11 , 7'h08} : out = {6'h0, 2'h0, 4'h3, 3'h0, 5'h0, 3'h0, 1'b0, 1'b1, 3'h0, 2'h0}; // BIC
      {6'h11 , 7'h14} : out = {6'h3f, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0}; // CMOVLBS
      {6'h11 , 7'h16} : out = {6'h3f, 2'h0, 4'h0, 3'h2, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0}; // CMOVLBC
      {6'h11 , 7'h20} : out = {6'h0, 2'h0, 4'h4, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // BIS
      {6'h11 , 7'h24} : out = {6'h0, 2'h0, 4'h0, 3'h3, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0}; // CMOVEQ
      {6'h11 , 7'h26} : out = {6'h0, 2'h0, 4'h0, 3'h7, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0}; // CMOVNE
      {6'h11 , 7'h28} : out = {6'h0, 2'h0, 4'h4, 3'h0, 5'h0, 3'h0, 1'b0, 1'b1, 3'h0, 2'h0}; // ORNOT
      {6'h11 , 7'h40} : out = {6'h0, 2'h0, 4'h5, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // XOR
      {6'h11 , 7'h44} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0}; // CMOVLT
      {6'h11 , 7'h46} : out = {6'h0, 2'h0, 4'h0, 3'h4, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0}; // CMOVGE
      {6'h11 , 7'h48} : out = {6'h0, 2'h0, 4'h5, 3'h0, 5'h0, 3'h0, 1'b0, 1'b1, 3'h0, 2'h0}; // EQV
      //{6'h11 , 7'h61} : // AMASK
      {6'h11 , 7'h64} : out = {6'h0, 2'h0, 4'h0, 3'h3, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0}; // CMOVLE
      {6'h11 , 7'h66} : out = {6'h0, 2'h0, 4'h0, 3'h1, 5'h0, 3'h0, 1'b0, 1'b0, 3'h2, 2'h0}; // CMOVGT
      //{6'h11 , 7'h6C} : // IMPLVER
      
      {6'h12 , 7'h02} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // MSKBL
      {6'h12 , 7'h06} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h8, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // EXTBL
      {6'h12 , 7'h0B} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h10, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // INSBL
      {6'h12 , 7'h12} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h2, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // MSKWL
      {6'h12 , 7'h16} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'ha, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // EXTWL
      {6'h12 , 7'h1B} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h12, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // INSWL
      {6'h12 , 7'h22} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h4, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // MSKLL
      {6'h12 , 7'h26} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'hc, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // EXTLL
      {6'h12 , 7'h2B} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h14, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // INSLL
      {6'h12 , 7'h30} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h4, 2'h1}; // ZAP
      {6'h12 , 7'h31} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h4, 2'h2}; // ZAPNOT
      {6'h12 , 7'h32} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h6, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // MSKQL
      {6'h12 , 7'h34} : out = {6'h0, 2'h2, 4'h0, 3'h0, 5'h0, 3'h0, 1'b1, 1'b0, 3'h0, 2'h0}; // SRL
      {6'h12 , 7'h36} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'he, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // EXTQL
      {6'h12 , 7'h39} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h0, 3'h0, 1'b1, 1'b0, 3'h0, 2'h0}; // SLL
      {6'h12 , 7'h3B} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h16, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // INSQL
      {6'h12 , 7'h3C} : out = {6'h0, 2'h3, 4'h0, 3'h0, 5'h0, 3'h0, 1'b1, 1'b0, 3'h0, 2'h0}; // SRA
      {6'h12 , 7'h52} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h3, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // MSKWH
      {6'h12 , 7'h57} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h13, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // INSWH
      {6'h12 , 7'h5A} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'hb, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // EXTWH
      {6'h12 , 7'h62} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h5, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // MSKLH
      {6'h12 , 7'h67} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h15, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // INSLH
      {6'h12 , 7'h6A} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'hd, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // EXTLH
      {6'h12 , 7'h72} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h7, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // MSKQH
      {6'h12 , 7'h77} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'h17, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // INSQH
      {6'h12 , 7'h7A} : out = {6'h0, 2'h0, 4'h0, 3'h0, 5'hf, 3'h0, 1'b0, 1'b0, 3'h4, 2'h0}; // EXTQH
      
      {6'h13 , 7'h00} : out = {6'h0, 2'h0, 4'h8, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0}; // MULL
      {6'h13 , 7'h20} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // MULQ
      {6'h13 , 7'h30} : out = {6'h0, 2'h0, 4'h9, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // UMULH
      {6'h13 , 7'h40} : out = {6'h0, 2'h0, 4'h8, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h1, 2'h0}; // MULL/V
      {6'h13 , 7'h60} : out = {6'h0, 2'h0, 4'h7, 3'h0, 5'h0, 3'h0, 1'b0, 1'b0, 3'h0, 2'h0}; // MULQ/V
    endcase
  end
endmodule
