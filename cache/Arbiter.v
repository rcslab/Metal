module Arbiter #(parameter Num_caches = 2, Address_bits = 64, Data_bits = 512)
              (output reg [Address_bits - 1:0] m_addr,
              output reg [Data_bits - 1:0] m_write_data,
              output reg m_read_en, m_write_en,
              output reg [Data_bits - 1:0] p_read_data [Num_caches],
              output reg p_grant [Num_caches],
              output reg p_stall [Num_caches],
              input [Data_bits - 1:0] m_read_data,
              input [Address_bits - 1:0] p_addr [Num_caches],
              input [Data_bits - 1:0] p_write_data [Num_caches],
              input p_read_en [Num_caches],
              input p_write_en [Num_caches],
              input rst, clk, m_stall);

  // Constants
  parameter GRANT = 0,
            WAIT = 1;

  reg [$clog2(Num_caches) - 1:0] serving, next;
  assign next = serving + 1;
  reg time_passed;
  reg state;

  integer i;
  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < Num_caches; i = i + 1) begin
        p_grant[i] <= 0;
        p_stall[i] <= 0;
      end
      serving <= 0;
      p_grant[serving] <= 1;
      state <= GRANT;
      time_passed <= 0;
    end else begin
      case (state)
        GRANT: begin
          p_grant[serving] <= 0;
          if (p_read_en[serving] || p_write_en[serving]) begin
            m_addr <= p_addr[serving];
            m_write_data <= p_write_data[serving];
            m_read_en <= p_read_en[serving];
            m_write_en <= p_write_en[serving];
            p_stall[serving] <= 1;
            state <= WAIT;
            time_passed <= 0;
          end else begin
            if (time_passed) begin
              serving <= next;
              p_grant[next] <= 1;
              time_passed <= 0;
            end else begin
              time_passed <= 1;
            end
          end
        end
        WAIT: begin
          if (time_passed && !m_stall) begin
            p_stall[serving] <= 0;
            p_read_data[serving] <= m_read_data;
            serving <= next;
            p_grant[next] <= 1;
            time_passed <= 0;
            state <= GRANT;
          end else begin
            time_passed <= 1;
            m_read_en <= 0;
            m_write_en <= 0;
          end
        end
      endcase
    end
  end
endmodule
