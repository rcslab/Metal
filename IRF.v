/* verilator lint_off DECLFILENAME */

`include "Basics.v"

module IRF (output reg [63:0] out1, out2, reg_read_a4, reg_read_b5,
            output [63:0] reg_read_a, reg_read_b,
            input [4:0] read_addr_a, read_addr_b, write_addr,
            input [63:0] write_data, pc2,
            input [15:0] displacement,
            input [7:0] literal,
            input [1:0] mux1_sel,
            input mux2_sel, write_en, clk);
  
  wire [63:0] mux1_out, mux2_out;
  wire [63:0] mux1_in[3:0], mux2_in[1:0];
  reg [63:0] reg_read_a3, reg_read_b3, reg_read_b4;
  
  always @(posedge clk) begin
    out1 <= mux1_out;
    out2 <= mux2_out;
    reg_read_a3 <= reg_read_a;
    reg_read_a4 <= reg_read_a3;
    reg_read_b3 <= reg_read_b;
    reg_read_b4 <= reg_read_b3;
    reg_read_b5 <= reg_read_b4;
  end
  
  Register_file rf(
        .ra (reg_read_a),
        .rb (reg_read_b),
        .read_addr_a (read_addr_a),
        .read_addr_b (read_addr_b),
        .write_addr (write_addr),
        .write_data (write_data),
        .write_en (write_en),
        .clk (clk)
        );
        
  assign mux1_in[0] = reg_read_a;
  assign mux1_in[1] = {{48{displacement[15]}}, displacement[15:0]};
  assign mux1_in[2] = pc2;
  assign mux1_in[3] = 0;
  Mux #(.BITS(64), .WORDS(4)) mux1(
      .out (mux1_out),
      .sel (mux1_sel),
      .in (mux1_in)
      );

  assign mux2_in[0] = reg_read_b;
  assign mux2_in[1] = {{56{literal[7]}}, literal[7:0]};
  Mux #(.BITS(64), .WORDS(2)) mux2(
      .out (mux2_out),
      .sel (mux2_sel),
      .in (mux2_in)
      );
        
endmodule

module Register_file (output [63:0] ra, rb,
            input [4:0] read_addr_a, read_addr_b, write_addr,
            input [63:0] write_data,
            input write_en, clk);
  reg [63:0] register[31:0];
  initial register[31] = 0;
  always @(negedge clk) begin
    if (write_en && write_addr != 31)  register[write_addr] <= write_data;
  end
  assign ra = register[read_addr_a];
  assign rb = register[read_addr_b];
endmodule

