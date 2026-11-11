module axis_async_fifo #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 4
)(
  // slave side (data in), write clock domain
  input  logic                  s_clk,
  input  logic                  s_rst,
  input  logic [DATA_WIDTH-1:0] s_tdata,
  input  logic                  s_tlast,
  input  logic                  s_tvalid,
  output logic                  s_tready,

  // master side (data out), read clock domain
  input  logic                  m_clk,
  input  logic                  m_rst,
  output logic [DATA_WIDTH-1:0] m_tdata,
  output logic                  m_tlast,
  output logic                  m_tvalid,
  input  logic                  m_tready
);

  logic                wr_full, rd_empty;
  logic [DATA_WIDTH:0] wr_word, rd_word;   // {tlast, tdata}

  assign wr_word            = {s_tlast, s_tdata};
  assign s_tready           = !wr_full;
  assign m_tvalid           = !rd_empty;
  assign {m_tlast, m_tdata} = rd_word;

  async_FIFO #(
    .DATA_WIDTH (DATA_WIDTH + 1),
    .ADDR_WIDTH (ADDR_WIDTH)
  ) fifo (
    .wr_clk   (s_clk),
    .wr_rst   (s_rst),
    .wr_inc   (s_tvalid && s_tready),
    .wr_data  (wr_word),
    .wr_full  (wr_full),

    .rd_clk   (m_clk),
    .rd_rst   (m_rst),
    .rd_inc   (m_tvalid && m_tready),
    .rd_data  (rd_word),
    .rd_empty (rd_empty)
  );

endmodule
