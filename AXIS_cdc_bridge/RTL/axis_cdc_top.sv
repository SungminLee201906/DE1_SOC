module axis_cdc_top #(
  parameter ADDR_WIDTH = 4
)(
  // ---- write clock domain ----
  input  logic        csi_wr_clk,         // wr_clk
  input  logic        rsi_wr_reset,       // hard reset, synchronized to wr_clk by Platform Designer
  input  logic [1:0]  avs_wr_address,     // WR_REGS Avalon-MM slave
  input  logic        avs_wr_write,
  input  logic [31:0] avs_wr_writedata,
  input  logic        avs_wr_read,
  output logic [31:0] avs_wr_readdata,

  // ---- read clock domain ----
  input  logic        csi_rd_clk,         // rd_clk
  input  logic        rsi_rd_reset,       // hard reset, synchronized to rd_clk by Platform Designer
  input  logic [2:0]  avs_rd_address,     // RD_REGS Avalon-MM slave
  input  logic        avs_rd_write,
  input  logic [31:0] avs_rd_writedata,
  input  logic        avs_rd_read,
  output logic [31:0] avs_rd_readdata
);

  // ---- write side signals ----
  logic        wr_rst, wr_soft_reset;
  logic        gen_enable, gen_clear, gen_inject;
  logic [7:0]  gen_seed, gen_throttle;
  logic [31:0] sent_count;

  // ---- read side signals ----
  logic        rd_rst, rd_soft_reset;
  logic        chk_enable, chk_clear;
  logic [7:0]  chk_seed, chk_throttle;
  logic [31:0] word_count, err_count;
  logic        error_seen;

  // ---- register blocks (hard reset only) ----
  wr_regs u_wr_regs (
    .clk              (csi_wr_clk),
    .rst              (rsi_wr_reset),
    .avs_s0_address   (avs_wr_address),
    .avs_s0_write     (avs_wr_write),
    .avs_s0_writedata (avs_wr_writedata),
    .avs_s0_read      (avs_wr_read),
    .avs_s0_readdata  (avs_wr_readdata),
    .enable           (gen_enable),
    .soft_reset       (wr_soft_reset),
    .inject           (gen_inject),
    .counter_clear    (gen_clear),
    .seed             (gen_seed),
    .throttle         (gen_throttle),
    .sent_count       (sent_count)
  );

  rd_regs u_rd_regs (
    .clk              (csi_rd_clk),
    .rst              (rsi_rd_reset),
    .avs_s0_address   (avs_rd_address),
    .avs_s0_write     (avs_rd_write),
    .avs_s0_writedata (avs_rd_writedata),
    .avs_s0_read      (avs_rd_read),
    .avs_s0_readdata  (avs_rd_readdata),
    .enable           (chk_enable),
    .soft_reset       (rd_soft_reset),
    .counter_clear    (chk_clear),
    .seed             (chk_seed),
    .throttle         (chk_throttle),
    .error_seen       (error_seen),
    .word_count       (word_count),
    .err_count        (err_count)
  );

  // ---- reset flops: datapath reset = hard reset | soft reset ----
  //glitch free
  //sycnhronous release
  always_ff @(posedge csi_wr_clk or posedge rsi_wr_reset) begin
    if (rsi_wr_reset) wr_rst <= 1'b1;
    else              wr_rst <= wr_soft_reset;
  end

  always_ff @(posedge csi_rd_clk or posedge rsi_rd_reset) begin
    if (rsi_rd_reset) rd_rst <= 1'b1;
    else              rd_rst <= rd_soft_reset;
  end

  // ---- datapath ----
  axis_cdc_bridge #(.ADDR_WIDTH(ADDR_WIDTH)) u_bridge (
    .wr_clk       (csi_wr_clk),
    .wr_rst       (wr_rst),
    .gen_clear    (gen_clear),
    .gen_enable   (gen_enable),
    .gen_seed     (gen_seed),
    .gen_throttle (gen_throttle),
    .gen_inject   (gen_inject),
    .sent_count   (sent_count),

    .rd_clk       (csi_rd_clk),
    .rd_rst       (rd_rst),
    .chk_clear    (chk_clear),
    .chk_enable   (chk_enable),
    .chk_seed     (chk_seed),
    .chk_throttle (chk_throttle),
    .word_count   (word_count),
    .err_count    (err_count),
    .error_seen   (error_seen)
  );

endmodule
