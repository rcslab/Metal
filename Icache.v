/* verilator lint_off WIDTH */
module Icache(output[31:0] data, output stall, input[63:0] addr, input read_en);
  reg[31:0] temp[0:255];
  reg[7:0] iMem[0:1023];
  integer i;
  assign stall = 0;
  initial begin 
    $readmemh("iMem.list", temp);
    for (i = 0; i < 1024; i = i + 4)
      {iMem[i], iMem[i+1], iMem[i+2], iMem[i+3]} = temp[i/4];
  end
  assign data = {iMem[addr], iMem[addr+1], iMem[addr+2], iMem[addr+3]};
endmodule
/* verilator lint_on WIDTH */

