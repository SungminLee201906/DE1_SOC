`timescale 1ns/1ps

module axis_cdc_top_tb;

  // ---- clocks and hard resets ----
  logic csi_wr_clk = 0, csi_rd_clk = 0;
  logic rsi_wr_reset = 1, rsi_rd_reset = 1;
  always #5   csi_wr_clk = ~csi_wr_clk;   // 100 MHz
  always #8.5 csi_rd_clk = ~csi_rd_clk;   // ~59 MHz, unrelated

  // ---- Avalon-MM signals ----
  logic [1:0]  avs_wr_address = 0;
  logic        avs_wr_write = 0, avs_wr_read = 0;
  logic [31:0] avs_wr_writedata = 0, avs_wr_readdata;
  logic [2:0]  avs_rd_address = 0;
  logic        avs_rd_write = 0, avs_rd_read = 0;
  logic [31:0] avs_rd_writedata = 0, avs_rd_readdata;

  axis_cdc_top #(.ADDR_WIDTH(4)) dut (.*);

  // ---- register byte offsets (same as the README) ----
  localparam logic [7:0] CTRL = 8'h00, SEED = 8'h04, THROTTLE = 8'h08;
  localparam logic [7:0] SENT = 8'h0C;                               // WR only
  localparam logic [7:0] STATUS = 8'h0C, WORDS = 8'h10, ERRS = 8'h14; // RD only

  // CTRL bits
  localparam logic [31:0] EN = 32'h1, SOFT = 32'h2, INJ = 32'h4, CCLR = 32'h8;

  // ---- Avalon tasks: behave like the ARM ----
  task automatic wr_write(input logic [7:0] off, input logic [31:0] d);
    @(posedge csi_wr_clk);
    avs_wr_address <= off[3:2]; avs_wr_writedata <= d; avs_wr_write <= 1;
    @(posedge csi_wr_clk);
    avs_wr_write <= 0;
  endtask

  task automatic wr_read(input logic [7:0] off, output logic [31:0] d);
    @(posedge csi_wr_clk);
    avs_wr_address <= off[3:2]; avs_wr_read <= 1;
    @(posedge csi_wr_clk);              // readdata is captured on this edge (latency 1)
    avs_wr_read <= 0;
    @(posedge csi_wr_clk);
    d = avs_wr_readdata;
  endtask

  task automatic rd_write(input logic [7:0] off, input logic [31:0] d);
    @(posedge csi_rd_clk);
    avs_rd_address <= off[4:2]; avs_rd_writedata <= d; avs_rd_write <= 1;
    @(posedge csi_rd_clk);
    avs_rd_write <= 0;
  endtask

  task automatic rd_read(input logic [7:0] off, output logic [31:0] d);
    @(posedge csi_rd_clk);
    avs_rd_address <= off[4:2]; avs_rd_read <= 1;
    @(posedge csi_rd_clk);
    avs_rd_read <= 0;
    @(posedge csi_rd_clk);
    d = avs_rd_readdata;
  endtask

  // ---- checking ----
  int errors = 0;
  task automatic check(input bit ok, input string msg);
    if (!ok) begin errors++; $display("FAIL: %s", msg); end
  endtask

  // ---- software sequences (same rules as the README) ----
  task automatic soft_reset_both();
    wr_write(CTRL, 0); rd_write(CTRL, 0);          // both enables off first
    rd_write(CTRL, SOFT); wr_write(CTRL, SOFT);    // set RD, then WR
    repeat (4) @(posedge csi_rd_clk);
    wr_write(CTRL, 0); rd_write(CTRL, 0);          // clear WR, then RD
    repeat (4) @(posedge csi_rd_clk);
  endtask

  task automatic start();
    rd_write(CTRL, EN);                            // checker first
    wr_write(CTRL, EN);                            // then generator
  endtask

  task automatic stop_and_drain();
    wr_write(CTRL, 0);                             // stop the generator
    repeat (2000) @(posedge csi_rd_clk);           // let the pipe empty
  endtask

  task automatic read_counts(output logic [31:0] sent, words, errs, status);
    wr_read(SENT,   sent);
    rd_read(WORDS,  words);
    rd_read(ERRS,   errs);
    rd_read(STATUS, status);
  endtask

  logic [31:0] v, sent, words, errs, status;

  initial begin
    // 1. Hard reset (released on each domain's own clock, like the reset controller)
    repeat (4) @(posedge csi_wr_clk);
    @(posedge csi_wr_clk); rsi_wr_reset <= 0;
    @(posedge csi_rd_clk); rsi_rd_reset <= 0;
    repeat (4) @(posedge csi_rd_clk);

    // 2. Reset values
    wr_read(SEED, v);  check(v == 32'h01, "WR SEED reset value");
    rd_read(SEED, v);  check(v == 32'h01, "RD SEED reset value");
    wr_read(CTRL, v);  check(v == 0,      "WR CTRL reset value");

    // 3. Configure: same seed in both blocks, throttles, then soft reset to load the seed
    wr_write(SEED, 32'hA5);       rd_write(SEED, 32'hA5);
    wr_write(THROTTLE, 32'd64);   rd_write(THROTTLE, 32'd128);
    wr_read(SEED, v);  check(v == 32'hA5, "WR SEED readback");
    soft_reset_both();

    // 4. Run with 3 injected errors
    start();
    repeat (3) begin
      repeat (300) @(posedge csi_wr_clk);
      wr_write(CTRL, EN | INJ);                    // read-modify-write: keep enable, add inject
    end
    repeat (300) @(posedge csi_wr_clk);
    stop_and_drain();
    read_counts(sent, words, errs, status);
    $display("run 1: sent %0d, received %0d, errors %0d, status %0d", sent, words, errs, status);
    check(sent > 0,        "run 1: nothing was sent");
    check(words == sent,   "run 1: received != sent");
    check(errs == 3,       "run 1: expected exactly 3 errors");
    check(status[0] == 1,  "run 1: error_seen not set");

    // 5. Counter clear (stopped and drained), checker stays enabled
    wr_write(CTRL, CCLR);
    rd_write(CTRL, EN | CCLR);
    read_counts(sent, words, errs, status);
    check(sent == 0 && words == 0 && errs == 0 && status == 0, "counter clear: counts not zero");

    // 6. Clean run after counter clear (LFSRs kept running, must still match)
    wr_write(CTRL, EN);
    repeat (3000) @(posedge csi_wr_clk);
    stop_and_drain();
    read_counts(sent, words, errs, status);
    $display("run 2: sent %0d, received %0d, errors %0d", sent, words, errs);
    check(words == sent && errs == 0, "run 2: errors after counter clear");

    // 7. Soft reset, new seed, clean run (soft reset must reload the seed in both blocks)
    wr_write(SEED, 32'h3C);       rd_write(SEED, 32'h3C);
    soft_reset_both();
    read_counts(sent, words, errs, status);
    check(sent == 0 && words == 0 && errs == 0, "soft reset: counts not zero");
    wr_read(THROTTLE, v);  check(v == 32'd64, "soft reset: WR THROTTLE was lost");
    start();
    repeat (3000) @(posedge csi_wr_clk);
    stop_and_drain();
    read_counts(sent, words, errs, status);
    $display("run 3: sent %0d, received %0d, errors %0d", sent, words, errs);
    check(sent > 0 && words == sent && errs == 0, "run 3: errors after soft reset");

    if (errors == 0) $display("PASS: top level works through the registers");
    else             $display("FAIL: %0d check(s) failed", errors);
    $finish;
  end

  initial begin
    #5_000_000;
    $display("TIMEOUT");
    $finish;
  end

endmodule
