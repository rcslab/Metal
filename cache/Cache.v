// Only Associativity = 8 supported
module Cache #(parameter Associativity = 8, Number_of_sets = 64, Block_size = 8, Word_size = 8, Address_bits = 64, Write_through = 0, Return_bits = 64, Return_block = 0, Read_delay = 0, Write_delay = 0, is_topmost = 1, is_lowest_invalidator = 0)
              (output reg [Return_bits - 1:0] p_read_data,
              output reg [Address_bits - 1:0] m_addr, // Last $clog2(Word_size * Block_size) bits = 0
              output reg [Block_size * Word_size * 8 - 1:0] m_write_data,
              output reg [Address_bits - 1:0] invalid_upper_addr,
              output reg stall, m_write_en, m_read_en, invalidate_upper,
              input [Address_bits - 1:0] p_addr, // Last $clog2(Word_size) bits ignore
              input [Return_bits - 1:0] p_write_data,
              input [Block_size * Word_size * 8 - 1:0] m_read_data,
              input p_write_en, p_read_en, rst, clk, m_stall, m_granted, p_conditional, invalidate,
              input [Address_bits - 1:0] invalid_addr);
  // Calculated Params
  parameter Word_bits = $clog2(Word_size);
  parameter Offset_bits = $clog2(Block_size);
  parameter Index_bits = $clog2(Number_of_sets);
  parameter Tag_size = Address_bits - Word_bits - Offset_bits - Index_bits;

  // Constants
  parameter IDLE = 0,
            CHECK = 1,
            WT_MEM_WRITE = 2,
            EVICT_MEM_WRITE = 3,
            MEM_FETCH = 4,
            HIT = 5;

  // Input registers
  reg [Address_bits - 1:0] p_reg_addr;
  reg [Return_bits - 1:0] p_reg_write_data;
  reg p_reg_write_en;
  reg p_reg_conditional;

  // Assign Multiplexed Outputs
  wire [Tag_size - 1:0] addr_tag;
  wire [Index_bits - 1:0] addr_index;
  wire [Offset_bits - 1:0] addr_offset;
  assign addr_tag = p_reg_addr[Address_bits - 1:Address_bits - Tag_size];
  assign addr_index = p_reg_addr[Address_bits - Tag_size - 1:Address_bits - Tag_size - Index_bits];
  assign addr_offset = p_reg_addr[Address_bits - Tag_size - Index_bits - 1:Address_bits - Tag_size - Index_bits - Offset_bits];

  // Cache Data
  reg valid [0:Number_of_sets - 1][0:Associativity - 1];
  reg dirty [0:Number_of_sets - 1][0:Associativity - 1];
  reg [Tag_size - 1:0] tag [0:Number_of_sets - 1][0:Associativity - 1];
  reg [Block_size * Word_size * 8 - 1:0] block [0:Number_of_sets - 1][0:Associativity - 1];
  reg [Associativity - 2:0] lru_bits [0:Number_of_sets - 1];

  // For invalidate
  wire [Tag_size - 1:0] invalid_tag;
  wire [Index_bits - 1:0] invalid_index;
  assign invalid_tag = invalid_addr[Address_bits - 1:Address_bits - Tag_size];
  assign invalid_index = invalid_addr[Address_bits - Tag_size - 1:Address_bits - Tag_size - Index_bits];
  wire [Tag_size - 1:0] invalid_set_tags [0:Associativity - 1];
  wire invalid_set_valids [0:Associativity - 1];
  assign invalid_set_tags = tag[invalid_index];
  assign invalid_set_valids = valid[invalid_index];
  wire invalid_hit;
  wire [$clog2(Associativity) - 1:0] invalid_which_block;
  TagFinder #(Associativity, Tag_size) invalid_tf (invalid_set_tags, invalid_set_valids, invalid_tag, invalid_hit, invalid_which_block);

  // Find tag in set
  wire [Tag_size - 1:0] active_set_tags [0:Associativity - 1];
  wire active_set_valids [0:Associativity - 1];
  assign active_set_tags = tag[addr_index];
  assign active_set_valids = valid[addr_index];
  wire hit;
  wire [$clog2(Associativity) - 1:0] which_block;
  TagFinder #(Associativity, Tag_size) tf (active_set_tags, active_set_valids, addr_tag, hit, which_block);

  // Find LRU
  wire [$clog2(Associativity) - 1:0] lru_index;
  wire [Associativity - 2:0] next_lru_bits;
  generate
    if (Associativity == 8) begin
      PLRU8 p8 (lru_bits[addr_index], which_block, lru_index, next_lru_bits);
    end
  endgenerate

  // Assign read block
  wire [Block_size * Word_size * 8 - 1:0] read_block;
  assign read_block = hit ? block[addr_index][which_block] : 0;

  // Alignment Zeros
  wire [Offset_bits + Word_bits - 1:0] zero_bits;
  assign zero_bits = 0;

  reg [3:0] state;
  reg m_active;
  integer time_passed;

  // Invalidate conditions
  wire exist_invalid, invalid_interrupt, self_write_invalid;
  assign exist_invalid = invalidate && invalid_hit;
  assign self_write_invalid = exist_invalid && invalid_tag == addr_tag && invalid_index == addr_index && m_active && is_lowest_invalidator;
  assign invalid_interrupt = exist_invalid && invalid_tag == addr_tag && invalid_index == addr_index && state != IDLE && !self_write_invalid;

  integer i, j;
  always @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
      stall <= 0;
      m_read_en <= 0;
      m_write_en <= 0;
      m_active <= 0;
      time_passed <= 0;
      invalidate_upper <= 0;
      /* verilator lint_off BLKLOOPINIT */
      for (i = 0; i < Number_of_sets; i = i + 1) begin
        for (j = 0; j < Associativity; j = j + 1) begin
          valid[i][j] <= 0;
        end
        lru_bits[i] <= 0;
      end
      /* verilator lint_on BLKLOOPINIT */
    end else begin
      // Snoop Module
      if (exist_invalid && !self_write_invalid) begin
        valid[invalid_index][invalid_which_block] <= 0;
      end
      if (!self_write_invalid) begin
        invalidate_upper <= invalidate;
        invalid_upper_addr <= invalid_addr;
      end else begin
        invalidate_upper <= 0;
      end

      // FSM
      if (invalid_interrupt) begin
        m_active <= 0;
        m_read_en <= 0;
        m_write_en <= 0;
        if (is_topmost) begin
          state <= CHECK; // L1 should retry
        end else begin
          state <= IDLE; // Other layers should abort
          stall <= 0;
        end
      end else begin
        case (state)
          IDLE: begin
            if (p_read_en || p_write_en) begin
              p_reg_addr <= p_addr;
              p_reg_write_data <= p_write_data;
              p_reg_write_en <= p_write_en;
              p_reg_conditional <= p_conditional;
              stall <= 1;
              state <= CHECK;
            end
          end
          CHECK: begin
            if (hit) begin
              p_read_data <= 1; // For conditional
              time_passed <= 0;
              state <= HIT;
            end else begin
              if (p_reg_conditional) begin
                p_read_data <= 0;
                stall <= 0;
                state <= IDLE;
              end else begin
                if (Write_through == 0 && valid[addr_index][lru_index] && dirty[addr_index][lru_index]) begin
                  state <= EVICT_MEM_WRITE;
                end else begin
                  state <= MEM_FETCH;
                end
              end
            end
          end
          EVICT_MEM_WRITE: begin
            if (!m_active) begin
              if (m_granted) begin
                m_addr <= {tag[addr_index][lru_index], addr_index, zero_bits};
                m_write_data <= block[addr_index][lru_index];
                m_write_en <= 1;
                time_passed <= 0;
                m_active <= 1;
              end
            end else begin
              if (time_passed != 0 && !m_stall) begin
                m_addr <= {addr_tag, addr_index, zero_bits};
                m_read_en <= 1;
                time_passed <= 0;
                m_active <= 0;
                state <= MEM_FETCH;
              end else begin
                m_write_en <= 0;
                time_passed <= time_passed + 1;
              end
            end
          end
          WT_MEM_WRITE: begin
            if (!m_active) begin
              if (m_granted) begin
                m_addr <= {addr_tag, addr_index, zero_bits};
                m_write_data <= block[addr_index][which_block];
                m_write_en <= 1;
                m_active <= 1;
              end
            end else begin
              if (time_passed != 0 && !m_stall) begin
                m_active <= 0;
                state <= IDLE;
                stall <= 0;
              end else begin
                m_write_en <= 0;
                time_passed <= time_passed + 1;
              end
            end
          end
          MEM_FETCH: begin
            if (!m_active) begin
              if (m_granted) begin
                m_addr <= {addr_tag, addr_index, zero_bits};
                m_read_en <= 1;
                time_passed <= 0;
                m_active <= 1;
              end
            end else begin
              if (time_passed != 0 && !m_stall) begin
                valid[addr_index][lru_index] <= 1;
                dirty[addr_index][lru_index] <= 0;
                tag[addr_index][lru_index] <= addr_tag;
                block[addr_index][lru_index] <= m_read_data;
                time_passed <= 0;
                m_active <= 0;
                state <= HIT;
              end else begin
                m_read_en <= 0;
                time_passed <= time_passed + 1;
              end
            end
          end
          HIT: begin
            if ((p_reg_write_en && time_passed >= Write_delay) || (!p_reg_write_en && time_passed >= Read_delay)) begin
              lru_bits[addr_index] <= next_lru_bits;
              if (!p_reg_conditional) begin
                if (Return_block == 1) begin
                  p_read_data <= read_block;
                end else begin
                  p_read_data <= read_block[(Block_size - addr_offset) * Word_size * 8 - 1 -: Word_size * 8];
                end
              end
              if (p_reg_write_en) begin
                block[addr_index][which_block][(Block_size - addr_offset) * Word_size * 8 - 1 -: Return_bits] <= p_reg_write_data;
                if (Write_through == 1) begin
                  state <= WT_MEM_WRITE;
                end else begin
                  dirty[addr_index][which_block] <= 1;
                  state <= IDLE;
                  stall <= 0;
                end
              end else begin
                state <= IDLE;
                stall <= 0;
              end
            end else begin
              time_passed <= time_passed + 1;
            end
          end
        endcase
      end
    end
  end
