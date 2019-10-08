module Cache #(parameter Associativity = 8, Number_of_sets = 64, Block_size = 64)
              (output reg [63:0] p_read_data, m_addr,
              output reg [511:0] m_write_data,
              output reg hit, miss,
              input [63:0] p_addr, p_write_data,
              input [511:0] m_read_data,
              input p_read_en, p_write_en, rst, clk)
              
  parameter Index_size = $clog2(Number_of_sets);
  parameter Offset_size = $clog2(Block_size);
  parameter Tag_size = 64 - Index_size - Offset_size;
  
  reg valid [0:Number_of_sets][0:Associativity];
  reg dirty [0:Number_of_sets][0:Associativity];
  reg [Tag_size - 1:0] tag [0:Number_of_sets][0:Associativity];
  reg [Block_size * 8 - 1:0] block [0:Number_of_sets][0:Associativity];
  
  wire [Index_size - 1:0] addr_index;
  wire [Tag_size - 1:0] addr_tag;
  wire [Offset_size + 2:0] offset;
  integer i;
  
  task insert (input [63:0] addr, input [511:0] data);
  
  endtask
  
  always @(posedge clk) begin
    hit = 0;
    miss = 0;
    addr_index = p_addr[$clog2(Block_size) +: $clog2(Number_of_sets)];
    addr_tag = p_addr[63:$clog2(Block_size) + $clog2(Number_of_sets)];
    offset = {p_addr[Offset_size - 1:3], 6'b0};

    if (p_write_en) begin
      insert(p_addr, {448'b0, p_write_data});
    end
    if (p_read_en or p_write_en) begin
      for (i = 0; i < Associativity; i = i + 1) begin
        if (tag[addr_index][i] == addr_tag && valid[addr_index][i] == 1) begin
          if (p_read_en) begin
            p_read_data = block[addr_index][i][offset +: 64];
          end else if (p_write_en) begin
            dirty[addr_index][i] = 1;
            block[addr_index][i][offset +: 64] = p_write_data;
          end
          hit = 1;
          miss = 0;
          break;
        end
      end
      if (hit == 0) begin
        miss = 1;
        m_addr = p_addr;
        m_write_en = 0;
        @(posedge clk)
        insert (m_addr, m_read_data);
        p_read_data = m_read_data[offset +: 64];
        miss = 0;
      end
    end
  end
endmodule
