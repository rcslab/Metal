/* verilator lint_off WIDTH */
/* verilator lint_off UNUSED */
module Icache #(parameter Metal = 0) (output[31:0] data, output stall, input[63:0] addr, input read_en);
  reg[7:0] iMem[0:2048];
  wire[63:0] a;
  integer i;
  assign stall = 0;
  initial begin
    if (Metal)
      $readmemh("metal.mem", iMem);
    else 
      $readmemh("instruction.mem", iMem);
  end
  assign a = Metal ? (addr & 64'h0ffff) : addr;
  assign data = {iMem[a], iMem[a+1], iMem[a+2], iMem[a+3]};
endmodule
/* verilator lint_on UNUSED */
/* verilator lint_on WIDTH */

