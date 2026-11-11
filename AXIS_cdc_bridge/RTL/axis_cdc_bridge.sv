module axis_cdc_bridge #(
  parameter ADDR_WIDTH = 4
)(
  // ---- write clock domain: generator side ----
  input  logic        wr_clk,
  input  logic        wr_rst,
  input  logic        gen_clear,
  input  logic        gen_enable,
  input  logic [7:0]  gen_seed,
  input  logic [7:0]  gen_throttle,
  output logic [31:0] sent_count,

  // ---- read clock domain: checker side ----
  input  logic        rd_clk,
  input  logic        rd_rst,
  input  logic        chk_clear,
  input  logic        chk_enable,
  input  logic [7:0]  chk_seed,
  input  logic [7:0]  chk_throttle,
  output logic [31:0] word_count,
  output logic [31:0] err_count,
  output logic        error_seen
);

  // generator -> skid A
  logic [7:0] g_tdata;  logic g_tvalid, g_tready;
  // skid A -> FIFO
  logic [7:0] a_tdata;  logic a_tvalid, a_tready;
  // FIFO -> skid B
  logic [7:0] f_tdata;  logic f_tvalid, f_tready;
  // skid B -> checker
  logic [7:0] b_tdata;  logic b_tvalid, b_tready;

  lfsr_generator gen (
    .clk        (wr_clk),
    .rst        (wr_rst),
    .clear      (gen_clear),
    .enable     (gen_enable),
    .seed       (gen_seed),
    .throttle   (gen_throttle),
    .m_tdata    (g_tdata),
    .m_tvalid   (g_tvalid),
    .m_tready   (g_tready),
    .sent_count (sent_count)
  );

  skid_buffer #(.WIDTH(8)) skid_in (
    .clk      (wr_clk),
    .rst      (wr_rst),
    .s_tdata  (g_tdata),
    .s_tvalid (g_tvalid),
    .s_tready (g_tready),
    .m_tdata  (a_tdata),
    .m_tvalid (a_tvalid),
    .m_tready (a_tready)
  );

  axis_async_fifo #(.DATA_WIDTH(8), .ADDR_WIDTH(ADDR_WIDTH)) fifo (
    .s_clk    (wr_clk),
    .s_rst    (wr_rst),
    .s_tdata  (a_tdata),
    .s_tlast  (1'b0),
    .s_tvalid (a_tvalid),
    .s_tready (a_tready),

    .m_clk    (rd_clk),
    .m_rst    (rd_rst),
    .m_tdata  (f_tdata),
    .m_tlast  (),
    .m_tvalid (f_tvalid),
    .m_tready (f_tready)
  );

  skid_buffer #(.WIDTH(8)) skid_out (
    .clk      (rd_clk),
    .rst      (rd_rst),
    .s_tdata  (f_tdata),
    .s_tvalid (f_tvalid),
    .s_tready (f_tready),
    .m_tdata  (b_tdata),
    .m_tvalid (b_tvalid),
    .m_tready (b_tready)
  );

  lfsr_checker chk (
    .clk        (rd_clk),
    .rst        (rd_rst),
    .clear      (chk_clear),
    .enable     (chk_enable),
    .seed       (chk_seed),
    .throttle   (chk_throttle),
    .s_tdata    (b_tdata),
    .s_tvalid   (b_tvalid),
    .s_tready   (b_tready),
    .word_count (word_count),
    .err_count  (err_count),
    .error_seen (error_seen)
  );

endmodule
