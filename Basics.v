/* verilator lint_off DECLFILENAME */
`ifndef _basics_vh_
`define _basics_vh_

module Mux #(parameter BITS=64, WORDS=2) (output [BITS-1:0] out,
                                          input[$clog2(WORDS)-1:0] sel,
                                          input[BITS-1:0] in [0:WORDS-1]);
  assign out = in[sel];
endmodule

/*module SignExtender #(parameter Input_size = 32, Output_size = 64)
                    (output [Output_size-1:0] out, input [Input_size-1:0] in);
  assign out[Input_size-1:0] = in[Input_size-1:0];
  assign out[Output_size-1:Input_size] = {(Output_size-Input_size){in[Input_size-1]}};
endmodule*/
 
`endif
