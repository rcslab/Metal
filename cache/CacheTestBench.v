`include "Cache.v"
`include "Arbiter.v"
module CacheTestBench(output [63:0] l1c_read_data, l1d_read_data, output l1c_stall, l1d_stall, input [63:0] l1c_addr, l1d_addr, l1c_write_data, l1d_write_data, input l1c_write_en, l1d_write_en, l1c_read_en, l1d_read_en, clk, rst);
  wire [511:0] m_read_data, m_write_data;
  wire [63:0] m_addr;
  wire m_read_en, m_write_en, m_stall;

  wire [63:0] l2_arbiter_addr[2];
  wire [511:0] l2_arbiter_write_data[2];
  wire [511:0] l2_arbiter_read_data[2];
  wire l2_arbiter_read_en[2];
  wire l2_arbiter_write_en[2];
  wire l2_arbiter_stall[2];
  wire l2_arbiter_grant[2];

  wire [511:0] l2_read_data;
  wire [511:0] l2_write_data;
  wire [63:0] l2_addr;
  wire l2_read_en;
  wire l2_write_en;
  wire l2_stall;

  Cache #(8, 64, 8, 8, 64, 1, 64, 0, 0, 0) l1c(l1c_read_data, l2_arbiter_addr[0], l2_arbiter_write_data[0], l1c_stall, l2_arbiter_write_en[0], l2_arbiter_read_en[0], l1c_addr, l1c_write_data, l2_arbiter_read_data[0], l1c_write_en, l1c_read_en, rst, clk, l2_arbiter_stall[0], l2_arbiter_grant[0]);

  Cache #(8, 64, 8, 8, 64, 1, 64, 0, 0, 0) l1d(l1d_read_data, l2_arbiter_addr[1], l2_arbiter_write_data[1], l1d_stall, l2_arbiter_write_en[1], l2_arbiter_read_en[1], l1d_addr, l1d_write_data, l2_arbiter_read_data[1], l1d_write_en, l1d_read_en, rst, clk, l2_arbiter_stall[1], l2_arbiter_grant[1]);

  Arbiter #(2, 64, 512) l2_arbiter(l2_addr, l2_write_data, l2_read_en, l2_write_en, l2_arbiter_read_data, l2_arbiter_grant, l2_arbiter_stall, l2_read_data, l2_arbiter_addr, l2_arbiter_write_data, l2_arbiter_read_en, l2_arbiter_write_en, rst, clk, l2_stall);

  Cache #(8, 512, 8, 8, 64, 0, 512, 1, 0, 0) l2(l2_read_data, m_addr, m_write_data, l2_stall, m_write_en, m_read_en, l2_addr, l2_write_data, m_read_data, l2_write_en, l2_read_en, rst, clk, m_stall, 1);

  TestMemory tm(m_read_data, m_stall, m_addr, m_write_data, m_read_en, m_write_en, clk);
endmodule

module TestMemory(output [511:0] read_data, output reg stall, input[63:0] addr, input [511:0] write_data, input m_read_en, m_write_en, input clk);
  reg[511:0] Mem[0:65535];
  reg [63:0] addr_reg;
  reg [511:0] write_data_reg;
  reg write_en_reg;
  integer time_passed;

  initial begin
    $readmemh("test.mem", Mem);
    stall <= 0;
  end

  always @(posedge clk) begin
    if (!stall) begin // IDLE State
      if (m_read_en || m_write_en) begin
        stall <= 1;
        time_passed <= 0;
        addr_reg <= addr;
        write_data_reg <= write_data;
        write_en_reg <= m_write_en;
      end
    end else begin // Processing State
      if (time_passed >= 8) begin
        if (write_en_reg) Mem[addr_reg[63:6]] <= write_data_reg;
        stall <= 0;
      end else begin
        time_passed <= time_passed + 1;
      end
    end
  end

  assign read_data = Mem[addr_reg[63:6]];
endmodule