endmodule

module TagFinder #(parameter Associativity = 8, Tag_size = 52)
                  (input [Tag_size - 1:0] active_set_tags[0:Associativity - 1],
                   input active_set_valids[0:Associativity - 1],
                   input [Tag_size - 1:0] addr_tag,
                   output reg hit,
                   output reg [$clog2(Associativity) - 1:0] index);
  reg [Associativity - 1:0] hits;
  assign hit = |hits;
  integer i;
  always @ (*) begin
    for (i = 0; i < Associativity; i = i + 1) begin
      hits[i] = (active_set_valids[i] && addr_tag == active_set_tags[i]);
      if (hits[i]) begin
        index = i;
      end
    end
  end
endmodule

module PLRU8(input [6:0] lru_bits,
                   input [2:0] access_index,
                   output reg [2:0] lru_index,
                   output reg [6:0] next_lru_bits);
  always @ (*) begin
    if ((lru_bits & 7'b1101000) == 7'b0000000) lru_index = 0;
    else if ((lru_bits & 7'b1101000) == 7'b0001000) lru_index = 1;
    else if ((lru_bits & 7'b1100100) == 7'b0100000) lru_index = 2;
    else if ((lru_bits & 7'b1100100) == 7'b0100100) lru_index = 3;
    else if ((lru_bits & 7'b1010010) == 7'b1000000) lru_index = 4;
    else if ((lru_bits & 7'b1010010) == 7'b1000010) lru_index = 5;
    else if ((lru_bits & 7'b1010001) == 7'b1010000) lru_index = 6;
    else if ((lru_bits & 7'b1010001) == 7'b1010001) lru_index = 7;
  end

  always @ (*) begin
    if (access_index == 0) next_lru_bits = (lru_bits & 7'b1111111) | 7'b1101000;
    else if (access_index == 1) next_lru_bits = (lru_bits & 7'b1110111) | 7'b1100000;
    else if (access_index == 2) next_lru_bits = (lru_bits & 7'b1011111) | 7'b1000100;
    else if (access_index == 3) next_lru_bits = (lru_bits & 7'b1011011) | 7'b1000000;
    else if (access_index == 4) next_lru_bits = (lru_bits & 7'b0111111) | 7'b0010010;
    else if (access_index == 5) next_lru_bits = (lru_bits & 7'b0111101) | 7'b0010000;
    else if (access_index == 6) next_lru_bits = (lru_bits & 7'b0101111) | 7'b0000001;
    else if (access_index == 7) next_lru_bits = (lru_bits & 7'b0101110) | 7'b0000000;
  end
endmodule
