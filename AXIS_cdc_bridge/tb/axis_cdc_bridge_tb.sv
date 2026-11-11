`timescale 1ns/1ps

module axis_cdc_bridge_tb;

  logic        wr_clk = 0, rd_clk = 0;
  logic        wr_rst = 1, rd_rst = 1;
  logic        gen_clear = 0, gen_enable = 0;
  logic        chk_clear = 0, chk_enable = 0;
  logic [7:0]  gen_seed = 8'hA5, chk_seed = 8'hA5;
  logic [7:0]  gen_throttle = 0, chk_throttle = 0;
  logic [31:0] sent_count, word_count, err_count;
  logic        error_seen;

  always #5   wr_clk = ~wr_clk;   // 100 MHz
  always #8.5 rd_clk = ~rd_clk;   // ~59 MHz, unrelated

  axis_cdc_bridge #(.ADDR_WIDTH(4)) dut (.*);

  int errors = 0;
  task automatic check(input bit ok, input string msg);
    if (!ok) begin errors++; $display("FAIL: %s", msg); end
  endtask

  // Reset everything; release the checker side first so both LFSRs start aligned
  task automatic reset_all();
    gen_enable <= 0; chk_enable <= 0;
    @(posedge wr_clk); wr_rst <= 1;
    @(posedge rd_clk); rd_rst <= 1;
    repeat (4) @(posedge wr_clk);
    repeat (4) @(posedge rd_clk);
    rd_rst <= 0;
    repeat (4) @(posedge rd_clk);
    @(posedge wr_clk); wr_rst <= 0;
    repeat (2) @(posedge wr_clk);
  endtask

  task automatic run_phase(input string name, input logic [7:0] gt, ct, input int n);
    reset_all();
    gen_throttle <= gt;
    chk_throttle <= ct;
    @(posedge rd_clk); chk_enable <= 1;
    repeat (3) @(posedge wr_clk);
    gen_enable <= 1;
    wait (word_count >= n);
    @(posedge rd_clk);
    check(err_count == 0,                       {name, ": checker found errors"});
    check(sent_count >= word_count,             {name, ": received more than sent"});
    check((sent_count - word_count) <= 32,      {name, ": too many words in flight"});
    $display("%s: %0d words, %0d errors", name, word_count, err_count);
  endtask

  initial begin
    run_phase("full speed",  8'd0,   8'd0,   1000);
    run_phase("slow reader", 8'd0,   8'd200, 500);   // FIFO fills up
    run_phase("slow writer", 8'd200, 8'd0,   500);   // FIFO runs near empty
    run_phase("both random", 8'd128, 8'd128, 1000);

    if (errors == 0) $display("PASS: bridge carried every word in order");
    else             $display("FAIL: %0d check(s) failed", errors);
    $finish;
  end

  initial begin
    #5_000_000;
    $display("TIMEOUT");
    $finish;
  end

endmodule
