module Ibox (output [63:0] result, input[63:0] a, b, input[12:0] opcode);

  wire [63:0] shifter_out, alu_out, mux1_out, sext_out, cmp_out, mei_out1, zap_out;
  wire [15:0] mux3_out;
  wire [7:0] mei_out2, mux4_out;
  wire [5:0] mux0_out, n_shift_ctrl;
  wire [3:0] alu_ctrl;
  wire [2:0] cmp_ctrl, mei_ctrl, mux2_ctrl;
  wire [1:0] shifter_ctrl, mux3_ctrl;
  wire mux0_ctrl, mux1_ctrl, mux4_ctrl;
  
  Shifter shifter(
      .out (shifter_out),
      .in (a),
      .n (mux0_out),
      .right (shifter_ctrl[0]),
      .arithmetic (shifter_ctrl[1])
      );

  ALU alu(
      .c (alu_out),
      .a (shifter_out),
      .b (mux1_out),
      .op (alu_ctrl)
      );
    
  SignExtender sext(
      .out (sext_out)
      .in (alu_out[31:0])
      );
      
  CompareWithZero comparator(
      .out (cmp_out),
      .in (alu_out),
      .op (cmp_ctrl)
      );
      
  MSK_EXT_INS msk_ext_ins(
      .out1 (mei_out1),
      .out2 (mei_out2),
      .ra (a),
      .rb (b[2:0]),
      .mask (mux3_out),
      .inst (mei_ctrl[2:1]),
      .high (mei_ctrl[0])
      );
      
  ByteZAP bytezap(
      .out (zap_out),
      .in (mei_out1),
      .mask (mux4_out)
      );
      
  Mux #(.BITS(6), .WORDS(2)) mux0(
      .out (mux0_out),
      .sel (mux0_ctrl),
      .in ({b[5:0], n_shift_ctrl})
      );
  
  Mux #(.BITS(64), .WORDS(2)) mux1(
      .out (mux1_out),
      .sel (mux1_ctrl),
      .in ({b, ~b})
      );
  
  Mux #(.BITS(64), .WORDS(8)) mux2(
      .out (result),
      .sel (mux2_ctrl),
      .in ({alu_out, sext_out, cmp_out, (alu_out & 64'b1000), zap_out, 0, 0, 0})
      );
      
  Mux #(.BITS(16), .WORDS(4)) mux3(
      .out (mux3_out),
      .sel (mux3_ctrl),
      .in ({16'b01, 16'b011, 16'b01111, 16'b011111111})
      );

  Mux #(.BITS(8), .WORDS(2)) mux4(
      .out (mux4_out),
      .sel (mux4_ctrl),
      .in ({mei_out2, b[7:0]})
      );
      
  Controller cu(
      .in (opcode)
      .out ({n_shift_ctrl, shifter_ctrl, alu_ctrl, cmp_ctrl, mei_ctrl, mux0_ctrl, mux1_ctrl, mux2_ctrl, mux3_ctrl, mux4_ctrl})
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
        3 : c = a and b;
        4 : c = a or b;
        5 : c = a xor b;
        6 : begin  // CMPBGE
          for (i = 0; i < 8; i = i + 1) begin
            temp[i] = A[i * 8 + 7 : i * 8] >= B[i * 8 + 7 : i * 8];
          end
          c = {56'b0, temp[7:0]};
        end
        //7 : c = $signed(a[31:0]) * $signed(b[31:0]);
        7 : c = $signed(a) * $signed(b);
        8 : c = (a * b)[127:64];
      endcase
    end
endmodule

module Shifter (output reg[63:0] out, input [63:0] in, input[5:0] n, input right, input arithmetic);
  assign out = right ? (arithmetic ? in >>> n : in >> n) : in << n;
endmodule

module CompareWithZero (output reg[63:0] out, input [63:0] in, input[2:0] op);
  reg l, e;
  always @* begin
    l = in[63];
    e = ~(|in);
    case (op)
      0: out = l; // <
      1: out = ~l and ~e; // >
      2: out = e; // ==
      3: out = e or l; // <=
      4: out = e or ~l; // >=
    endcase
  end
  
endmodule

module SignExtender (output [63;0] out, input [31:0] in)
    assign out = {32{in[31]}, out[31:0]};
endmodule

module Mux #(parameter BITS=64, WORDS=2) (output [BITS-1:0] out,
                                          input[$clog2(WORDS)-1:0] sel,
                                          input[BITS-1:0] in [0:WORDS-1]);
  assign out = in[sel];
endmodule

module MSK_EXT_INS (output reg[63:0] out1, output reg[7:0] out2,
                    input[63:0] ra, input[2:0] rb, input reg[15:0] mask, input [1:0] inst, input high);
    
    reg[5:0] byteloc;
    reg[2:0] rbvp;
    always @* begin
      rbp = little_endian ? rb : ~rb
      byteloc = rbp << 3;
      if (high) byteloc = 64 - byteloc;
      // inst: MSK = 0, EXT = 1, INS = 2
      if (inst == 0 or inst == 2) mask = mask << rbp;
      
      if (inst == 0) out1 = ra;
      else if ((inst == 1 and high) or (inst == 2 and !high)) out1 = ra << byteloc;
      else out1 = ra >> byteloc;
      
      if (inst == 1 or !high) out2 = ~mask[7:0]
      else out2 = ~mask[15:8];
      
    end
endmodule

module ByteZAP (output reg[63:0] out, input[63:0] in, input[7:0] mask);
    integer i;
    always @* begin
      for (i = 0; i < 8; i = i + 1) begin
        out[i * 8 + 7:i * 8] = mask[i] ? 0 : in[i * 8 + 7:i * 8];
      end
    end
endfunction

module Controller (output [25:0] out, input [12:0] in);

endmodule
