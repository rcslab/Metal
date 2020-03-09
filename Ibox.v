/* verilator lint_off DECLFILENAME */

`include "Basics.v"

module Ibox #(parameter LITTLE_ENDIAN = 1) (output [63:0] result,
                                            output ibox_flag,
                                            input[63:0] a, b,
                                            input[31:0] control);

  wire [63:0] shifter_out, alu_out, mux1_out, cmp_out, zap_out, mei_out1, mux1_in[0:1], mux2_in[0:7];
  wire [7:0] mei_out2, mux3_out, mux3_in[0:3];
  wire [5:0] mux0_out, n_shift_ctrl, mux0_in[0:1];
  wire [4:0] alu_ctrl;
  wire [4:0] mei_ctrl;
  wire [2:0] cmp_ctrl, mux2_ctrl, xor_ctrl;
  wire [1:0] shifter_ctrl, mux3_ctrl;
  wire mux0_ctrl, mux1_ctrl, v;
  reg ovf;
  
  assign {n_shift_ctrl, shifter_ctrl, alu_ctrl, cmp_ctrl, mei_ctrl, xor_ctrl, mux0_ctrl, mux1_ctrl, mux2_ctrl, mux3_ctrl, v} = control;
  
  assign ibox_flag = v & ovf;
  
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
      .op (alu_ctrl),
      .ovf (ovf)
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
      .high (mei_ctrl[0])
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
  assign mux2_in[1] = {{32{alu_out[31]}}, alu_out[31:0]};
  assign mux2_in[2] = cmp_out;
  assign mux2_in[3] = (alu_out & (~64'b111));
  assign mux2_in[4] = zap_out;
  assign mux2_in[5] = LITTLE_ENDIAN ? 0 : ({61'b0, xor_ctrl} ^ alu_out);
  assign mux2_in[6] = {{56{alu_out[7]}}, alu_out[7:0]};
  assign mux2_in[7] = {{48{alu_out[15]}}, alu_out[15:0]};
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
      
endmodule

module ALU (output reg[63:0] c, input[63:0] a, b, input[4:0] op, output reg ovf);
  integer i;
  reg [127:0] temp;
  always @* begin
    ovf = 0;
    temp = 0;

    case (op)
      0 : c = a;
      1 : begin c = a + b; ovf = (a[63] & b[63] & ~c[63]) | (~a[63] & ~b[63] & c[63]); end
      2 : begin c = a - b; ovf = (a[63] & ~b[63] & ~c[63]) | (~a[63] & b[63] & c[63]); end
      3 : c = a & b;
      4 : c = a | b;
      5 : c = a ^ b;
      6 : begin // CMPBGE
        c = 0;
        for (i = 0; i < 8; i = i + 1) begin
          c[i] = a[i * 8 +: 8] >= b[i * 8 +: 8];
        end
      end
      7 : begin
        temp = $signed(a) * $signed(b);
        ovf = ~(& temp[127:63]) & (| temp[127:63]); 
        c = temp[63:0];
      end
      8 : begin
        temp = $signed(a[31:0]) * $signed(b[31:0]); 
        ovf = ~(& temp[63:31]) & (| temp[63:31]); 
        c = {{32{temp[31]}}, temp[31:0]};
      end
      9 : begin temp = (a * b); c = temp[127:64]; end
      10: begin // CTPOP
        c = 0;
        for (i = 0; i < 64; i = i + 1) begin
          if (b[i]) c = c + 1;
        end
      end
      11: begin // CTLZ
        c = 0;
        for (i = 63; i >= 0; i = i - 1) begin
          if (b[i])
            break;
          c = c + 1;
        end
      end
      12: begin // CTTZ
        c = 0;
        for (i = 0; i < 64; i = i + 1) begin
          if (b[i])
            break;
          c = c + 1;
        end
      end
      13: begin // PERR
        c = 0;
        for (i = 0; i < 8; i = i + 1) begin
          temp[7:0] = a[i * 8 +: 8] - b[i * 8 +: 8]; //overflow?
          if (temp[7])
            c = c - {{56{temp[7]}}, temp[7:0]};
          else
            c = c + {{56{temp[7]}}, temp[7:0]};
        end
      end
      14: begin // PKLB
        c[7:0] = b[7:0];
        c[15:8] = b[39:32];
        c[63:16] = 0;
      end
      15: begin // PKWB
        c[7:0] = b[7:0];
        c[15:8] = b[23:16];
        c[23:16] = b[39:32];
        c[31:24] = b[55:48];
        c[63:32] = 0;
      end
      16: begin // UNPKBL
        c = 0;
        c[7:0] = b[7:0];
        c[39:32] = b[15:8];
      end
      17: begin // UNPKBW
        c = 0;
        c[7:0] = b[7:0];
        c[23:16] = b[15:8];
        c[39:32] = b[23:16];
        c[55:48] = b[31:24];
      end
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

module MSK_EXT_INS #(parameter LITTLE_ENDIAN = 1) (output reg[63:0] out1, output reg[7:0] out2,
                    input[63:0] ra, input[2:0] rb, input[1:0] size, input[1:0] inst, input high);
    
  reg[5:0] byteloc;
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
