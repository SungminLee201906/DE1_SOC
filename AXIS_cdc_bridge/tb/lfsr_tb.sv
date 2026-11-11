`timescale 1ns/1ps

module lfsr_tb;

  logic        clk = 0, rst = 1, clear = 0, enable = 0, inject = 0;
  logic [7:0]  seed = 8'hA5;
  logic [7:0]  g_throttle = 0, c_throttle = 0;

  logic [7:0]  g_tdata, link_tdata;
  logic        g_tvalid, c_tready;
  logic [31:0] sent_count, word_count, err_count;
  logic        error_seen;

  localparam int BAD_WORD = 100;

  always #5 clk = ~clk;

  lfsr_generator gen (
    .clk, .rst, .clear, .enable, .seed,
    .throttle   (g_throttle),
    .m_tdata    (g_tdata),
    .m_tvalid   (g_tvalid),
    .m_tready   (c_tready),
    .sent_count
  );

  // The link can corrupt one word (flip bit 0) to prove the checker notices
  assign link_tdata = g_tdata ^ ((inject && sent_count == BAD_WORD) ? 8'h01 : 8'h00);

  lfsr_checker chk (
    .clk, .rst, .clear, .enable, .seed,
    .throttle   (c_throttle),
    .s_tdata    (link_tdata),
    .s_tvalid   (g_tvalid),
    .s_tready   (c_tready),
    .word_count, .err_count, .error_seen
  );

  int errors = 0;
  task automatic check(input bit ok, input string msg);
    if (!ok) begin errors++; $display("FAIL: %s", msg); end
  endtask

  task automatic do_clear();
    @(posedge clk); clear <= 1;
    @(posedge clk); clear <= 0;
  endtask

  initial begin
    repeat (4) @(posedge clk);
    rst <= 0;
    @(posedge clk);

    // Phase 1: full speed, clean link, 1000 words (past the 255-value wrap)
    enable <= 1;
    wait (word_count >= 1000);
    @(posedge clk);
    check(err_count == 0, "phase 1: errors on a clean link");

    // Phase 2: random pauses on both sides, clean link
    enable <= 0; do_clear();
    g_throttle <= 128; c_throttle <= 128;
    enable <= 1;
    wait (word_count >= 1000);
    @(posedge clk);
    check(err_count == 0, "phase 2: errors with backpressure");

    // Phase 3: corrupt one word, expect exactly one error
    enable <= 0; do_clear();
    g_throttle <= 0; c_throttle <= 0;
    inject <= 1;
    enable <= 1;
    wait (word_count >= 500);
    @(posedge clk);
    check(err_count == 1,  "phase 3: expected exactly 1 error");
    check(error_seen == 1, "phase 3: error_seen should be set");

    if (errors == 0) $display("PASS: generator and checker agree");
    else             $display("FAIL: %0d check(s) failed", errors);
    $finish;
  end

  initial begin
    #2_000_000;
    $display("TIMEOUT");
    $finish;
  end

endmodule
