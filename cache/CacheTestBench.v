`include "Cache.v"
module CacheTestBench(output [63:0] p_read_data, output stall, input [63:0] p_addr, p_write_data, input p_write_en, p_read_en, clk, rst);
  wire [511:0] m_read_data, m_write_data;
  wire [63:0] m_addr;
  wire m_read_en, m_write_en, m_stall;

  wire [511:0] l2_read_data, l2_write_data;
  wire [63:0] l2_addr;
  wire l2_read_en, l2_write_en, l2_stall;

  Cache #(8, 64, 8, 8, 64, 1, 64, 0) l1(p_read_data, l2_addr, l2_write_data, stall, l2_write_en, l2_read_en, p_addr, p_write_data, l2_read_data, p_write_en, p_read_en, rst, ~clk, l2_stall);
  Cache #(8, 512, 8, 8, 64, 0, 512, 1) l2(l2_read_data, m_addr, m_write_data, l2_stall, m_write_en, m_read_en, l2_addr, l2_write_data, m_read_data, l2_write_en, l2_read_en, rst, clk, m_stall);
  TestMemory tm(m_read_data, m_stall, m_addr, m_write_data, m_read_en, m_write_en, clk);
endmodule

module TestMemory(output [511:0] read_data, output reg stall, input[63:0] addr, input [511:0] write_data, input m_read_en, m_write_en, input clk);
  reg[511:0] Mem[0:65535];
  integer delay;

  initial begin
    $readmemh("test.mem", Mem);
    delay = 0;
  end

  always @(posedge m_read_en or posedge m_write_en) begin
    stall = 1;
    delay = 0;
  end

  always @(posedge clk) begin
    if (stall == 1) delay = delay + 1;
    if (delay == 8) stall = 0;
    if (m_write_en) Mem[addr[63:6]] <= write_data;
  end

  assign read_data = Mem[addr[63:6]];
endmodule
